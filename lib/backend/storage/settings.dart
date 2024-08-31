import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/sutils.dart';

class Settings extends LocalStorage {
    static final Settings instance = Settings._();
    Settings._() : super("Settings", {
        "site": "StreamingCommunity",
        "domains": {"Scaricati": ""}
    });

    static Site get site => Site.get(Settings.instance["site"])!;
    static set site(Site site) => Settings.instance["site"] = site.name;
    static Map<String, dynamic> get domains => Settings.instance["domains"];
    static set domains(Map<String, dynamic> domains) => Settings.instance["domains"] = domains;
    static bool online = false;
}
