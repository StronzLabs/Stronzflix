import 'dart:convert';

import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/storage/local_storage.dart';

class Settings extends LocalStorage {
    static final Settings instance = Settings._();
    Settings._() : super({
        "site": "StreamingCommunity",
        "domains": jsonEncode({"Scaricati": ""})
    });

    late final Map<String, String> _domains;

    @override
    Future<void> construct() async {
        await super.construct();

        this._domains = jsonDecode(Settings.instance["domains"]).cast<String, String>();
    }

    static Site get site => Site.get(Settings.instance["site"])!;
    static set site(Site site) => Settings.instance["site"] = site.name;
    static Map<String, String> get domains => Settings.instance._domains;
    static set domains(Map<String, String> domains) => Settings.instance["domains"] = jsonEncode(domains);
    static bool online = false;
    static Future<void> update() => Settings.instance.save();
}
