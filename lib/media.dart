import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:video_player/video_player.dart';

import 'components/player_controls.dart';

class MediaPage extends StatefulWidget {

    final Playable media;
    const MediaPage({super.key, required this.media});

    @override
    State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {

    late VideoPlayerController _videoPlayerController;
    late ChewieController _chewieController;

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
            customControls: const PlayerControls(),
            hideControlsTimer: const Duration(seconds: 1, milliseconds: 500),
        );
    }

    @override
    void dispose() {
        this._videoPlayerController.dispose();
        this._chewieController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text(super.widget.media.name),
            ),
            body: Center(
                child: FutureBuilder(
                    future: this._initVideoPlayer(),
                    builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done)
                            return Chewie(
                                controller: this._chewieController,
                            );
                        else if (snapshot.hasError)
                            return const Text("Errore");
                        else
                            return const CircularProgressIndicator();
                    }
                )
            )
        );
    }
}
