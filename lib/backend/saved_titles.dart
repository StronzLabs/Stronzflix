import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';

sealed class SavedTitles {
    SavedTitles._();

    static late SharedPreferences _prefs;

    static final Map<String, TitleMetadata> _savedTitles = {};

    static List<TitleMetadata> getAll() {
        return _savedTitles.values.toList();
    }

    static Future<void> init() async {
        SavedTitles._prefs = await SharedPreferences.getInstance();

        if (!SavedTitles._prefs.containsKey("SavedTitles"))
            SavedTitles._prefs.setStringList("SavedTitles", []);

        SavedTitles.loadState();
    }

    static void add(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        SavedTitles._savedTitles[id] = metadata;

        SavedTitles.saveState();
    }

    static void remove(TitleMetadata metadata) {
        String id = metadata.site.name + metadata.url;
        SavedTitles._savedTitles.remove(id);

        SavedTitles.saveState();
    }

    static bool isSaved(TitleMetadata metadata){
        String id = metadata.site.name + metadata.url;
        return SavedTitles._savedTitles.containsKey(id);
    }

    static Future<void> saveState() async {
        List<String> list = [];

        for (TitleMetadata metadata in SavedTitles._savedTitles.values) {
            String serializedMetadata = jsonEncode({
                "name": metadata.name,
                "url": metadata.url,
                "site": metadata.site.name,
                "poster": metadata.poster
            });

            list.add(serializedMetadata);
        }
        await SavedTitles._prefs.setStringList("SavedTitles", list);
    }

    static void loadState() {
        List<String> list = SavedTitles._prefs.getStringList("SavedTitles")!;

        for (String json in list) {
            Map<String, dynamic> data = jsonDecode(json);

            TitleMetadata metadata = TitleMetadata(
                name: data["name"],
                url: data["url"],
                site: Site.get(data["site"])!,
                poster: data["poster"]);

            String id = metadata.site.name + metadata.url;
            SavedTitles._savedTitles[id] = metadata;
        }
    }
}
