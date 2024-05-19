import 'package:shared_preferences/shared_preferences.dart';

class Settings {
    Settings._();

    static late final SharedPreferences _prefs;

    static late String site;

    static Future<void> load() async {
        Settings._prefs = await SharedPreferences.getInstance();
        Settings.site = Settings._prefs.getString("site") ?? "StreamingCommunity";
    }

    static Future<void> save() async {
        await Settings._prefs.setString("site", Settings.site);
    }
}