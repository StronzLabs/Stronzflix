import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/components/player/cast_button.dart';
import 'package:stronzflix/components/player/chat_button.dart';
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

class MobileVideoControls extends StatefulWidget {
    const MobileVideoControls({super.key});

    @override
    State<MobileVideoControls> createState() => _MobileVideoControlsState();
}

class _MobileVideoControlsState extends State<MobileVideoControls> {

    final List<StreamSubscription> _subscriptions = [];
    late bool _buffering = playerController(super.context).isBuffering;
    bool _visible = true;
    bool _mount = true;
    Timer? _timer;

    StreamSubscription? _peerMessagesSubscription;

    late PlayerInfo _playerInfo;

    Widget _buildBuffering(BuildContext context) {
        return IgnorePointer(
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
        return Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop()
                    ),
                    const SizedBox(width: 8.0),
                    Text(playerController(super.context).title,
                        style: const TextStyle(
                            fontSize: 21.0,
                        ),
                    ),
                    const Spacer(),
                    CastButton(
                        onOpened: this._timer?.cancel,
                        onClosed: this._restartTimer,
                    ),
                    const ChatButton()
                ],
            ),
        );
    }

    Widget _buildPrimaryBar(BuildContext context) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                // TODO: double tap the screen to seek 10 seconds back
                if(this._mount)
                    const PlayPauseButton(
                        iconSize: 50,
                    ),
                // TODO: double tap the screen to seek 10 seconds forward
            ]
        );
    }

    Widget _buildSeekBar(BuildContext context) {
        return Transform.translate(
            offset: const Offset(0.0, 16.0),
            child: SeekBar(
                onSeekStart: this._timer?.cancel,
                onSeekEnd: this._restartTimer
            ),
        );
    }

    Widget _buildBottomBar(BuildContext context) {
        return Container(
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
                            onOpened: this._timer?.cancel,
                            onClosed: this._restartTimer
                        ),
                ]
            )
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
                            Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                    if(this._mount)
                                        this._buildTopBar(context),
                                    Expanded(
                                        child: this._buffering
                                            ? const SizedBox.shrink()
                                            : this._buildPrimaryBar(context)
                                    ),
                                    if(this._mount)
                                        ...[
                                            this._buildSeekBar(context),
                                            this._buildBottomBar(context)
                                        ]
                                ]
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
            },
            child: Focus(
                autofocus: true,
                child: GestureDetector(
                    onTap: this._onTap,
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
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
        ]);
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
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp
        ]);
        super.dispose();
    }

    void _onTap() {
        if (this._visible) {
            this._timer?.cancel();
            this.setState(() => this._visible = false);
        } else {
            this._restartTimer();
            this.setState(() {
                this._mount = true;
                this._visible = true;
            });
        }

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
