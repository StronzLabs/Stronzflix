import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/components/player/cast_button.dart';
import 'package:stronzflix/components/player/chat_button.dart';
import 'package:stronzflix/components/player/fullscreen_button.dart';
import 'package:stronzflix/components/player/next_button.dart';
import 'package:stronzflix/components/player/playpause_button.dart';
import 'package:stronzflix/components/player/position_indicator.dart';
import 'package:stronzflix/components/player/seek_bar.dart';
import 'package:stronzflix/components/player/settings_button.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player/volume_button.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';
import 'package:stronzflix/dialogs/notification_overlay.dart';
import 'package:stronzflix/utils/utils.dart';

class DesktopVideoControls extends StatefulWidget {
    const DesktopVideoControls({super.key});

    @override
    State<DesktopVideoControls> createState() => _DesktopVideoControlsState();
}

class _DesktopVideoControlsState extends State<DesktopVideoControls> {

    final List<StreamSubscription> _subscriptions = [];
    DateTime _lastTap = DateTime.now();
    late bool _buffering = playerController(super.context).isBuffering;
    bool _visible = true;
    bool _mount = true;
    bool _onControls = false;
    bool _menuOpened = false;
    bool _seeking = false;
    Timer? _timer;
    double _savedVolume = 0.0;

    StreamSubscription? _peerMessagesSubscription;

    late PlayerInfo _playerInfo;

