import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:stronzflix/backend/media.dart';

class TimeStamp {
    final String name;
    final String url;
    final String player;
    int time;
    final String cover;

    TimeStamp({required this.name, required this.url, required this.player, required this.time, required this.cover});

    Map toJson() => {
        "name": this.name,
        "url": this.url,
        "player": this.player,
        "time": this.time,
        "cover": this.cover
    };

    factory TimeStamp.fromJson(Map json) => TimeStamp(
        name: json["name"],
        url: json["url"],
        player: json["player"],
        time: json["time"],
        cover: json["cover"]
    );

    @override
    String toString() => this.toJson().toString();
}

final class Storage {

    static late Directory _dir;

    static late File _keepWatchingFile;
    static late Map<String, TimeStamp> _keepWatchingList;
    static Map<String, TimeStamp> get keepWatching => Storage._keepWatchingList;

    static Future<void> init() async {
        Storage._dir = Directory("${(await getApplicationDocumentsDirectory()).path}/Stronzflix");
        await Storage._dir.create(recursive: true);
        Storage._keepWatchingFile = File("${Storage._dir.path}/keep_watching.json");

        if (!await Storage._keepWatchingFile.exists()) {
            await Storage._keepWatchingFile.create();
            await Storage._keepWatchingFile.writeAsString('{"TimeStamps":[]}');
        }

        dynamic timeStamps = jsonDecode(await Storage._keepWatchingFile.readAsString())["TimeStamps"];
        Storage._keepWatchingList = {
            for (var timeStamp in timeStamps)
                "${timeStamp["player"]}_${timeStamp["url"]}" : TimeStamp.fromJson(timeStamp)
        };
    }

    static void serialize() async {
        await Storage._keepWatchingFile.writeAsString(jsonEncode({
            "TimeStamps": [
                for (var timeStamp in Storage._keepWatchingList.values)
                    timeStamp.toJson()
            ]
        }));
    }

    static String _calcID(IWatchable watchable) => "${watchable.player.name}_${watchable.url}";

    static void startWatching(IWatchable media) {
        Storage.keepWatching[Storage._calcID(media)] = TimeStamp(
            cover: media.cover,
            name: media.name,
            player: media.player.name,
            time: 0,
            url: media.url
        );
    }

    static void updateWatching(IWatchable media, int time) {
        Storage.keepWatching[Storage._calcID(media)]!.time = time;
    }
}