import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' show ValueNotifier;
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stronzflix/backend/ffmpeg_wrapper.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;
import 'package:stronzflix/utils/utils.dart';

import 'download_state.dart';

class DownloadOptions {
    final Variant variant;
    final Rendition? audio;
    final Watchable watchable;

    const DownloadOptions(this.variant, this.audio, this.watchable);
}

class DownloadManager {
    const DownloadManager._();

    static Future<Directory> get downloadDirectory async {
        Directory outputDir = await getApplicationDocumentsDirectory();
        return Directory('${outputDir.path}/Stronzflix/downloads/');
    }

    static ValueNotifier<List<DownloadState>> downloads = ValueNotifier([]);

    static void removeDownload(DownloadState download) async {
        downloads.value = downloads.value.where((e) => e != download).toList();
    }

    static void _cleanTmpDownload(DownloadState download) async {
        String titleID = _calcTitleId(download.options.watchable);
        String watchableID = _calcWatchableId(download.options.watchable);
        Directory directory = Directory('${(await downloadDirectory).path}${titleID}');
        File videoTs = File('${directory.path}/${watchableID}-video.ts');
        File audioTs = File('${directory.path}/${watchableID}-audio.ts');
        if(videoTs.existsSync())
           videoTs.deleteSync();
        if(audioTs.existsSync())
            audioTs.deleteSync();

        if(directory.listSync().where((e) => e.path.endsWith(".ts") || e.path.endsWith(".mp4")).isEmpty)
            directory.deleteSync(recursive: true);
    }

    static Stream<Uint8List> _downloadSegmnets(List<Segment> segments, String baseUri) async * {
        Uint8List? key;
        Uint8List? iv;
        for (Segment segment in segments) {
            Uri url = Uri.parse(segment.url!);
            Uint8List bytes = await http.getRaw(url);

            if(segment.encryptionIV != null) {
                key ??= await http.getRaw(Uri.parse("$baseUri/..${segment.fullSegmentEncryptionKeyUri}"));
                iv ??= hexToUint8List(segment.encryptionIV!.substring(2));
                bytes = decryptAES128(bytes, key, iv);
            }

            yield bytes;
        }
    }

    static Future<bool> _downloadPlaylist(DownloadState state, void Function(double) progressCallback, Uri url, File outputFile) async {
        HlsPlaylist playlist = await HlsPlaylistParser.create().parseString(url, await http.get(url));
        if(playlist is! HlsMediaPlaylist)
            throw Exception("Not a master playlist");

        double advance = 0;
        double delta = 1 / (playlist.segments.length + 2);
        progressCallback(advance);

        String baseUri = playlist.baseUri!.substring(0, playlist.baseUri!.lastIndexOf("/"));

        IOSink outputSink = outputFile.openWrite(mode: FileMode.writeOnly);
        advance += delta;
        progressCallback(advance);

        await for (Uint8List segment in DownloadManager._downloadSegmnets(playlist.segments, baseUri)) {
            outputSink.add(segment);
            advance += delta;
            progressCallback(advance);

            if (state.isPaused)
                await state.resumeFuture;
            if (state.isCanceled) {
                await outputSink.close();
                return false;
            }
        }

        await outputSink.close();
        advance += delta;
        progressCallback(advance);
        return true;
    }

    static Future<bool> _downloadVariant(DownloadState state,  File outputFile, Variant variant, void Function(double) progressCallback) async {
        return _downloadPlaylist(state, progressCallback, variant.url, outputFile);
    }

    static Future<bool> _downloadRendition(DownloadState state, File outputFile, Rendition rendition, void Function(double) progressCallback) async {
        return _downloadPlaylist(state, progressCallback, rendition.url!, outputFile);
    }

    static Future<bool> _downloadTitleMetadata(Directory outputDirectory, Title title) async{
        File metadataFile = File('${outputDirectory.path}/metadata.json');
        if(metadataFile.existsSync())
            return true;

        File bannerFile = File('${outputDirectory.path}/banner.jpg');
        await bannerFile.writeAsBytes(await http.getRaw(Uri.parse(title.banner)));

        File posterFile = File('${outputDirectory.path}/poster.jpg');
        await posterFile.writeAsBytes(await http.getRaw(Uri.parse(title.metadata.poster)));

        Map<String, dynamic> metadata = {
            "description": title.description,
            "name": title.name,
        };

        metadataFile.writeAsStringSync(jsonEncode(metadata));
        return true;
    }

    static Future<bool> _downloadEpisodeMetadata(Directory outputDirectory, Episode episode) async {
        Series series = episode.season.series;
        if(!await _downloadTitleMetadata(outputDirectory, series))
            return false;

        String coverID = _calcId("${episode.name}-cover");
        File coverFile = File('${outputDirectory.path}/${coverID}.jpg');
        await coverFile.writeAsBytes(await http.getRaw(Uri.parse(episode.cover)));

        File metadataFile = File('${outputDirectory.path}/metadata.json');
        Map<String, dynamic> metadata = jsonDecode(metadataFile.readAsStringSync());
        metadata["seasons"] ??= [];
        if(metadata["seasons"].where((e) => e["name"] == episode.season.name).isEmpty) {
            metadata["seasons"].add({
                "name": episode.season.name,
                "episodes": []
            });
        }
        if(metadata["seasons"].firstWhere((e) => e["name"] == episode.season.name)["episodes"].where((e) => e["name"] == episode.name).isEmpty)
            metadata["seasons"].firstWhere((e) => e["name"] == episode.season.name)["episodes"].add({
                "name": episode.name
            });
    
        Map<String, dynamic> episodeObject = metadata["seasons"].firstWhere((e) => e["name"] == episode.season.name)["episodes"].firstWhere((e) => e["name"] == episode.name);
        episodeObject["cover"] = coverID;
        episodeObject["url"] = _calcWatchableId(episode);

        metadataFile.writeAsStringSync(jsonEncode(metadata));
        return true;        
    }

