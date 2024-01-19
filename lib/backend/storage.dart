import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/media.dart';

final class Storage {
    static late SharedPreferences _prefs;

    static late Map<String, SerialInfo> _keepWatchingList;
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

    static String? _currentlyWatching;

    static int startWatching(String site, String siteUrl, {int? startAt}) {
        Storage._currentlyWatching = Storage._calcID(site, siteUrl);

        if (!Storage.keepWatching.containsKey(Storage._currentlyWatching!))
            Storage.keepWatching[Storage._currentlyWatching!] = SerialInfo(
                siteUrl: siteUrl,
                site: site,
                startAt: startAt ?? 0
            );

        return Storage.keepWatching[Storage._currentlyWatching!]!.startAt;
    }

    static void stopWatching() {
        Storage._currentlyWatching = null;
    }

    static void removeWatching({SerialInfo? serialInfo}) {
        String id = serialInfo == null ? Storage._currentlyWatching! : Storage._calcID(serialInfo.site, serialInfo.siteUrl);
        Storage._keepWatchingList.remove(id);
        Storage.stopWatching();
    }

    static void updateWatching(Watchable media, int time) {
        Storage.keepWatching[_currentlyWatching]!.name = media.name;
        Storage.keepWatching[_currentlyWatching]!.cover = media.cover;
        Storage.keepWatching[_currentlyWatching]!.startAt = time;
    }
}
