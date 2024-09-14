import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/downloads/download_state.dart';
import 'package:stronzflix/backend/ffmpeg_wrapper.dart';
import 'package:stronzflix/utils/utils.dart';

import 'dart:typed_data';

import 'package:sutils/sutils.dart';

abstract class Downloader {
    static const Downloader hls = HLSDownloader();
    static const Downloader direct = DirectDownloader();

    const Downloader();
    Future<void> download(DownloadOptions options, DownloadState downloadState, Directory outputDir, String watchableID);
    Future<void> cleanTmpDownload(DownloadState download);
}

class HLSDownloader extends Downloader {
    const HLSDownloader();

    Stream<Uint8List> _downloadSegmnets(List<Segment> segments, String baseUri) async * {
        Uint8List? key;
        Uint8List? iv;
        for (Segment segment in segments) {
            Uri url = Uri.parse(segment.url!);
            Uint8List bytes = await HTTP.getRaw(url, timeout: const Duration(seconds: 30), maxRetries: 5);

            if(segment.encryptionIV != null) {
                key ??= await HTTP.getRaw(Uri.parse("$baseUri/..${segment.fullSegmentEncryptionKeyUri}"));
                iv ??= hexToUint8List(segment.encryptionIV!.substring(2));
                bytes = decryptAES128(bytes, key, iv);
            }

            yield bytes;
        }
    }

    Future<bool> _downloadPlaylist(DownloadState state, void Function(double) progressCallback, Uri url, IOSink outputSink) async {
        HlsPlaylist playlist = await HlsPlaylistParser.create().parseString(url, await HTTP.get(url));
        if(playlist is! HlsMediaPlaylist)
            throw Exception("Not a master playlist");

        double advance = 0;
        double delta = 1 / (playlist.segments.length + 2);
        progressCallback(advance);

        String baseUri = playlist.baseUri!.substring(0, playlist.baseUri!.lastIndexOf("/"));

        advance += delta;
        progressCallback(advance);

        await for (Uint8List segment in this._downloadSegmnets(playlist.segments, baseUri)) {
            outputSink.add(segment);
            advance += delta;
            progressCallback(advance);

            if (state.isPaused)
                await state.resumeFuture;
            if (state.isCanceled) {
                return false;
            }
        }

        advance += delta;
        progressCallback(advance);
        return true;
    }

    Future<bool> _downloadVariant(DownloadState state, IOSink outputSink, Variant variant, void Function(double) progressCallback) async {
        return this._downloadPlaylist(state, progressCallback, variant.url, outputSink);
    }

    Future<bool> _downloadRendition(DownloadState state, IOSink outputSink, Rendition rendition, void Function(double) progressCallback) async {
        return this._downloadPlaylist(state, progressCallback, rendition.url!, outputSink);
    }

    @override
    Future<void> download(DownloadOptions options, DownloadState downloadState, Directory outputDir, String watchableID) async {
        File videoTs = File('${outputDir.path}/${watchableID}-video.ts');
        IOSink videoSink = videoTs.openWrite(mode: FileMode.writeOnly);
        File audioTs = File('${outputDir.path}/${watchableID}-audio.ts');
        IOSink audioSink = audioTs.openWrite(mode: FileMode.writeOnly);

        double videoAdvance = 0;
        double audioAdvance = 0;
        double ntasks = options.audio == null ? 1 : 2;

        void updateProgress() {
            double totalAdvance = (videoAdvance + audioAdvance) / ntasks;
            downloadState.value = totalAdvance;
        }

        List<bool> results = await Future.wait([
            this._downloadVariant(downloadState, videoSink, options.variant!, (progress) {
                videoAdvance = progress;
                updateProgress();
            }),
            if (options.audio != null)
                this._downloadRendition(downloadState, audioSink, options.audio!, (progress) {
                    audioAdvance = progress;
                    updateProgress();
                }),
        ]).onError((error, stackTrace) => [false]);

        await videoSink.close();
        await audioSink.close();

        if (results.any((e) => !e)) {
            downloadState.setError();
            return;
        }

        try {
            await FFmpegWrapper.run('-i "${audioTs.path}" -i "${videoTs.path}" -c copy "${outputDir.path}/${watchableID}.mp4"');
        } catch(_) {
            downloadState.setError();
        }
    }

    @override
    Future<void> cleanTmpDownload(DownloadState download) async {
        String titleID = DownloadManager.calcTitleId(download.options.watchable.metadata);
        String watchableID = DownloadManager.calcWatchableId(download.options.watchable);
        Directory directory = Directory('${(await DownloadManager.downloadDirectory).path}${titleID}');
        File videoTs = File('${directory.path}/${watchableID}-video.ts');
        File audioTs = File('${directory.path}/${watchableID}-audio.ts');
        if(videoTs.existsSync())
           videoTs.deleteSync();
        if(audioTs.existsSync())
            audioTs.deleteSync();

        if(directory.listSync().where((e) => e.path.endsWith(".ts") || e.path.endsWith(".mp4")).isEmpty)
            directory.deleteSync(recursive: true);
    }
}

class DirectDownloader extends Downloader {
    const DirectDownloader();
    
    @override
    Future<void> download(DownloadOptions options, DownloadState downloadState, Directory outputDir, String watchableID) async {
        final task = DownloadTask(
            url: options.url!.toString(),
            directory: outputDir.path,
            filename: '${watchableID}.mp4',
            allowPause: true
        );

        await FileDownloader().download(task,
            onProgress: (progress) async {
                downloadState.value = progress;
                if (downloadState.isPaused) {
                    FileDownloader().pause(task);
                    await downloadState.resumeFuture;
                    FileDownloader().resume(task);
                }
                if (downloadState.isCanceled) {
                    FileDownloader().cancelTaskWithId(task.taskId);
                    return;
                }
            },
            onStatus: (status) {
                if(status == TaskStatus.failed || status == TaskStatus.canceled)
                    downloadState.setError();
            }
        );
    }

    @override
    Future<void> cleanTmpDownload(DownloadState download) async {
        if(!download.hasError && !download.isCanceled)
            return;

        String titleID = DownloadManager.calcTitleId(download.options.watchable.metadata);
        String watchableID = DownloadManager.calcWatchableId(download.options.watchable);
        Directory directory = Directory('${(await DownloadManager.downloadDirectory).path}${titleID}');
        File videoFile = File('${directory.path}/${watchableID}.mp4');
        if(videoFile.existsSync())
            videoFile.deleteSync();

        if(directory.listSync().where((e) => e.path.endsWith(".mp4")).isEmpty)
            directory.deleteSync(recursive: true);
    }
}