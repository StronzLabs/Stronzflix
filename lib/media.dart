import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:video_player/video_player.dart';
// import 'package:window_manager/window_manager.dart';

class MediaPage extends StatefulWidget {

    final Playable media;
    const MediaPage({super.key, required this.media});

    @override
    State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {

    late Future<Uri> _uri;

    late VideoPlayerController _videoPlayerController;
    late ChewieController _chewieController;

    @override
    void initState() {
        super.initState();

        this._uri = super.widget.media.player.getSource(super.widget.media);
        this._uri.then((uri) {
            this._videoPlayerController = VideoPlayerController.networkUrl(
                Uri.parse("$uri#.m3u8")
            );

            this._chewieController = ChewieController(
                videoPlayerController: this._videoPlayerController,
                autoPlay: true,
                allowedScreenSleep: false,
                aspectRatio: 16/9,
            );
        });

        // windowManager.setFullScreen(true);
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
                    future: this._uri,
                    builder: (context, snapshot) {
                        if (snapshot.hasData)
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
