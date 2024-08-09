import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/methods/fullscreen.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';
import 'package:stronzflix/dialogs/notification_overlay.dart';
import 'package:stronzflix/utils/utils.dart';

abstract class StronzflixVideoControlsState<T extends StatefulWidget> extends State<T> {
    final List<StreamSubscription> _subscriptions = [];
    late bool _buffering = playerController(super.context).isBuffering;
    bool visible = true;
    bool mount = true;
    bool menuOpened = false;
    Timer? _timer;

    StreamSubscription? _peerMessagesSubscription;

    late PlayerInfo playerInfo;

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

    Widget buildTopBar(BuildContext context);
    Widget buildPrimaryBar(BuildContext context);
    Widget buildBottomBar(BuildContext context);
    Widget buildSeekBar(BuildContext context);

    Widget buildControls(BuildContext context) {
        return Stack(
            children: [
                AnimatedOpacity(
                    curve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 150),
                    opacity: this.visible ? 1.0 : 0.0,
                    onEnd: () {
                        if (!this.visible)
                            this.setState(() => this.mount = false);
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
                                        if(this.mount)
                                            this.buildTopBar(context),
                                        Expanded(
                                            child: this.buildPrimaryBar(context)
                                        ),
                                        if(this.mount)
                                            ...[
                                                this.buildSeekBar(context),
                                                this.buildBottomBar(context)
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
    void setState(VoidCallback fn) {
        if (super.mounted)
            super.setState(fn);
    }

    @override
    void initState() {
        super.initState();
        this._peerMessagesSubscription = PeerMessenger.messages.listen(this._handlePeerMessage);
        this.restartTimer();
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

        this.playerInfo = FullScreenProvider.of<PlayerInfo>(super.context);
    }

    @override
    void dispose() {
        for (StreamSubscription subscription in this._subscriptions)
            subscription.cancel();
        this._peerMessagesSubscription?.cancel();
        super.dispose();
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

    void cancelTimer() {
        this._timer?.cancel();
    }

    void restartTimer() {
        this.cancelTimer();
        this._timer = Timer(const Duration(seconds: 2), () =>
            this.setState(() => this.visible = false)
        );
    }

    void onMenuOpened() {
        this.setState(() {
        this.cancelTimer();
            this.menuOpened = true;
        });
    }

    void onMenuClosed() {
        this.setState(() {
            this.menuOpened = false;
            this.restartTimer();
        });
    }
}