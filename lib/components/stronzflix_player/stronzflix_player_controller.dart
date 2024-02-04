import 'dart:async';

import 'package:cast/device.dart';
import 'package:cast/session.dart';
import 'package:flutter/foundation.dart';
import 'package:stronzflix/backend/cast.dart';
import 'package:stronzflix/components/stronzflix_player/stronzflix_player_sinks.dart';
import 'package:video_player/video_player.dart';

abstract class StronzflixPlayerController extends ValueNotifier<VideoPlayerValue> {
    final StronzflixPlayerSinks sink;

    StronzflixPlayerController(this.sink)
        : super(const VideoPlayerValue(duration: Duration.zero));

    Future<void> initialize();

    @override
    Future<void> dispose() async {
        super.dispose();
    }

    Duration get position => super.value.position;
    Duration get duration => super.value.duration;
    bool get isBuffering => super.value.isBuffering;
    bool get isPlaying => super.value.isPlaying;

    void play();
    void pause();
    void seekTo(Duration position);
}

class LocalPlayerController extends StronzflixPlayerController {
    final VideoPlayerController controller;

    LocalPlayerController(this.controller) : super(StronzflixPlayerSinks.local);

    @override
    Future<void> initialize() async {
        await this.controller.initialize();
        await this.controller.play();
        this.controller.addListener(this._updateValue);
    }

    @override
    Future<void> dispose() async {
        this.controller.removeListener(this._updateValue);
        await this.controller.dispose();
        super.dispose();
    }

    @override
    void play() {
        this.controller.play();
    }

    @override
    void pause() {
        this.controller.pause();
    }

    @override
    void seekTo(Duration position) {
        this.controller.seekTo(position);
    }

    void _updateValue() => super.value = this.controller.value;
}

class CastPlayerController extends StronzflixPlayerController {
    final Uri source;
    final CastDevice device;

    late final CastManager _castManager;
    int? _mediaSessionId;

    Timer? _pollTimer;

    CastPlayerController(this.source, this.device) : super(StronzflixPlayerSinks.cast);

    @override
    Future<void> initialize() async {
        this._castManager = await CastManager.connect(this.device);
        this._castManager.registerListener(this._updateValue);
        super.value = super.value.copyWith(isBuffering: true);

        await this._castManager.sendMessage(CastSession.kNamespaceReceiver, {
            'type': 'LAUNCH',
            'appId': 'CC1AD845',
        }).then((_) =>
            this._castManager.sendMessage(CastSession.kNamespaceMedia, {
                "type": "LOAD",
                "media": {
                    "contentId": this.source.toString(),
                    "streamType": "BUFFERED",
                    "contentType": "application/vnd.apple.mpegurl"
                }
            })
        ).then((status) {
            List<dynamic> sessions = status["status"];
            this._mediaSessionId = sessions.firstWhere((session) => session["media"]["contentId"] == this.source.toString())["mediaSessionId"];
        });

        this._pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
            this._castManager.sendMessage(CastSession.kNamespaceMedia, {
                "type": "GET_STATUS",
                "mediaSessionId": this._mediaSessionId,
            });
        });
    }

    @override
    Future<void> dispose() async {
        this._pollTimer?.cancel();
        this._castManager.disconnect();
        super.dispose();
    }

    @override
    void play() {
        this._castManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "PLAY",
            "mediaSessionId": this._mediaSessionId,
        });
    }

    @override
    void pause() {
        this._castManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "PAUSE",
            "mediaSessionId": this._mediaSessionId,
        });
    }

    @override
    void seekTo(Duration position) {
        this._castManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "SEEK",
            "mediaSessionId": this._mediaSessionId,
            "currentTime": position.inSeconds,
        });
    }

    void _updateValue(Map<String, dynamic> message) {
        if(this._mediaSessionId == null || message["type"] != "MEDIA_STATUS")
            return;
    
        Map<String, dynamic> status = message["status"].firstWhere((status) => status["mediaSessionId"] == this._mediaSessionId);
    
        super.value = super.value.copyWith(
            isInitialized: true,
            position: Duration(seconds: status["currentTime"].floor()),
            isBuffering: status["playerState"] == "BUFFERING",
            isPlaying: status["playerState"] == "PLAYING",
            isCompleted: status["playerState"] == "IDLE" && status["idleReason"] == "FINISHED",
            errorDescription: status["playerState"] == "IDLE" && status["idleReason"] == "ERROR" ? "An error occurred" : null,
        );

        if(status["media"] != null)
            super.value = super.value.copyWith(
                duration: Duration(seconds: status["media"]["duration"].toDouble().floor())
            );

        super.notifyListeners();
    }
}

