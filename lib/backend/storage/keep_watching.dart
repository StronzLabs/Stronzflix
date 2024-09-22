import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/sutils.dart';

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
                uri: Uri.parse(data["metadata"]["uri"]),
                site: Site.get(data["metadata"]["site"])!,
                poster: Uri.parse(data["metadata"]["poster"])
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
            "uri": this.metadata.uri.toString(),
            "site": this.metadata.site.name,
            "poster": this.metadata.poster.toString()
        },
        "info": this.info,
        "timestamp": this.timestamp,
        "duration": this.duration
    };
}

class _KeepWatchingMetadatas extends ValueNotifier<Iterable<SerialMetadata>> {
    final Map<String, SerialMetadata> _data = {};

    _KeepWatchingMetadatas() : super([]);

    SerialMetadata operator [](String key) => this._data[key]!;

    void operator []=(String key, SerialMetadata value) {
        this._data[key] = value;
        this.value = this._data.values;
    }

    void remove(String key) {
        this._data.remove(key);
        this.value = this._data.values;
    }

    bool contains(String key) => this._data.containsKey(key);
}

class KeepWatching extends LocalStorage {
    static final KeepWatching instance = KeepWatching._();
    KeepWatching._() : super("KeepWatching", {
        "KeepWatching": <String>[]
    });

    final _KeepWatchingMetadatas _keepWatching = _KeepWatchingMetadatas();
    static ValueNotifier<Iterable<SerialMetadata>> get listener => KeepWatching.instance._keepWatching;
    static List<TitleMetadata> get metadata => KeepWatching.instance._keepWatching.value.map((data) => data.metadata).toList();

    @override
    Future<void> unserialize() async {
        await super.unserialize();

        for (String json in super["KeepWatching"]) {
            Map<String, dynamic> data = jsonDecode(json);

            Site? site = Site.get(data["metadata"]["site"]);
            if(site == null)
                continue;

            TitleMetadata metadata = TitleMetadata(
                name: data["metadata"]["name"],
                uri: Uri.parse(data["metadata"]["uri"]),
                site: site,
                poster: Uri.parse(data["metadata"]["poster"])
            );
            String info = data["info"];
            int timestamp = data["timestamp"];
            int duration = data["duration"];

            String id = metadata.site.name + metadata.uri.toString();
            this._keepWatching[id] = SerialMetadata(metadata: metadata, info: info, timestamp: timestamp, duration: duration);
        }
    }

    @override
    Future<void> serialize() async {
        List<String> list = [
            for (SerialMetadata data in this._keepWatching.value)
                jsonEncode(data.serialize())
        ];

        super["KeepWatching"] = list;

        super.serialize();
    }

    static Future<Watchable?> getWatchable(TitleMetadata metadata) async{
        String id = metadata.site.name + metadata.uri.toString();
        if(KeepWatching.isWatched(metadata))
            return Watchable.unserialize(
                KeepWatching.instance._keepWatching[id].metadata,
                KeepWatching.instance._keepWatching[id].info
            );
        
        return null;
    }

    static int? getTimestamp(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        String info = Watchable.genInfo(watchable);
        String id = data.site.name + data.uri.toString();
        if (KeepWatching.isWatched(data) && KeepWatching.instance._keepWatching[id].info == info)
            return KeepWatching.instance._keepWatching[id].timestamp;
        return null;
    }

    static bool isWatched(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.uri.toString();
        return KeepWatching.instance._keepWatching.contains(id);
    }

    static int? getDuration(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        String info = Watchable.genInfo(watchable);
        String id = data.site.name + data.uri.toString();
        if (KeepWatching.isWatched(data) && KeepWatching.instance._keepWatching[id].info == info)
            return KeepWatching.instance._keepWatching[id].duration;
        return null;
    }

    static void add(Watchable watchable, int timestamp, int duration) {
        SerialMetadata data = SerialMetadata.fromWatchable(watchable, timestamp, duration);
        String id = data.metadata.site.name + data.metadata.uri.toString();
        KeepWatching.instance._keepWatching[id] = data;

        KeepWatching.instance.serialize();
    }

    static void remove(TitleMetadata metadata, {String? info}) {
        String id = metadata.site.name + metadata.uri.toString();
        if (info != null && KeepWatching.isWatched(metadata) && KeepWatching.instance._keepWatching[id].info != info)
            return;
        KeepWatching.instance._keepWatching.remove(id);
        KeepWatching.instance.serialize();
    }
}
