import 'dart:async';

import 'package:cast/cast.dart';
import 'package:stronzflix/backend/cast/cast.dart';

class CastV2Device extends CasterDevice {
    final CastDevice device;

    @override
    String get name => device.name;

    const CastV2Device(this.device);
}

class CastV2 extends CasterInterface {

    CastSession? _session;
    final Map<int, Completer> _subscribedIds = {};
    int _messageId = 1;

    int? _mediaSessionId;
    Timer? _pollTimer;

    @override
    Future<List<CastV2Device>> discovery() async {
        List<CastDevice> devices = await CastDiscoveryService().search();
        List<CastV2Device> results = devices.map((device) => CastV2Device(device)).toList();
        return results;
    }

    @override
    Future<void> connect(CasterDevice device) async {
        if(device is! CastV2Device)
            return;

        try {
            this._session = await CastSessionManager().startSession(device.device);
            this._session!.messageStream.listen(
                (message) => this._subscribedIds[message["requestId"]]?.complete(message)
            );
            this._session!.stateStream.listen(
                (state) {
                    if(state == CastSessionState.closed)
                        this.disconnect();
                }
            );

            Map<String, dynamic> status = await this._sendMessage(CastSession.kNamespaceReceiver, {
                'type': 'LAUNCH',
                'appId': 'CC1AD845',
            });

            bool succesfullyLaunched = status["status"]["applications"]?.any((app) => app["appId"] == "CC1AD845") ?? false;

            this._pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
                this._sendMessage(CastSession.kNamespaceMedia, {
                    "type": "GET_STATUS",
                    "mediaSessionId": this._mediaSessionId,
                }).then(this._onStatus);
            });

            if(succesfullyLaunched)
                CastManager.state.connected = true;
            else
                await this.disconnect();
        } catch (_) {
        }
    }

    @override
    Future<void> disconnect() async {
        try {
            await this._session?.close();
        } catch (_) {}
        this._pollTimer?.cancel();
        this._session = null;
        CastManager.state.connected = false;
    }

    @override
    Future<bool> loadMedia(Uri uri) async {
        Map<String, dynamic> mediaStatus = await this._sendMessage(CastSession.kNamespaceMedia, {
            "type": "LOAD",
            "media": {
                "contentId": uri.toString(),
                "streamType": "BUFFERED",
                "contentType": "application/vnd.apple.mpegurl"
            }
        });

        if(mediaStatus["type"] == "LOAD_FAILED")
            return false;

        this._mediaSessionId = mediaStatus["status"].firstWhere(
            (session) => session["media"]["contentId"] == uri.toString()
        )["mediaSessionId"];

        return true;
    }

    @override
    Future<void> play() async {
        await this._sendMessage(CastSession.kNamespaceMedia, {
            "type": "PLAY",
            "mediaSessionId": this._mediaSessionId,
        }).then(this._onStatus);
    }

    @override
    Future<void> pause() async {
        await this._sendMessage(CastSession.kNamespaceMedia, {
            "type": "PAUSE",
            "mediaSessionId": this._mediaSessionId,
        }).then(this._onStatus);
    }

    @override
    Future<void> stop() async {
        await this._sendMessage(CastSession.kNamespaceMedia, {
            "type": "STOP",
            "mediaSessionId": this._mediaSessionId
        }).then(this._onStatus);
    }
    
    @override
    Future<void> seekTo(Duration position) async {
        await this._sendMessage(CastSession.kNamespaceMedia, {
            "type": "SEEK",
            "mediaSessionId": this._mediaSessionId,
            "currentTime": position.inSeconds,
        }).then(this._onStatus);
    }

    @override
    Future<void> setVolume(double volume) async {
        // TODO: Stream volume must not be used in conjunction with the volume slider or volume buttons to control the device volume
        // https://developers.google.com/cast/docs/media/messages#Volume
    }

    Future<Map<String, dynamic>> _sendMessage(String namespace, Map<String, dynamic> payload) async {
        int id = this._messageId++;
        Completer c = Completer();
        payload["requestId"] = id;
        this._subscribedIds[id] = c;

        try {
            this._session?.sendMessage(namespace, payload);
        } catch (_) {
            c.complete({"error": "Failed to send message"});
        }

        Map<String, dynamic> response = await c.future;
        this._subscribedIds.remove(id);
        return response;
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

        CasterMediaState mediaState = CasterMediaState(
            playing: status["playerState"] == "PLAYING",
            buffering: status["playerState"] == "BUFFERING",
            completed: status["playerState"] == "IDLE" && status["idleReason"] == "FINISHED",
            position: Duration(seconds: status["currentTime"].floor()),
            duration: status.containsKey("media")
                ? Duration(seconds: status["media"]["duration"].toDouble().floor())
                : null
        );

        CastManager.state.mediaState = mediaState;
    }
}
