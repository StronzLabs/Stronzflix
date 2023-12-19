import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/components/player_controls.dart';
import 'package:stronzflix/utils/storage.dart';
import 'package:video_player/video_player.dart';

class MediaPage extends StatefulWidget {

    final IWatchable media;
    const MediaPage({super.key, required this.media});

    @override
    State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> with WidgetsBindingObserver {

    late VideoPlayerController _videoPlayerController;
    late ChewieController _chewieController;
    late final AppLifecycleListener _lifecycleListener;

    late Duration startAt;

    Duration _startAt() {
        TimeStamp? t = Storage.find(super.widget.media);
        if (t != null)
            return Duration(milliseconds: t.time);
        else
            return Duration.zero;
    }

    Future<void> _initVideoPlayer() async {
        Uri uri = await super.widget.media.player.getSource(super.widget.media);
        this._videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse("$uri#.m3u8")
        );

        await this._videoPlayerController.initialize();

        this._chewieController = ChewieController(
            videoPlayerController: this._videoPlayerController,
            autoPlay: true,
            allowedScreenSleep: false,
            aspectRatio: this._videoPlayerController.value.aspectRatio,
            customControls: PlayerControls(media: super.widget.media),
            hideControlsTimer: const Duration(seconds: 1, milliseconds: 500),
            startAt: this.startAt
        );
    }

    void _saveState() async {
        Storage.updateWatching(super.widget.media, this._videoPlayerController.value.position.inMilliseconds);
        if (this._videoPlayerController.value.position.inMilliseconds >= this._videoPlayerController.value.duration.inMilliseconds * 0.9)
            Storage.removeWatching(super.widget.media);

        Storage.serialize();
    }

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
        this._lifecycleListener = AppLifecycleListener(
            onStateChange: (_) => this._saveState,
            onExitRequested: () async { this._saveState(); return AppExitResponse.exit; }
        );
        this.startAt = this._startAt();
        Storage.startWatching(super.widget.media, at: this.startAt);
    }

    @override
    void dispose() {
        this._saveState();
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
