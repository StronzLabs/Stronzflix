import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
    Settings._();

    static late final SharedPreferences _prefs;

    static late String site;
    static late Map<String, String> domains;
    static bool online = false;

    static Future<void> load() async {
        Settings._prefs = await SharedPreferences.getInstance();

        Settings.site = Settings._prefs.getString("site") ?? "StreamingCommunity";
        Settings.domains = jsonDecode(Settings._prefs.getString("domains") ?? jsonEncode({"Scaricati": ""})).cast<String, String>();
    }

    static Future<void> save() async {
        await Settings._prefs.setString("site", Settings.site);
        await Settings._prefs.setString("domains", jsonEncode(Settings.domains));
    }
}