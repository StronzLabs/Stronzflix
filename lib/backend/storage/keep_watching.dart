import 'dart:convert';

import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/storage/local_storage.dart';

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

class KeepWatching extends LocalStorage {
    static final KeepWatching instance = KeepWatching._();
    KeepWatching._() : super({ "KeepWatching": <String>[] });

    final Map<String, SerialMetadata> _keepWatching = {};
    static List<TitleMetadata> get metadata => KeepWatching.instance._keepWatching.values.map((data) => data.metadata).toList();

    @override
    Future<void> construct() async {
        await super.construct();

        for (String json in super["KeepWatching"]) {
            Map<String, dynamic> data = jsonDecode(json);

            Site? site = Site.get(data["metadata"]["site"]);
            if(site == null)
                continue;

            TitleMetadata metadata = TitleMetadata(
                name: data["metadata"]["name"],
                url: data["metadata"]["url"],
                site: site,
                poster: data["metadata"]["poster"]
            );
            String info = data["info"];
            int timestamp = data["timestamp"];
            int duration = data["duration"];

            String id = metadata.site.name + metadata.url;
            this._keepWatching[id] = SerialMetadata(metadata: metadata, info: info, timestamp: timestamp, duration: duration);
        }
    }

    @override
    Future<void> save() async {
        List<String> list = [];

        for (SerialMetadata data in this._keepWatching.values)
            list.add(jsonEncode(data.serialize()));
        super["KeepWatching"] = list;

        super.save();
    }

    static Future<Watchable?> getWatchable(TitleMetadata metadata) async{
        String id = metadata.site.name + metadata.url;
        if(KeepWatching.instance._keepWatching.containsKey(id))
            return Watchable.unserialize(
                KeepWatching.instance._keepWatching[id]!.metadata,
                KeepWatching.instance._keepWatching[id]!.info
            );
        
        return null;
    }

    static int? getTimestamp(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        String info = Watchable.genInfo(watchable);
        String id = data.site.name + data.url;
        if (KeepWatching.instance._keepWatching.containsKey(id) && KeepWatching.instance._keepWatching[id]?.info == info)
            return KeepWatching.instance._keepWatching[id]?.timestamp;
        return null;
    }

    static int? getDuration(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        String info = Watchable.genInfo(watchable);
        String id = data.site.name + data.url;
        if (KeepWatching.instance._keepWatching.containsKey(id) && KeepWatching.instance._keepWatching[id]?.info == info)
            return KeepWatching.instance._keepWatching[id]?.duration;
        return null;
    }

    static void add(Watchable watchable, int timestamp, int duration) {
        SerialMetadata data = SerialMetadata.fromWatchable(watchable, timestamp, duration);
        String id = data.metadata.site.name + data.metadata.url;
        KeepWatching.instance._keepWatching[id] = data;

        KeepWatching.instance.save();
    }

    static void remove(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        KeepWatching.instance._keepWatching.remove(id);

        KeepWatching.instance.save();
    }
}