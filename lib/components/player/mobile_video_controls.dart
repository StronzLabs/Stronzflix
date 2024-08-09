import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/components/player/cast_button.dart';
import 'package:stronzflix/components/player/exit_button.dart';
import 'package:stronzflix/components/player/media_title.dart';
import 'package:stronzflix/components/player/next_button.dart';
import 'package:stronzflix/components/player/playpause_button.dart';
import 'package:stronzflix/components/player/position_indicator.dart';
import 'package:stronzflix/components/player/seek_bar.dart';
import 'package:stronzflix/components/player/settings_button.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player/stronzflix_video_controls.dart';
import 'package:stronzflix/components/player/volume_button.dart';

class MobileVideoControls extends StatefulWidget {
    const MobileVideoControls({super.key});

    @override
    State<MobileVideoControls> createState() => _MobileVideoControlsState();
}

class _MobileVideoControlsState extends StronzflixVideoControlsState<MobileVideoControls> {

    @override
    Widget buildTopBar(BuildContext context) {
        return Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
                children: [
                    const ExitButton(),
                    const SizedBox(width: 8.0),
                    const MediaTitle(),
                    const SizedBox(width: 8.0),
                    CastButton(
                        onOpened: super.onMenuOpened,
                        onClosed: super.onMenuClosed,
                    )
                ],
            ),
        );
    }

    @override
    Widget buildPrimaryBar(BuildContext context) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                // TODO: double tap the screen to seek 10 seconds back
                if(super.mount)
                    const PlayPauseButton(
                        iconSize: 50,
                    ),
                // TODO: double tap the screen to seek 10 seconds forward
            ]
        );
    }

    @override
    Widget buildBottomBar(BuildContext context) {
        return Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
                children: [
                    const PlayPauseButton(),
                    const NextButton(),
                    const VolumeButton(),
                    const PositionIndicator(),
                    const Spacer(),
                    if(!super.playerInfo.isCasting)
                        SettingsButton(
                            onOpened: super.onMenuOpened,
                            onClosed: super.onMenuClosed,
                        )
                ]
            )
        );
    }

    @override
    Widget buildSeekBar(BuildContext context) {
        return Transform.translate(
            offset: const Offset(0.0, 16.0),
            child: SeekBar(
                onSeekStart: super.cancelTimer,
                onSeekEnd: super.restartTimer
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return CallbackShortcuts(
            bindings: {
                const SingleActivator(LogicalKeyboardKey.mediaPlay): () =>
                    playerController(context).play(),
                const SingleActivator(LogicalKeyboardKey.mediaPause): () =>
                    playerController(context).pause(),
                const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () =>
                    playerController(context).playOrPause(),
            },
            child: Focus(
                autofocus: true,
                child: GestureDetector(
                    onTap: this._onTap,
                    child: super.buildControls(context),
                )
            )
        );
    }

    @override
    void initState() {
        super.initState();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
        ]);
    }

    @override
    void dispose() {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp
        ]);
        super.dispose();
    }

    void _onTap() {
        if (super.visible) {
            super.cancelTimer();
            super.setState(() => super.visible = false);
        } else {
            super.restartTimer();
            super.setState(() {
                super.mount = true;
                super.visible = true;
            });
        }
    }
}
