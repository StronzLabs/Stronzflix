import 'dart:convert';

import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/backend/streamingcommunity.dart';
import 'package:stronzflix/backend/vixxcloud.dart';
import 'package:stronzflix/backend/storage.dart';

class SerialInfo {
    String name;
    String siteUrl;
    String site;
    int startAt;
    String cover;

    SerialInfo({
        required this.siteUrl,
        required this.site,
        this.startAt = 0,
        this.cover = "",
        this.name = "",
    });

    SerialInfo.fromJson(Map<String, dynamic> json) :
        this.name = json["name"],
        this.siteUrl = json["siteUrl"],
        this.site = json["site"],
        this.startAt = json["startAt"],
        this.cover = json["cover"];

    Map<String, dynamic> toJson() => {
        "name": this.name,
        "siteUrl": this.siteUrl,
        "site": this.site,
        "startAt": this.startAt,
        "cover": this.cover
    };

    @override
    String toString() => jsonEncode(this.toJson());
}

class Backend {

    static int startWatching(String site, String siteUrl, {int? startAt}) {
        int startTime = Storage.startWatching(site, siteUrl, startAt: startAt);

        SerialInfo serialInfo = SerialInfo(
            siteUrl: siteUrl,
            site: site,
            startAt: startTime
        );
        PeerManager.startWatching(serialInfo);

        return startTime;
    }

    static void stopWatching() {
        PeerManager.stopWatching();
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
        await Storage.init();

        StreamingCommunity.instance;
        VixxCloud.instance;
    }
}