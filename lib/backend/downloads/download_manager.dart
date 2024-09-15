import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' show ValueNotifier;
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/downloader.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:sutils/sutils.dart';

import 'download_state.dart';

class DownloadOptions {
    final Variant? variant;
    final Rendition? audio;
    final Uri? url;
    final Watchable watchable;

    const DownloadOptions(this.watchable, {this.variant, this.audio, this.url});
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

    static Future<File> _downloadTitleMetadata(Directory outputDirectory, Title title) async{
        File metadataFile = File('${outputDirectory.path}/metadata.json');
        if(metadataFile.existsSync())
            return metadataFile;

        File bannerFile = File('${outputDirectory.path}/banner.jpg');
        await bannerFile.writeAsBytes(await HTTP.getRaw(title.banner));

        File posterFile = File('${outputDirectory.path}/poster.jpg');
        await posterFile.writeAsBytes(await HTTP.getRaw(title.metadata.poster));

        Map<String, dynamic> metadata = {
            "description": title.description,
            "name": title.name,
        };

        metadataFile.writeAsStringSync(jsonEncode(metadata));
        return metadataFile;
    }

    static Future<bool> _downloadEpisodeMetadata(Directory outputDirectory, Episode episode) async {
        String coverID = DownloadManager._calcId("${episode.title}-cover");
        File coverFile = File('${outputDirectory.path}/${coverID}.jpg');
        await coverFile.writeAsBytes(await HTTP.getRaw(episode.cover));
        
        File metadataFile = await DownloadManager._downloadTitleMetadata(outputDirectory, episode.season.series);
        Map<String, dynamic> metadata = jsonDecode(metadataFile.readAsStringSync());
        metadata["seasons"] ??= [];
        
        Map<String, dynamic>? seasonData = metadata["seasons"]
            .firstWhere((e) => e["seasonNo"] == episode.season.seasonNo, orElse: () => null);
        if(seasonData == null) {
            seasonData = {
                "name": episode.season.name,
                "seasonNo": episode.season.seasonNo,
                "episodes": []
            };
            metadata["seasons"].add(seasonData);
        }

        Map<String, dynamic>? episodeData = seasonData["episodes"]
            .firstWhere((e) => e["episodeNo"] == episode.episodeNo, orElse: () => null);
        if(episodeData == null) {
            episodeData = {
                "name": episode.name,
                "episodeNo": episode.episodeNo,
                "cover": coverID,
                "url": DownloadManager.calcWatchableId(episode)
            };
            seasonData["episodes"].add(episodeData);
        }

        metadataFile.writeAsStringSync(jsonEncode(metadata));
        return true;        
    }

    static Future<void> _downloadFilmMetadata(Directory outputDirectory, Film film) async {
        File metadataFile = await _downloadTitleMetadata(outputDirectory, film);

        Map<String, dynamic> metadata = jsonDecode(metadataFile.readAsStringSync());
        metadata["url"] = DownloadManager.calcWatchableId(film);
        metadataFile.writeAsStringSync(jsonEncode(metadata));
    }

    static Future<void> _downloadMetadata(Directory outputDirectory, Watchable watchable) async {
        if(watchable is Episode)
            await DownloadManager._downloadEpisodeMetadata(outputDirectory, watchable);
        else if(watchable is Film)
            await DownloadManager._downloadFilmMetadata(outputDirectory, watchable);
        else
            throw Exception("Unknown watchable type");
    }

    static String _calcId(String str) => md5.convert(utf8.encode(str)).toString();
    static String calcTitleId(TitleMetadata metadata) => DownloadManager._calcId(metadata.name);
    static String calcWatchableId(Watchable watchable) => DownloadManager._calcId(watchable.title);

    static Future<void> download(DownloadOptions options) async {
        String titleID = DownloadManager.calcTitleId(options.watchable.metadata);
        String watchableID = DownloadManager.calcWatchableId(options.watchable);
        Directory outputDir = Directory('${(await downloadDirectory).path}${titleID}');
        outputDir.createSync(recursive: true);

        if(Directory(outputDir.path).listSync().any((e) => e.path.contains(watchableID)))
            return;

        DownloadState downloadState = DownloadState(options.watchable.title, options);
        downloads.value.add(downloadState);

        Downloader downloader = options.url == null ? Downloader.hls : Downloader.direct;
        await downloader.download(options, downloadState, outputDir, watchableID);

        if(!downloadState.hasError && !downloadState.isCanceled) {
            await DownloadManager._downloadMetadata(outputDir, options.watchable);
            LocalSite.notify();
        }
        
        await downloader.cleanTmpDownload(downloadState);
        if(!downloadState.hasError || downloadState.isCanceled)
            DownloadManager.removeDownload(downloadState);
    }

    static Future<void> _deleteEpisode(Episode episode) async {
        String titleID = DownloadManager.calcTitleId(episode.metadata);

        Directory directory = Directory('${(await downloadDirectory).path}${titleID}');
        Map<String, dynamic> metadata = jsonDecode(File('${directory.path}/metadata.json').readAsStringSync());

        Map<String, dynamic> seasonData = metadata["seasons"]
            .firstWhere((e) => e["seasonNo"] == episode.season.seasonNo);

        seasonData["episodes"].removeWhere((e) => e["episodeNo"] == episode.episodeNo);
        
        if(seasonData["episodes"].isEmpty)
            metadata["seasons"].removeWhere((e) => e["seasonNo"] == episode.season.seasonNo);

        File metadataFile = File('${directory.path}/metadata.json');
        metadataFile.writeAsStringSync(jsonEncode(metadata));
        File coverFile = File.fromUri(episode.cover);
        coverFile.deleteSync();
        File episodeFile = File.fromUri(episode.uri);
        episodeFile.deleteSync();

        KeepWatching.remove(episode.metadata, info: Watchable.genInfo(episode));

        if(metadata["seasons"].isEmpty)
            await DownloadManager.deleteTitle(episode.metadata);
    }

    static Future<void> deleteSingle(Watchable watchable) async {
        if(watchable is Film)
            await DownloadManager.deleteTitle(watchable.metadata);
        if(watchable is Episode)
            await DownloadManager._deleteEpisode(watchable);
        else
            throw Exception("Unknown watchable type");
        LocalSite.notify();
    }

    static Future<void> deleteTitle(TitleMetadata metadata) async {
        String titleID = DownloadManager.calcTitleId(metadata);
        Directory directory = Directory('${(await downloadDirectory).path}${titleID}');
        try {
            directory.deleteSync(recursive: true);
        } catch (_) {
            for(FileSystemEntity entity in directory.listSync())
                try {
                    entity.deleteSync();
                } catch (_) {}
        }
        
        KeepWatching.remove(metadata);
        LocalSite.notify();
    }
}
