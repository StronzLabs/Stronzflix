import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';

class SerialMetadata {
    final TitleMetadata metadata;
    final String info;
    final int timestamp;
    final int duration;

    const SerialMetadata({
        required this.metadata,
        required this.info,
        required this.timestamp,
        required this.duration
    });

    static SerialMetadata unserialize(Map<String, dynamic> data) {
        return SerialMetadata(
            metadata: TitleMetadata(
                name: data["metadata"]["name"],
                url: data["metadata"]["url"],
                site: Site.get(data["metadata"]["site"])!,
                poster: data["metadata"]["poster"]
            ),
            info: data["info"],
            timestamp: data["timestamp"],
            duration: data["duration"]
        );
    }

    static SerialMetadata fromWatchable(Watchable watchable, int timestamp, int duration) {
        TitleMetadata data = watchable.metadata;
        String info = Watchable.genInfo(watchable);
        return SerialMetadata(
            metadata: data,
            info: info,
            timestamp: timestamp,
            duration: duration
        );
    }

    Map<String, dynamic> serialize() => {
        "metadata":  {
            "name": this.metadata.name,
            "url": this.metadata.url,
            "site": this.metadata.site.name,
            "poster": this.metadata.poster
        },
        "info": this.info,
        "timestamp": this.timestamp,
        "duration": this.duration
    };
}

sealed class KeepWatching {
    KeepWatching._();

    static late SharedPreferences _prefs;

    static final Map<String, SerialMetadata> _keepWatching = {};
    static List<TitleMetadata> get metadata => KeepWatching._keepWatching.values.map((data) => data.metadata).toList();
    
    static Future<Watchable?> getWatchable(TitleMetadata metadata) async{
        String id = metadata.site.name + metadata.url;
        if(KeepWatching._keepWatching.containsKey(id))
            return Watchable.unserialize(
                KeepWatching._keepWatching[id]!.metadata,
                KeepWatching._keepWatching[id]!.info
            );
        
        return null;
    }

    static int? getTimestamp(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        String info = Watchable.genInfo(watchable);
        String id = data.site.name + data.url;
        if (KeepWatching._keepWatching.containsKey(id) && KeepWatching._keepWatching[id]?.info == info)
            return KeepWatching._keepWatching[id]?.timestamp;
        return null;
    }

    static int? getDuration(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        String info = Watchable.genInfo(watchable);
        String id = data.site.name + data.url;
        if (KeepWatching._keepWatching.containsKey(id) && KeepWatching._keepWatching[id]?.info == info)
            return KeepWatching._keepWatching[id]?.duration;
        return null;
    }

    static Future<void> init() async {
        KeepWatching._prefs = await SharedPreferences.getInstance();

        if (!KeepWatching._prefs.containsKey("KeepWatching"))
            KeepWatching._prefs.setStringList("KeepWatching", []);

        KeepWatching.unserialize();
    }

    static void add(Watchable watchable, int timestamp, int duration) {
        SerialMetadata data = SerialMetadata.fromWatchable(watchable, timestamp, duration);
        String id = data.metadata.site.name + data.metadata.url;
        KeepWatching._keepWatching[id] = data;

        KeepWatching.serialize();
    }

    static void remove(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        KeepWatching._keepWatching.remove(id);

        KeepWatching.serialize();
    }

    static Future<void> serialize() async {
        List<String> list = [];
        for (SerialMetadata data in KeepWatching._keepWatching.values) {
            list.add(jsonEncode(data.serialize()));
        }
        await KeepWatching._prefs.setStringList("KeepWatching", list);
    }

    static void unserialize() {
        List<String> list = KeepWatching._prefs.getStringList("KeepWatching")!;
        for (String json in list) {
            Map<String, dynamic> data = jsonDecode(json);
            TitleMetadata metadata = TitleMetadata(
                name: data["metadata"]["name"],
                url: data["metadata"]["url"],
                site: Site.get(data["metadata"]["site"])!,
                poster: data["metadata"]["poster"]
            );
            String info = data["info"];
            int timestamp = data["timestamp"];
            int duration = data["duration"];

            String id = metadata.site.name + metadata.url;
            KeepWatching._keepWatching[id] = SerialMetadata(metadata: metadata, info: info, timestamp: timestamp, duration: duration);
        }
    }
}