import 'dart:convert';

import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/storage/local_storage.dart';

class Settings extends LocalStorage {
    static final Settings instance = Settings._();
    Settings._() : super({
        "site": "StreamingCommunity",
        "domains": jsonEncode({"Scaricati": ""})
    });

    static Site get site => Site.get(Settings.instance["site"])!;
    static set site(Site site) => Settings.instance["site"] = site.name;
    static Map<String, String> get domains => jsonDecode(Settings.instance["domains"]).cast<String, String>();
    static bool online = false;
    static Future<void> update() => Settings.instance.save();
}
