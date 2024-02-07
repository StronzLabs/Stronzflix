import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/api/media.dart';

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

    static int startWatching(String site, String siteUrl, {int? startAt, String episode = ""}) {
        Storage._lastId = Storage._calcID(site, siteUrl);

        if (!Storage._keepWatchingList.containsKey(Storage._lastId))
            Storage._keepWatchingList[Storage._lastId!] = SerialInfo(
                siteUrl: siteUrl,
                site: site,
                startAt: startAt ?? 0,
                episode: episode
            );

        return Storage._keepWatchingList[Storage._lastId]!.startAt;
    }

    static void watchNext(List<int> seasons) {
        SerialInfo serialInfo = Storage._keepWatchingList[Storage._lastId]!;
        serialInfo.startAt = 0;
        List<String> seasonXepisode = serialInfo.episode.split("x");
        int season = int.parse(seasonXepisode[0]) - 1;
        int episode = int.parse(seasonXepisode[1]) - 1;

        if (episode + 1 < seasons[season])
            serialInfo.episode = "${season + 1}x${episode + 2}";
        else if (season + 1 < seasons.length)
            serialInfo.episode = "${season + 2}x1";
        else
            throw Exception("No more episodes");

        Storage._keepWatchingList[Storage._lastId!] = serialInfo;
    }

    static void removeWatching(String site, String siteUrl) {
        String id = Storage._calcID(site, siteUrl);
        Storage._keepWatchingList.remove(id);
    }

    static void updateWatching(Watchable media, int time) {
        if (Storage._keepWatchingList.containsKey(Storage._lastId)) {
            Storage._keepWatchingList[Storage._lastId]!.name = media.name;
            Storage._keepWatchingList[Storage._lastId]!.cover = media.cover;
            Storage._keepWatchingList[Storage._lastId]!.startAt = time;
        }
    }
}
