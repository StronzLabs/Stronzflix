import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/components/player_controls.dart';
import 'package:video_player/video_player.dart';

class MediaPage extends StatefulWidget {

    final Playable playable;
    const MediaPage({super.key, required this.playable});

    @override
    State<MediaPage> createState() => _MediaPageState();

    static Future<void> playMedia(BuildContext context, SerialInfo serialInfo, {bool peer = true}) async {
        Backend.startWatching(serialInfo.site, serialInfo.siteUrl, startAt: serialInfo.startAt, peer: peer);
        
        await Navigator.push(context, MaterialPageRoute(
            builder: (context) => MediaPage(
                playable: LatePlayable(serialInfo: serialInfo)
            )
        ));
    }
}

class _MediaPageState extends State<MediaPage> with WidgetsBindingObserver {

    late VideoPlayerController _videoPlayerController;
    late ChewieController _chewieController;
    late final AppLifecycleListener _lifecycleListener;

    late final Watchable _watchable;

    Future<void> _initVideoPlayer() async {
        this._watchable = await super.widget.playable.resolve();
        Uri uri = await this._watchable.player.getSource(this._watchable);
        uri = Uri.parse(uri.toString().split('?').join('.m3u8?'));
        this._videoPlayerController = VideoPlayerController.networkUrl(uri);

        await this._videoPlayerController.initialize();

        this._chewieController = ChewieController(
            videoPlayerController: this._videoPlayerController,
            autoPlay: true,
            allowedScreenSleep: false,
            aspectRatio: this._videoPlayerController.value.aspectRatio,
            customControls: PlayerControls(media: this._watchable),
            hideControlsTimer: const Duration(seconds: 1, milliseconds: 500),
            startAt: Duration(milliseconds: this._watchable.startAt),
        );
    }

    void _saveState() {
        Backend.updateWatching(this._watchable, this._videoPlayerController.value.position.inMilliseconds);
        if (this._videoPlayerController.value.position.inMilliseconds >= this._videoPlayerController.value.duration.inMilliseconds * 0.9)
            Backend.removeWatching();
        Backend.serialize();
    }

    @override
    void initState() {
        super.initState();

        WidgetsBinding.instance.addObserver(this);
        this._lifecycleListener = AppLifecycleListener(
            onStateChange: (_) => this._saveState,
            onExitRequested: () async { this._saveState(); return AppExitResponse.exit; }
        );

        PeerManager.registerHandler(PeerMessageIntent.stopWatching,
            (_) {
                Navigator.of(super.context).pop();
                PeerManager.isNotWatching();
            }
        );
    }

    @override
    void dispose() {
        this._saveState();
        Backend.stopWatching();
        this._videoPlayerController.dispose();
        this._chewieController.dispose();
        WidgetsBinding.instance.removeObserver(this);
        this._lifecycleListener.dispose();
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
        if (state == AppLifecycleState.detached)
            this._saveState();
    }

    @override
    Widget build(BuildContext context) {
        return PopScope(
            onPopInvoked: (_) => this._saveState(),
            child: Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                    child: FutureBuilder(
                        future: this._initVideoPlayer(),
                        builder: (context, snapshot) {
                            if (snapshot.hasError)
                                return const Icon(Icons.error);
                            else if (snapshot.connectionState == ConnectionState.done)
                                return Chewie(
                                    controller: this._chewieController
                                );
                            else
                                return const CircularProgressIndicator();
                        }
                    )
                )
            )
        );
    }
}
