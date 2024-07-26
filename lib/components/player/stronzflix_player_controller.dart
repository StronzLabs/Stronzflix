import 'dart:async';

import 'package:cast/device.dart';
import 'package:cast/session.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/cast.dart';
import 'package:stronzflix/backend/media_session.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/utils/utils.dart';
import 'package:http/http.dart' as http;

class StronzflixPlayerStream {
    final Stream<bool> buffering;
    final Stream<bool> playing;
    final Stream<bool> completed;
    final Stream<Duration> position;
    final Stream<Duration> duration;
    final Stream<double> volume;
    final Stream<Duration> buffer;

    const StronzflixPlayerStream({
        this.buffering = const Stream.empty(),
        this.playing = const Stream.empty(),
        this.position = const Stream.empty(),
        this.duration = const Stream.empty(),
        this.volume = const Stream.empty(),
        this.buffer = const Stream.empty(),
        this.completed = const Stream.empty(),
    });
}

abstract class StronzflixPlayerController {

    final Watchable _watchable;

    StronzflixPlayerController(this._watchable);

    Duration get position;
    Duration get duration;
    Duration get buffer;
    bool get isBuffering;
    bool get isPlaying;
    double get volume;
    bool get isCompleted;
    StronzflixPlayerStream get stream;

    String get title {
        if (this._watchable is Film)
            return this._watchable.name;
        else if (this._watchable is Episode)
            return '${this._watchable.season.series.name} - ${this._watchable.name}';
        else
            throw Exception('Unknown watchable type');
    }

    String get thumbnail {
        if (this._watchable is Film)
            return this._watchable.banner;
        else if (this._watchable is Episode)
            return this._watchable.cover;
        else
            throw Exception('Unknown watchable type');
    }

    @mustCallSuper
    Future<void> initialize(Uri uri, Duration startAt) async {
        await MediaSession.start(this.title, this.thumbnail, (event) => switch (event) {
            MediaSessionEvent.play => this.play(),
            MediaSessionEvent.pause => this.pause(),
        });
    }

    @mustCallSuper
    Future<void> dispose() async {
        await MediaSession.stop();
    }

    @mustCallSuper
    Future<void> play({bool sink = false}) async {
        if(!sink)
            await PeerMessenger.play();
        MediaSession.informPlaying();
    }
    @mustCallSuper
    Future<void> pause({bool sink = false}) async {
        if(!sink)
            await PeerMessenger.pause();
        MediaSession.informPaused();
    }
    
    Future<void> playOrPause() => this.isPlaying ? this.pause() : this.play();

    Watchable? get next {
        Watchable current = this._watchable;
        Watchable? next;
        if (current is Episode) {
            Season season = current.season;
            Series series = season.series;
            int episodeNo = season.episodes.indexOf(current);
            int seasonNo = series.seasons.indexOf(season);

            if (episodeNo < season.episodes.length - 1)
                next = season.episodes[episodeNo + 1];
            else if (seasonNo < series.seasons.length - 1)
                next = series.seasons[seasonNo + 1].episodes[0];      
        } 
        return next;
    }
    
    @mustCallSuper
    Future<void> seekTo(Duration position, {bool sink = false}) async { if(!sink) PeerMessenger.seek(position.inSeconds); } 
    Future<void> setVolume(double volume);
}

StronzflixPlayerController playerController(BuildContext context, {bool listen = false}) {
    return FullScreenProvider.of<StronzflixPlayerController>(context, listen: listen);
}

class LocalPlayerController extends StronzflixPlayerController {

    final Player _player = Player(
        configuration: const PlayerConfiguration(
            title: "Stronzflix"
        )
    );
    late VideoController _controller;
    VideoController get controller => this._controller;

    LocalPlayerController(super._watchable) {
        // FIXME: https://github.com/media-kit/media-kit/issues/837#issuecomment-2125734802
        this._controller = VideoController(this._player);
    }

    @override
    Duration get position => this._controller.player.state.position;
    @override
    Duration get duration => this._controller.player.state.duration;
    @override
    bool get isBuffering => this._controller.player.state.buffering;
    @override
    bool get isPlaying => this._controller.player.state.playing;
    @override
    double get volume => this._controller.player.state.volume;
    @override
    Duration get buffer => this._controller.player.state.buffer;
    @override
    bool get isCompleted => this._controller.player.state.completed;
    @override
    StronzflixPlayerStream get stream => StronzflixPlayerStream(
        buffering: this._controller.player.stream.buffering,
        playing: this._controller.player.stream.playing,
        position: this._controller.player.stream.position,
        duration: this._controller.player.stream.duration,
        volume: this._controller.player.stream.volume,
        buffer: this._controller.player.stream.buffer,
        completed: this._controller.player.stream.completed,
    );

    @override
    Future<void> initialize(Uri uri, Duration startAt) async {
        await super.initialize(uri, startAt);
        await this._player.open(Media(
            uri.toString(),
            // start: startAt
        ));
        await this._player.setSubtitleTrack(
            this._player.state.tracks.subtitle.firstWhere((track) => track.id == "no")
        );
    }

    @override
    Future<void> dispose() async {
        await super.dispose();
        await this._controller.player.dispose();
    }

    @override
    Future<void> play({bool sink = false}) async {
        await super.play(sink: sink);
        await this._controller.player.play();
    }

