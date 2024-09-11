import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/sutils.dart';

class _SavedMetadatas extends ValueNotifier<Iterable<TitleMetadata>> {
    final Map<String, TitleMetadata> _data = {};

    _SavedMetadatas() : super([]);

    TitleMetadata operator [](String key) => this._data[key]!;

    void operator []=(String key, TitleMetadata value) {
        this._data[key] = value;
        this.value = this._data.values;
    }

    void remove(String key) {
        this._data.remove(key);
        this.value = this._data.values;
    }

    bool contains(String key) => this._data.containsKey(key);
}

class SavedTitles extends LocalStorage {
    static final SavedTitles instance = SavedTitles._();
    SavedTitles._() : super("SavedTitles", {
        "SavedTitles": <String>[]
    });

    final _SavedMetadatas _savedTitles = _SavedMetadatas();
    static ValueNotifier<Iterable<TitleMetadata>> get listener => SavedTitles.instance._savedTitles;
    static Iterable<TitleMetadata> get all => SavedTitles.instance._savedTitles.value;

    @override
    Future<void> unserialize() async {
        await super.unserialize();

        for (String json in super["SavedTitles"]) {
            Map<String, dynamic> data = jsonDecode(json);

            Site? site = Site.get(data["site"]);
            if(site == null)
                continue;

            TitleMetadata metadata = TitleMetadata(
                name: data["name"],
                uri: Uri.parse(data["uri"]),
                site: site,
                poster: Uri.parse(data["poster"]));

            String id = metadata.site.name + metadata.uri.toString();
            this._savedTitles[id] = metadata;
        }
    }

    @override
    Future<void> serialize() async {
        List<String> list = [];

        for (TitleMetadata metadata in this._savedTitles.value) {
            String serializedMetadata = jsonEncode({
                "name": metadata.name,
                "uri": metadata.uri.toString(),
                "site": metadata.site.name,
                "poster": metadata.poster.toString()
            });

            list.add(serializedMetadata);
        }
        super["SavedTitles"] = list;

        super.serialize();
    }

    static void add(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.uri.toString();
        SavedTitles.instance._savedTitles[id] = metadata;
        SavedTitles.instance.serialize();
    }

    static void remove(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.uri.toString();
        SavedTitles.instance._savedTitles.remove(id);
        SavedTitles.instance.serialize();
    }

    static bool isSaved(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.uri.toString();
        return SavedTitles.instance._savedTitles.contains(id);
    }
}
