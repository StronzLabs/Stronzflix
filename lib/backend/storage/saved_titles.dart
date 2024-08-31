import 'dart:convert';

import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/sutils.dart';

class SavedTitles extends LocalStorage {
    static final SavedTitles instance = SavedTitles._();
    SavedTitles._() : super("SavedTitles", {
        "SavedTitles": <String>[]
    });

    final Map<String, TitleMetadata> _savedTitles = {};

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
                url: data["url"],
                site: site,
                poster: data["poster"]);

            String id = metadata.site.name + metadata.url;
            this._savedTitles[id] = metadata;
        }
    }

    @override
    Future<void> serialize() async {
        List<String> list = [];

        for (TitleMetadata metadata in this._savedTitles.values) {
            String serializedMetadata = jsonEncode({
                "name": metadata.name,
                "url": metadata.url,
                "site": metadata.site.name,
                "poster": metadata.poster
            });

            list.add(serializedMetadata);
        }
        super["SavedTitles"] = list;

        super.serialize();
    }

    static List<TitleMetadata> getAll() {
        return SavedTitles.instance._savedTitles.values.toList();
    }

    static void add(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        SavedTitles.instance._savedTitles[id] = metadata;
        SavedTitles.instance.serialize();
    }

    static void remove(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        SavedTitles.instance._savedTitles.remove(id);
        SavedTitles.instance.serialize();
    }

    static bool isSaved(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        return SavedTitles.instance._savedTitles.containsKey(id);
    }
}
