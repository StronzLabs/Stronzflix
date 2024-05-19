import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/widgets/video_controls_theme_data_injector.dart';
import 'package:provider/provider.dart';
import 'package:stronzflix/components/player/desktop_video_controls.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:stronzflix/utils/utils.dart';

class VideoPlayerView extends StatefulWidget {
    final Uri uri;
    
    const VideoPlayerView({
        super.key,
        required this.uri
    });

    @override
    State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {

    final LocalPlayerController _controller = LocalPlayerController();
    final AsyncMemoizer _controllerMemorizer = AsyncMemoizer();

    @override
    Widget build(BuildContext context) {
        return Center(
            child: Provider<StronzflixPlayerController>(
                create: (_) => this._controller,
                child: FutureBuilder(
                    future: this._controllerMemorizer.runOnce(
                        () => this._controller.initialize(
                            super.widget.uri,
                            FullScreenProvider.of<PlayerInfo>(context, listen: false).startAt
                        )
                    ),
                    builder: (context, snapshot) {
                        if(snapshot.connectionState != ConnectionState.done)
                            return const CircularProgressIndicator();

                        return Video(
                            controller: this._controller.controller,
                            controls: (_) => VideoControlsThemeDataInjector(
                                child: SPlatform.isDesktop
                                ? const DesktopVideoControls()
                                : const DesktopVideoControls(),
                            )
                        );
                    }
                )
            ),
        );
    }

    @override
    void dispose() {
        this._controller.dispose();
        super.dispose();
    }
}