    static Future<bool> _downloadFilmMetadata(Directory outputDirectory, Film film) async {
        if(!await _downloadTitleMetadata(outputDirectory, film))
            return false;

        File metadataFile = File('${outputDirectory.path}/metadata.json');
        Map<String, dynamic> metadata = jsonDecode(metadataFile.readAsStringSync());

        metadata["url"] = _calcWatchableId(film);

        metadataFile.writeAsStringSync(jsonEncode(metadata));
        return true;
    }

    static Future<bool> _downloadMetadata(Directory outputDirectory, Watchable watchable) async {
        if(watchable is Episode)
            return _downloadEpisodeMetadata(outputDirectory, watchable);
        if(watchable is Film)
            return _downloadFilmMetadata(outputDirectory, watchable);
        return false;
    }

    static String _calcId(String str) => md5.convert(utf8.encode(str)).toString();
    static String _calcTitleId(Watchable watchable) =>
        watchable is Film ? _calcId(watchable.name) :
        watchable is Episode ? _calcId(watchable.season.series.name) :
        throw Exception("Unknown watchable type");
    static String _calcWatchableId(Watchable watchable) => _calcId(watchable.name);

    static String _downloadName(Watchable watchable) =>
        watchable is Film ? watchable.name :
        watchable is Episode ? "${watchable.season.series.name} - ${watchable.name}" :
        throw Exception("Unknown watchable type");

    static Future<void> download(DownloadOptions options) async {
        String titleID = _calcTitleId(options.watchable);
        String watchableID = _calcWatchableId(options.watchable);
        Directory outputDir = Directory('${(await downloadDirectory).path}${titleID}');
        outputDir.createSync(recursive: true);

        if(Directory(outputDir.path).listSync().any((e) => e.path.contains(watchableID)))
            return;

        DownloadState downloadState = DownloadState(_downloadName(options.watchable), options);
        downloads.value.add(downloadState);

        File videoTs = File('${outputDir.path}/${watchableID}-video.ts');
        File audioTs = File('${outputDir.path}/${watchableID}-audio.ts');

        double videoAdvance = 0;
        double audioAdvance = 0;
        double ntasks = options.audio == null ? 1 : 2;

        void updateProgress() {
            double totalAdvance = (videoAdvance + audioAdvance) / ntasks;
            downloadState.value = totalAdvance;
        }

        List<bool> results = await Future.wait([
            DownloadManager._downloadVariant(downloadState, videoTs, options.variant, (progress) {
                videoAdvance = progress;
                updateProgress();
            }),
            if (options.audio != null)
                DownloadManager._downloadRendition(downloadState, audioTs, options.audio!, (progress) {
                    audioAdvance = progress;
                    updateProgress();
                }),
        ]).onError((error, stackTrace) => [false]);

        if (results.any((e) => !e)) {
            downloadState.setError();
            DownloadManager._cleanTmpDownload(downloadState);
            return;
        }

        await DownloadManager._downloadMetadata(outputDir, options.watchable);

        await FFmpegWrapper.run('-i "${audioTs.path}" -i "${videoTs.path}" -c copy "${outputDir.path}/${watchableID}.mp4"');
        DownloadManager._cleanTmpDownload(downloadState);
        DownloadManager.removeDownload(downloadState);
    }

    static Future<void> _deleteFilm(Film film) async {
        String titleID = _calcTitleId(film);
        Directory directory = Directory('${(await downloadDirectory).path}${titleID}');
        directory.deleteSync(recursive: true);
    }

    static Future<void> _deleteEpisode(Episode episode) async {
        String titleID = _calcTitleId(episode);
        String watchableID = _calcWatchableId(episode);
        Directory directory = Directory('${(await downloadDirectory).path}${titleID}');
        Map<String, dynamic> metadata = jsonDecode(File('${directory.path}/metadata.json').readAsStringSync());
    
        metadata["seasons"].firstWhere((e) => e["name"] == episode.season.name)["episodes"].removeWhere((e) => e["name"] == episode.name);
        if(metadata["seasons"].firstWhere((e) => e["name"] == episode.season.name)["episodes"].isEmpty)
            metadata["seasons"].removeWhere((e) => e["name"] == episode.season.name);
        if(metadata["seasons"].isEmpty)
            directory.deleteSync(recursive: true);
        else {
            File metadataFile = File('${directory.path}/metadata.json');
            metadataFile.writeAsStringSync(jsonEncode(metadata));
            File coverFile = File('${directory.path}/${_calcId("${episode.name}-cover")}.jpg');
            coverFile.deleteSync();
            File episodeFile = File('${directory.path}/${watchableID}.mp4');
            episodeFile.deleteSync();
        }
    }

    static Future<void> deleteSingle(Watchable watchable) async {
        if(watchable is Film)
            return _deleteFilm(watchable);
        if(watchable is Episode)
            return _deleteEpisode(watchable);
        throw Exception("Unknown watchable type");
    }

    static Future<void> delete(Title title) async {
        String titleID = _calcId(title.name);
        Directory directory = Directory('${(await downloadDirectory).path}${titleID}');
        try {
            directory.deleteSync(recursive: true);
        } catch (_) {
            for(FileSystemEntity entity in directory.listSync())
                try {
                    entity.deleteSync();
                } catch (_) {}
        }
    }
}