    @override
    Future<void> pause({bool sink = false}) async {
        await super.pause(sink: sink);
        await this._controller.player.pause();
    }

    @override
    Future<void> seekTo(Duration position, {bool sink = false}) async {
        await super.seekTo(position, sink: sink);
        await this._controller.player.seek(position);
    }

    @override
    Future<void> setVolume(double volume) => this._controller.player.setVolume(volume);
}

class CastPlayerController extends StronzflixPlayerController {
    late final CastManager _castManager;
    final CastDevice _device;
    int? _mediaSessionId;

    Timer? _pollTimer;

    CastPlayerController(super._watchable, this._device);

    bool _playing = false;
    final StreamController<bool> _playingStream = StreamController<bool>.broadcast();
    @override
    bool get isPlaying => this._playing;

    bool _buffering = false;
    final StreamController<bool> _bufferingStream = StreamController<bool>.broadcast();
    @override
    bool get isBuffering => this._buffering;

    Duration _position = Duration.zero;
    final StreamController<Duration> _positionStream = StreamController<Duration>.broadcast();
    @override
    Duration get position => this._position;

    Duration _duration = Duration.zero;
    final StreamController<Duration> _durationStream = StreamController<Duration>.broadcast();
    @override
    Duration get duration => this._duration;

    bool _completed = false;
    final StreamController<bool> _completedStream = StreamController<bool>.broadcast();
    @override
    bool get isCompleted => this._completed;

    @override
    double get volume => 100.0;
    
    @override
    Duration get buffer => Duration.zero;
    
    @override
    StronzflixPlayerStream get stream => StronzflixPlayerStream(
        playing: this._playingStream.stream,
        buffering: this._bufferingStream.stream,
        position: this._positionStream.stream,
        duration: this._durationStream.stream,
        completed: this._completedStream.stream,
    );

    Future<String> _findContenType(Uri uri) async {
        http.Response response = await http.head(uri);
        return response.headers["content-type"] ?? "application/vnd.apple.mpegurl";
    }

    @override
    Future<void> initialize(Uri uri, Duration startAt) async {
        await super.initialize(uri, startAt);

        this._castManager = await CastManager.connect(this._device);
        this._castManager.registerListener(this._updateValue);

        String contentType = await this._findContenType(uri);

        await this._castManager.sendMessage(CastSession.kNamespaceReceiver, {
            'type': 'LAUNCH',
            'appId': 'CC1AD845',
        }).then((_) =>
            this._castManager.sendMessage(CastSession.kNamespaceMedia, {
                "type": "LOAD",
                "media": {
                    "contentId": uri.toString(),
                    "streamType": "BUFFERED",
                    "contentType": contentType
                }
            })
        ).then((status) {
            // TODO: do somethings for errors
            print(status);
            List<dynamic> sessions = status["status"];
            this._mediaSessionId = sessions.firstWhere((session) => session["media"]["contentId"] == uri.toString())["mediaSessionId"];
        
            this.seekTo(startAt);
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
        await super.dispose();

        this._pollTimer?.cancel();
        this._castManager.disconnect();
        this._playingStream.close();
        this._bufferingStream.close();
        this._positionStream.close();
        this._durationStream.close();
    }

    @override
    Future<void> play({bool sink = false}) async {
        await super.play(sink: sink);
        await this._castManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "PLAY",
            "mediaSessionId": this._mediaSessionId,
        });
    }

    @override
    Future<void> pause({bool sink = false}) async {
        await super.pause(sink: sink);
        await this._castManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "PAUSE",
            "mediaSessionId": this._mediaSessionId,
        });
    }

    @override
    Future<void> seekTo(Duration position, {bool sink = false}) async {
        await super.seekTo(position, sink: sink);
        await this._castManager.sendMessage(CastSession.kNamespaceMedia, {
            "type": "SEEK",
            "mediaSessionId": this._mediaSessionId,
            "currentTime": position.inSeconds,
        });
    }

    @override
    Future<void> setVolume(double volume) async {}

    void _updateValue(Map<String, dynamic> message) {
        if(this._mediaSessionId == null || message["type"] != "MEDIA_STATUS")
            return;
    
        Map<String, dynamic> status = message["status"].firstWhere((status) => status["mediaSessionId"] == this._mediaSessionId);

        bool playing = status["playerState"] == "PLAYING";
        if(this._playing != playing) {
            this._playing = playing;
            this._playingStream.add(playing);
        }

        bool buffering = status["playerState"] == "BUFFERING";
        if(this._buffering != buffering) {
            this._buffering = buffering;
            this._bufferingStream.add(buffering);
        }

        Duration position = Duration(seconds: status["currentTime"].floor());
        if(this._position != position) {
            this._position = position;
            this._positionStream.add(position);
        }

        bool completed = status["playerState"] == "IDLE" && status["idleReason"] == "FINISHED";
        if(this._completed != completed) {
            this._completed = completed;
            this._completedStream.add(completed);
        }

        if(!status.containsKey("media"))
            return;

        Duration duration = Duration(seconds: status["media"]["duration"].toDouble().floor());
        if(this._duration != duration) {
            this._duration = duration;
            this._durationStream.add(duration);
        }
    }
}
