import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/utils/storage.dart';
import 'package:video_player/video_player.dart';

import '../components/player_controls.dart';

class MediaPage extends StatefulWidget {

    final IWatchable media;
    final Duration startAt;
    const MediaPage({super.key, required this.media, this.startAt = const Duration()});

    @override
    State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> with WidgetsBindingObserver {

    late VideoPlayerController _videoPlayerController;
    late ChewieController _chewieController;
    late final AppLifecycleListener _lifecycleListener;

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
            startAt: super.widget.startAt,
        );
    }

    void _saveState() async {
        Storage.updateWatching(super.widget.media, this._videoPlayerController.value.position.inMilliseconds);
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
        Storage.startWatching(super.widget.media);
    }

    @override
    void dispose() {
        this._videoPlayerController.dispose();
        this._chewieController.dispose();
        WidgetsBinding.instance.removeObserver(this);
        this._lifecycleListener.dispose();
        this._saveState();
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
                                    controller: this._chewieController,
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
