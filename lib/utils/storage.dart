import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    String toString() => json.encode(this.toJson());
}

final class Storage {
    static late SharedPreferences _prefs;

    static late Map<String, TimeStamp> _keepWatchingList;
    static Map<String, TimeStamp> get keepWatching => Storage._keepWatchingList;

    static Future<void> init() async {
        Storage._prefs = await SharedPreferences.getInstance();

        if (!Storage._prefs.containsKey("TimeStamps"))
            Storage._prefs.setStringList("TimeStamps", []);

        Iterable<dynamic> timeStamps = Storage._prefs.getStringList("TimeStamps")!.map((e) => jsonDecode(e));

        Storage._keepWatchingList = {
            for (dynamic timeStamp in timeStamps)
                "${timeStamp["player"]}_${timeStamp["url"]}" : TimeStamp.fromJson(timeStamp)
        };
    }

    static void serialize() {
        List<String> timestamps = Storage._keepWatchingList.values.map<String>((element) => element.toString()).toList();
        Storage._prefs.setStringList("TimeStamps", timestamps);
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
