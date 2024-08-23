import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/components/player/cast_button.dart';
import 'package:stronzflix/components/player/chat_button.dart';
import 'package:stronzflix/components/player/exit_button.dart';
import 'package:stronzflix/components/player/fullscreen_button.dart';
import 'package:stronzflix/components/player/media_title.dart';
import 'package:stronzflix/components/player/next_button.dart';
import 'package:stronzflix/components/player/playpause_button.dart';
import 'package:stronzflix/components/player/position_indicator.dart';
import 'package:stronzflix/components/player/seek_bar.dart';
import 'package:stronzflix/components/player/settings_button.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player/stronzflix_video_controls.dart';
import 'package:stronzflix/components/player/volume_button.dart';
import 'package:stronzflix/utils/platform.dart';

class DesktopVideoControls extends StatefulWidget {
    const DesktopVideoControls({super.key});

    @override
    State<DesktopVideoControls> createState() => _DesktopVideoControlsState();
}

class _DesktopVideoControlsState extends StronzflixVideoControlsState<DesktopVideoControls> {

    DateTime _lastTap = DateTime.now();
    bool _hoveringControls = false;
    double _savedVolume = 0.0;
    bool _seeking = false;

    @override
    Widget buildTopBar(BuildContext context) {
        return MouseRegion(
            onHover: (_) => this._onEnterControls(),
            onExit: (_) => this._onExitControls(),
            onEnter: (_) => this._onEnterControls(),
            child: Container(
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
                        ),
                        const SizedBox(width: 8.0),
                        const ChatButton(),
                    ],
                )
            )
        );
    }

    @override
    Widget buildPrimaryBar(BuildContext context) {
        return MouseRegion(
            cursor: super.visible ? SystemMouseCursors.basic : SystemMouseCursors.none,
            child: GestureDetector(
                onTapUp: (e) {
                    DateTime now = DateTime.now();
                    Duration  difference = now.difference(this._lastTap);
                    this._lastTap = now;
                    if (difference < const Duration(milliseconds: 400))
                        SPlatform.toggleFullScreen();
                },
                onTap: playerController(context).playOrPause,
                child: Container(
                    color: Colors.transparent,
                )
            )
        );
    }

    @override
    Widget buildBottomBar(BuildContext context) {
        return MouseRegion(
            onHover: (_) => this._onEnterControls(),
            onExit: (_) => this._onExitControls(),
            onEnter: (_) => this._onEnterControls(),
            child: Container(
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
                            ),
                        if(!super.playerInfo.isCasting)
                            const FullscreenButton()
                    ]
                )
            )
        );
    }

    @override
    Widget buildSeekBar(BuildContext context) {
        return MouseRegion(
            onHover: (_) => this._onEnterControls(),
            onExit: (_) => this._onExitControls(),
            onEnter: (_) => this._onEnterControls(),
            child: Transform.translate(
                offset: const Offset(0.0, 16.0),
                child: SeekBar(
                    onSeekStart: () {
                        super.cancelTimer();
                        super.setState(() => this._seeking = true);
                    },
                    onSeekEnd: () {
                        super.restartTimer();
                        super.setState(() => this._seeking = false);
                    }
                ),
            )
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
                const SingleActivator(LogicalKeyboardKey.space): () =>
                    playerController(context).playOrPause(),
                const SingleActivator(LogicalKeyboardKey.keyJ): () {
                    final rate = playerController(context).position - const Duration(seconds: 10);
                    playerController(context).seekTo(rate);
                },
                const SingleActivator(LogicalKeyboardKey.keyI): () {
                    final rate = playerController(context).position + const Duration(seconds: 10);
                    playerController(context).seekTo(rate);
                },
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                    final rate = playerController(context).position - const Duration(seconds: 5);
                    playerController(context).seekTo(rate);
                },
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                    final rate = playerController(context).position + const Duration(seconds: 5);
                    playerController(context).seekTo(rate);
                },
                const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                    final volume = playerController(context).volume + 5.0;
                    playerController(context).setVolume(volume.clamp(0.0, 100.0));
                },
                const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                    final volume = playerController(context).volume - 5.0;
                    playerController(context).setVolume(volume.clamp(0.0, 100.0));
                },
                const SingleActivator(LogicalKeyboardKey.keyM): () {
                    if(playerController(context).volume > 0.0) {
                        this._savedVolume = playerController(context).volume;
                        playerController(context).setVolume(0.0);
                    } else
                        playerController(context).setVolume(this._savedVolume);
                },
                const SingleActivator(LogicalKeyboardKey.keyF): () => SPlatform.toggleFullScreen(),
                const SingleActivator(LogicalKeyboardKey.escape): () => SPlatform.setFullScreen(false),
            },
            child: Focus(
                autofocus: true,
                child: MouseRegion(
                    onHover: (_) => this._onHover(),
                    onEnter: (_) => this._onEnter(),
                    onExit: (_) => this._onExit(),
                    child: super.buildControls(context),
                )
            )
        );
    }

    void _onHover() {
        super.setState(() {
            super.mount = true;
            super.visible = true;
        });
        if(!this._hoveringControls)
            super.restartTimer();
    }

    void _onEnter() {
        super.setState(() {
            super.mount = true;
            super.visible = true;
        });
        super.restartTimer();
    }

    void _onExit() {
        if(super.menuOpened || this._seeking)
            return;
        super.setState(() {
            super.mount = false;
            super.visible = false;
        });
        super.cancelTimer();
    }

    void _onEnterControls() {
        super.setState(() {
            super.mount = true;
            super.visible = true;
            this._hoveringControls = true;
        });
        super.cancelTimer();
    }

    void _onExitControls() {
        this._hoveringControls = false;
    }
}