    Widget _buildBuffering(BuildContext context) {
        return IgnorePointer(
            child: Padding(
                padding: isFullscreen(context)
                    ? MediaQuery.of(context).padding
                    : EdgeInsets.zero,
                child: Column(
                    children: [
                        Container(
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        Expanded(
                            child: Center(
                                child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                        begin: 0.0,
                                        end: this._buffering ? 1.0 : 0.0,
                                    ),
                                    duration: const Duration(milliseconds: 150),
                                    builder: (context, value, child) {
                                        if (value > 0.0)
                                            return Opacity(
                                                opacity: value,
                                                child: child!,
                                            );
                                        return const SizedBox.shrink();
                                    },
                                    child: const CircularProgressIndicator(),
                                ),
                            ),
                        ),
                        Container(
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        )
                    ]
                )
            )
        );
    }

    Widget _buildTopGradient(BuildContext context) {
        return Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                        0.0,
                        0.2,
                    ],
                    colors: [
                        Color(0x61000000),
                        Color(0x00000000),
                    ],
                )
            )
        );
    }

    Widget _buildBottomGradient(BuildContext context) {
        return Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                        0.5,
                        1.0,
                    ],
                    colors: [
                        Color(0x00000000),
                        Color(0x61000000),
                    ],
                )
            )
        );
    }

    Widget _buildTopBar(BuildContext context) {
        return MouseRegion(
            onHover: (_) => this._onEnterControls(),
            onExit: (_) => this._onExitControls(),
            onEnter: (_) => this._onEnterControls(),
            child: Container(
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () async {
                                if(isFullscreen(context))
                                    await exitFullscreen(context);
                                if(context.mounted)
                                    Navigator.of(context).pop();
                            }
                        ),
                        const SizedBox(width: 8.0),
                        Text(playerController(super.context).title,
                            style: const TextStyle(
                                fontSize: 21.0,
                            ),
                        ),
                        const Spacer(),
                        CastButton(
                            onOpened: () => this.setState(() {
                                this._timer?.cancel();
                                this._menuOpened = true;
                            }),
                            onClosed: () => this.setState(() {
                                this._menuOpened = false;
                                this._restartTimer();
                            }),
                        ),
                        const ChatButton()
                    ],
                ),
            )
        );
    }

    Widget _buildPrimaryBar(BuildContext context) {
        return Expanded(
            child: MouseRegion(
                cursor: this._visible ? SystemMouseCursors.basic : SystemMouseCursors.none,
                child: GestureDetector(
                    onTapUp: (e) {
                        DateTime now = DateTime.now();
                        Duration  difference = now.difference(this._lastTap);
                        this._lastTap = now;
                        if (difference < const Duration(milliseconds: 400))
                            toggleFullscreen(context);
                    },
                    onTap: playerController(context).playOrPause,
                    child: Container(
                        color: Colors.transparent,
                    )
                )
            )
        );
    }

    Widget _buildSeekBar(BuildContext context) {
        return MouseRegion(
            onHover: (_) => this._onEnterControls(),
            onExit: (_) => this._onExitControls(),
            onEnter: (_) => this._onEnterControls(),
            child: Transform.translate(
                offset: const Offset(0.0, 16.0),
                child: SeekBar(
                    onSeekStart: () {
                        this._timer?.cancel();
                        this.setState(() => this._seeking = true);
                    },
                    onSeekEnd: () {
                        this._restartTimer();
                        this.setState(() => this._seeking = false);
                    }
                ),
            )
        );
    }

    Widget _buildBottomBar(BuildContext context) {
        return MouseRegion(
            onHover: (_) => this._onEnterControls(),
            onExit: (_) => this._onExitControls(),
            onEnter: (_) => this._onEnterControls(),
            child: Container(
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        const PlayPauseButton(),
                        const NextButton(),
                        const VolumeButton(),
                        const PositionIndicator(),
                        const Spacer(),
                        if(!this._playerInfo.isCasting)
                            SettingsButton(
                                onOpened: () => this.setState(() {
                                    this._timer?.cancel();
                                    this._menuOpened = true;
                                }),
                                onClosed: () => this.setState(() {
                                    this._menuOpened = false;
                                    this._restartTimer();
                                }),
                            ),
                        if(!this._playerInfo.isCasting)
                            const FullscreenButton()
                    ]
                )
            ),
        );
    }

    Widget _buildControls(BuildContext context) {
        return Stack(
            children: [
                AnimatedOpacity(
                    curve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 150),
                    opacity: this._visible ? 1.0 : 0.0,
                    onEnd: () {
                        if (!this._visible)
                            this.setState(() => this._mount = false);
                    },
                    child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                            this._buildTopGradient(context),
                            this._buildBottomGradient(context),
                            Padding(
                                padding: isFullscreen(context)
                                    ? MediaQuery.of(context).padding
                                    : EdgeInsets.zero,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                        if(this._mount)
                                            this._buildTopBar(context),
                                        this._buildPrimaryBar(context),
                                        if(this._mount)
                                            ...[
                                                this._buildSeekBar(context),
                                                this._buildBottomBar(context)
                                            ]
                                    ]
                                )
                            )
                        ],
                    ),
                ),
                this._buildBuffering(context)
            ]
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
                    final rate = playerController(context).position - const Duration(seconds: 4);
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
                const SingleActivator(LogicalKeyboardKey.keyF): () => toggleFullscreen(context),
                const SingleActivator(LogicalKeyboardKey.escape): () => exitFullscreen(context),
            },
            child: Focus(
                autofocus: true,
                child: MouseRegion(
                    onHover: (_) => this._onHover(),
                    onEnter: (_) => this._onEnter(),
                    onExit: (_) => this._onExit(),
                    child: this._buildControls(context),
                )
            )
        );
    }

    @override
    void setState(VoidCallback fn) {
        if (super.mounted)
            super.setState(fn);
    }

    @override
    void initState() {
        super.initState();
        this._peerMessagesSubscription = PeerMessenger.messages.listen(this._handlePeerMessage);
        this._restartTimer();
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        if (this._subscriptions.isEmpty)
            this._subscriptions.addAll([
                playerController(super.context).stream.buffering.listen(
                    (event) => this.setState(() => this._buffering = event)
                ),
                playerController(super.context).stream.position.listen(
                    (event) => FullScreenProvider.of<PlayerInfo>(super.context, listen: false).updateTimes(
                        playerController(context).duration.inSeconds, event.inSeconds
                    )
                )
            ]);

        this._playerInfo = FullScreenProvider.of<PlayerInfo>(super.context);
    }

    @override
    void dispose() {
        for (StreamSubscription subscription in this._subscriptions)
            subscription.cancel();
        this._peerMessagesSubscription?.cancel();
        super.dispose();
    }

    void _onHover() {
        this.setState(() {
            this._mount = true;
            this._visible = true;
        });
        if(!this._onControls)
            this._restartTimer();
    }

    void _onEnterControls() {
        this.setState(() {
            this._mount = true;
            this._visible = true;
            this._onControls = true;
        });
        this._timer?.cancel();
    }

    void _onExitControls() {
        this._onControls = false;
    }

    void _onEnter() {
        this.setState(() {
            this._mount = true;
            this._visible = true;
        });
        this._restartTimer();
    }

    void _onExit() {
        if(this._menuOpened || this._seeking)
            return;
        this.setState(() {
            this._mount = false;
            this._visible = false;
        });
        this._timer?.cancel();
    }

    void _restartTimer() {
        this._timer?.cancel();
        this._timer = Timer(const Duration(seconds: 2), () =>
            this.setState(() => this._visible = false)
        );
    }

    void _handlePeerMessage(Message message) {
        if (message.type == MessageType.play)
            playerController(super.context).play(sink: true);
        else if (message.type == MessageType.pause)
            playerController(super.context).pause(sink: true);
        else if (message.type == MessageType.seek)
            playerController(super.context).seekTo(Duration(seconds: int.parse(message.data!)), sink: true);
        else if(message.type == MessageType.chat)
            NotificationOverlay.show(super.context, message.data!);
    }
}
