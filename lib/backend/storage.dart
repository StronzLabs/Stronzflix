import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/media.dart';

final class Storage {
    static late SharedPreferences _prefs;

    static late Map<String, SerialInfo> _keepWatchingList;
    static String? _lastId;
    static Map<String, SerialInfo> get keepWatching => Storage._keepWatchingList;

    static Future<void> init() async {
        Storage._prefs = await SharedPreferences.getInstance();

        if (!Storage._prefs.containsKey("SerialInfo"))
            Storage._prefs.setStringList("SerialInfo", []);

        Iterable<dynamic> serialInfos = Storage._prefs.getStringList("SerialInfo")!.map((e) => jsonDecode(e));

        Storage._keepWatchingList = {
            for (dynamic serialInfo in serialInfos)
                "${serialInfo["site"]}_${serialInfo["siteUrl"]}" : SerialInfo.fromJson(serialInfo)
        };
    }

    static void serialize() {
        List<String> serialInfos = Storage._keepWatchingList.values.map<String>((element) => element.toString()).toList();
        Storage._prefs.setStringList("SerialInfo", serialInfos);
    }

    static String _calcID(String site, String siteUrl) => "${site}_${siteUrl}";

    static int startWatching(String site, String siteUrl, {int? startAt}) {
        Storage._lastId = Storage._calcID(site, siteUrl);

        if (!Storage.keepWatching.containsKey(Storage._lastId))
            Storage.keepWatching[Storage._lastId!] = SerialInfo(
                siteUrl: siteUrl,
                site: site,
                startAt: startAt ?? 0
            );

        return Storage.keepWatching[Storage._lastId]!.startAt;
    }

    static void removeWatching(String site, String siteUrl) {
        String id = Storage._calcID(site, siteUrl);
        Storage._keepWatchingList.remove(id);
    }

    static void updateWatching(Watchable media, int time) {
        if (Storage.keepWatching.containsKey(Storage._lastId)) {
            Storage.keepWatching[Storage._lastId]!.name = media.name;
            Storage.keepWatching[Storage._lastId]!.cover = media.cover;
            Storage.keepWatching[Storage._lastId]!.startAt = time;
        }
    }
}
