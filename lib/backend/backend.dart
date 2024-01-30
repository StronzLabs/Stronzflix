import 'dart:convert';

import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/backend/api/streamingcommunity.dart';
import 'package:stronzflix/backend/api/vixxcloud.dart';
import 'package:stronzflix/backend/storage.dart';

class SerialInfo {
    String name;
    String siteUrl;
    String site;
    int startAt;
    String cover;
    String episode;

    SerialInfo({
        required this.siteUrl,
        required this.site,
        this.startAt = 0,
        this.cover = "",
        this.name = "",
        this.episode = ""
    });

    SerialInfo.fromJson(Map<String, dynamic> json) :
        this.name = json["name"],
        this.siteUrl = json["siteUrl"],
        this.site = json["site"],
        this.startAt = json["startAt"],
        this.cover = json["cover"],
        this.episode = json["episode"];

    Map<String, dynamic> toJson() => {
        "name": this.name,
        "siteUrl": this.siteUrl,
        "site": this.site,
        "startAt": this.startAt,
        "cover": this.cover,
        "episode": this.episode
    };

    @override
    String toString() => jsonEncode(this.toJson());
}

class Backend {

    static int startWatching(String site, String siteUrl, {int? startAt, String episode = ""}) {
        int startTime = Storage.startWatching(site, siteUrl, startAt: startAt, episode: episode);

        SerialInfo serialInfo = SerialInfo(
            siteUrl: siteUrl,
            site: site,
            startAt: startTime,
            episode: episode
        );
        PeerManager.startWatching(serialInfo);

        return startTime;
    }

    static void stopWatching() {
        PeerManager.stopWatching();
    }

    static void watchNext(List<int> seasons) {
        Storage.watchNext(seasons);
    }

    static void updateWatching(Watchable watchable, int time) {
        Storage.updateWatching(watchable, time);
    }

    static void removeWatching(String site, String siteUrl) {
        Storage.removeWatching(site, siteUrl);
    }

    static void serialize() {
        Storage.serialize();
    }

    static Future<void> init() async {
        await StreamingCommunity.instance.ensureInitialized();
        await VixxCloud.instance.ensureInitialized();

        await Storage.init();
    }
}