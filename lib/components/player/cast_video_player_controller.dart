import 'dart:async';

import 'package:cast/cast.dart';
import 'package:stronz_video_player/data/tracks.dart';
import 'package:stronz_video_player/stronz_video_player.dart';
import 'package:stronzflix/backend/cast.dart';

class CastVideoPlayerController extends StronzPlayerController {

    int? _mediaSessionId;
    Timer? _pollTimer;

    Future<void> _load(Uri uri) async {
        Map<String, dynamic> mediaStatus = await CastManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "LOAD",
            "media": {
                "contentId": uri.toString(),
                "streamType": "BUFFERED",
                "contentType": "application/vnd.apple.mpegurl"
            }
        });

        if(mediaStatus["type"] == "LOAD_FAILED")
            throw Exception("Cannot load media cast:${mediaStatus["detailedErrorCode"]}");

        this._mediaSessionId = mediaStatus["status"].firstWhere(
            (session) => session["media"]["contentId"] == uri.toString()
        )["mediaSessionId"];
    }

    @override
    Future<void> initialize(Playable playable, {StronzControllerState? initialState}) async {
        await super.initialize(playable, initialState: initialState);

        await this._load(super.tracks.masterSource);

        this._pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
            CastManager.sendMessage(CastSession.kNamespaceMedia, {
                "type": "GET_STATUS",
                "mediaSessionId": this._mediaSessionId,
            }).then(this._onStatus);
        });

        if(initialState == null)
            return;
        if(initialState.playing ?? false)
            await this.play();
        if(initialState.position != null)
            await this.seekTo(initialState.position!);
        if(initialState.volume != null)
            await this.setVolume(initialState.volume!);
    }

    void _onStatus(Map<String, dynamic> message) {
        if(this._mediaSessionId == null || message["type"] != "MEDIA_STATUS")
            return;

        Map<String, dynamic> status = message["status"].firstWhere(
            (status) => status["mediaSessionId"] == this._mediaSessionId,
            orElse: () => {}
        );
        if(status.isEmpty)
            return;

        super.playing = status["playerState"] == "PLAYING";
        super.buffering = status["playerState"] == "BUFFERING";
        super.completed = status["playerState"] == "IDLE" && status["idleReason"] == "FINISHED";
        super.position = Duration(seconds: status["currentTime"].floor());

        if(status.containsKey("media"))
            super.duration = Duration(seconds: status["media"]["duration"].toDouble().floor());

        // TODO: Stream volume must not be used in conjunction with the volume slider or volume buttons to control the device volume
        // https://developers.google.com/cast/docs/media/messages#Volume
    }

    @override
    Future<void> dispose() async {
        this._pollTimer?.cancel();
        await CastManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "STOP",
            "mediaSessionId": this._mediaSessionId
        });
        super.dispose();
    }

    @override
    Future<void> pause() async {
        await super.pause();
        await CastManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "PAUSE",
            "mediaSessionId": this._mediaSessionId,
        }).then(this._onStatus);
    }

    @override
    Future<void> play() async {
        await super.play();
        await CastManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "PLAY",
            "mediaSessionId": this._mediaSessionId,
        }).then(this._onStatus);
    }

    @override
    Future<void> seekTo(Duration position) async {
        await CastManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "SEEK",
            "mediaSessionId": this._mediaSessionId,
            "currentTime": position.inSeconds,
        }).then(this._onStatus);
    }

    @override
    Future<void> setVolume(double volume) async {
        await super.setVolume(volume);
        // TODO: Stream volume must not be used in conjunction with the volume slider or volume buttons to control the device volume
        // https://developers.google.com/cast/docs/media/messages#Volume
    }

    @override
    Future<void> switchTo(Playable playable) async {
        super.buffering = true;
        Uri uri = await playable.source;
        await this._load(uri);
        await super.switchTo(playable);
        super.buffering = false;
    }

    @override
    Future<void> setAudioTrack(AudioTrack? track) => throw UnimplementedError();
    @override
    Future<void> setCaptionTrack(CaptionTrack? track) => throw UnimplementedError();
    @override
    Future<void> setVideoTrack(VideoTrack? track) => throw UnimplementedError();

}