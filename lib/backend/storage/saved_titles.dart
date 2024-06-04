import 'dart:convert';

import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/storage/local_storage.dart';

class SavedTitles extends LocalStorage {
    static final SavedTitles instance = SavedTitles._();
    SavedTitles._() : super({ "SavedTitles": <String>[] });

    final Map<String, TitleMetadata> _savedTitles = {};

    @override
    Future<void> construct() async {
        await super.construct();

        for (String json in super["SavedTitles"]) {
            Map<String, dynamic> data = jsonDecode(json);

            TitleMetadata metadata = TitleMetadata(
                name: data["name"],
                url: data["url"],
                site: Site.get(data["site"])!,
                poster: data["poster"]);

            String id = metadata.site.name + metadata.url;
            this._savedTitles[id] = metadata;
        }
    }

    @override
    Future<void> save() async {
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

        super.save();
    }

    static List<TitleMetadata> getAll() {
        return SavedTitles.instance._savedTitles.values.toList();
    }

    static void add(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        SavedTitles.instance._savedTitles[id] = metadata;
        SavedTitles.instance.save();
    }

    static void remove(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        SavedTitles.instance._savedTitles.remove(id);
        SavedTitles.instance.save();
    }

    static bool isSaved(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        return SavedTitles.instance._savedTitles.containsKey(id);
    }
}
