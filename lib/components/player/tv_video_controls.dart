import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/components/player/media_title.dart';
import 'package:stronzflix/components/player/next_button.dart';
import 'package:stronzflix/components/player/playpause_button.dart';
import 'package:stronzflix/components/player/position_indicator.dart';
import 'package:stronzflix/components/player/seek_bar.dart';
import 'package:stronzflix/components/player/settings_button.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player/stronzflix_video_controls.dart';

class TVVideoControls extends StatefulWidget {
    const TVVideoControls({super.key});

    @override
    State<TVVideoControls> createState() => _TVVideoControlsState();
}

class _TVVideoControlsState extends StronzflixVideoControlsState<TVVideoControls> {

    final FocusNode _focusNode = FocusNode();
    final FocusNode _seekBarNode = FocusNode();

    @override
    Widget buildTopBar(BuildContext context) {
        return Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Row(
                children: [
                    MediaTitle()
                ],
            ),
        );
    }

    @override
    Widget buildPrimaryBar(BuildContext context) {
        return const SizedBox.shrink();
    }

    @override
    Widget buildBottomBar(BuildContext context) {
        return Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
                children: [
                    PlayPauseButton(
                        onFocus: super.cancelTimer,
                        onFocusLost: super.restartTimer,
                    ),
                    NextButton(
                        onFocus: super.cancelTimer,
                        onFocusLost: super.restartTimer,
                    ),
                    const PositionIndicator(),
                    const Spacer(),
                    if(!super.playerInfo.isCasting)
                        SettingsButton(
                            onFocus: super.cancelTimer,
                            onFocusLost: super.restartTimer,
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
            child: KeyboardListener(
                focusNode: this._seekBarNode,
                child: const SeekBar(),
                onKeyEvent: (key) {
                    if (key is KeyDownEvent && key.logicalKey == LogicalKeyboardKey.select)
                        playerController(context).playOrPause();
                    if (key is KeyDownEvent && key.logicalKey == LogicalKeyboardKey.arrowRight) {
                        final rate = playerController(context).position + const Duration(seconds: 5);
                        playerController(context).seekTo(rate);
                        super.restartTimer();
                    }
                    if (key is KeyDownEvent && key.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        final rate = playerController(context).position - const Duration(seconds: 5);
                        playerController(context).seekTo(rate);
                        super.restartTimer();
                    }
                },
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return PopScope(
            canPop: !super.visible,
            onPopInvoked: (canPop) {
                if (super.visible)
                    super.setState(() {
                        super.mount = false;
                        super.visible = false;
                    });
            },
            child: CallbackShortcuts(
                bindings: {
                    const SingleActivator(LogicalKeyboardKey.mediaPlay): () =>
                        playerController(context).play(),
                    const SingleActivator(LogicalKeyboardKey.mediaPause): () =>
                        playerController(context).pause(),
                    const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () =>
                        playerController(context).playOrPause(),
                },
                child: KeyboardListener(
                    autofocus: true,
                    focusNode: this._focusNode,
                    child: super.buildControls(context),
                    onKeyEvent: (key) {
                        if (key is KeyDownEvent && key.logicalKey == LogicalKeyboardKey.select)
                            this._onFocus();
                    },
                )
            )
        );
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        this._focusNode.requestFocus();
    }

    @override
    void dispose() {
        super.dispose();
        this._focusNode.dispose();
    }

    void _onFocus() {
        super.restartTimer();
        super.setState(() {
            super.mount = true;
            super.visible = true;
        });
        this._seekBarNode.requestFocus();
    }
}
