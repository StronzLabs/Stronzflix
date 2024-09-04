import 'dart:convert';
import 'dart:io';

import 'package:stronzflix/backend/api/player.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';

class LocalSite extends Site {
    static Site instance = LocalSite._();
    LocalSite._() : super("Scaricati", "");

    @override
    bool tunerValidator(String homePage) => true;

    TitleMetadata _extractMetadata(Directory directory, [Map<String, dynamic>? metadata]) {
        metadata ??= jsonDecode(
            File("${directory.path}/metadata.json").readAsStringSync()
        );
        return TitleMetadata(
            name: metadata!["name"],
            uri: directory.uri,
            site: this,
            poster: Uri.parse("${directory.path}/poster.jpg")
        );
    }

    @override
    Future<List<TitleMetadata>> search(String query) async {
        Directory downloadDir = await DownloadManager.downloadDirectory;
        List<TitleMetadata> results = [];

        for(FileSystemEntity entity in downloadDir.listSync()) {
            if(entity is Directory) {
                File metadataFile = File("${entity.path}/metadata.json");
                if(!metadataFile.existsSync())
                    continue;
                Map<String, dynamic> metadata = jsonDecode(
                    metadataFile.readAsStringSync()
                );
                if(metadata["name"].toLowerCase().contains(query.toLowerCase())) {
                    results.add(_extractMetadata(entity, metadata));
                }
            }
        }

        return results;
    }

    @override
    Future<List<TitleMetadata>> latests() async {
        Directory downloadDir = await DownloadManager.downloadDirectory;

        List<TitleMetadata> results = [];
        List<FileSystemEntity> entities = downloadDir.listSync().toList();

        entities.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        for(FileSystemEntity entity in entities.take(50)) {
            if(entity is Directory) {
                File metadataFile = File("${entity.path}/metadata.json");
                if(!metadataFile.existsSync())
                    continue;
                results.add(_extractMetadata(entity));
            }
        }

        return results;
    }

    Future<Film> getFilm(TitleMetadata metadata, Map<String, dynamic> jsonMetadata) async {
        return Film(
            metadata: metadata,
            uri: Uri.parse("${metadata.uri}/${jsonMetadata["url"]}.mp4"),
            banner: Uri.parse("${metadata.uri}/banner.jpg"),
            description: jsonMetadata["description"]
        );
    }

    Future<Series> getSeries(TitleMetadata metadata, Map<String, dynamic> jsonMetadata) async {
        Series series = Series(
            banner: Uri.parse("${metadata.uri}/banner.jpg"),
            description: jsonMetadata["description"],
            seasons: [],
            metadata: metadata
        );

        for(Map<String, dynamic> seasonMetadata in jsonMetadata["seasons"]) {
            Season season = Season(
                series: series,
                name: seasonMetadata["name"],
                episodes: []
            );

            for(Map<String, dynamic> episodeMetadata in seasonMetadata["episodes"]) {
                season.episodes.add(Episode(
                    name: episodeMetadata["name"],
                    cover: Uri.parse("${metadata.uri}/${episodeMetadata["cover"]}.jpg"),
                    uri: Uri.parse("${metadata.uri}/${episodeMetadata["url"]}.mp4"),
                    episodeNo: episodeMetadata["episodeNo"],
                    season: season
                ));
            }

            series.seasons.add(season);
        }

        return series;
    }

    @override
    Future<Title> getTitle(TitleMetadata metadata) async {
        Map<String, dynamic> jsonMetadata = jsonDecode(
            File("${metadata.uri}/metadata.json").readAsStringSync()
        );
        return jsonMetadata.containsKey("url")
            ? getFilm(metadata, jsonMetadata)
            : getSeries(metadata, jsonMetadata);
    }

    @override
    Future<List<WatchOption>> getOptions(Watchable watchable) async {
        return [
            WatchOption(
                player: LocalPlayer.instance,
                uri: watchable.uri
            )
        ];
    }
}

class LocalPlayer extends Player {
    static Player instance = LocalPlayer._();
    LocalPlayer._() : super("Local");
    
    @override
    Future<Uri> getSource(Uri uri) => Future.value(uri);    
}
