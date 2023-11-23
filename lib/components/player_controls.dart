import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/components/center_play_button.dart';
import 'package:stronzflix/utils/format.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:chewie/src/animated_play_pause.dart';

class PlayerControls extends StatefulWidget {
  
    const PlayerControls({super.key});

    @override
    State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {

    ChewieController? _chewieController;
    ChewieController get chewieController => _chewieController!;
    late VideoPlayerController controller;
    late VideoPlayerValue _latestValue;

    final double _barHeight = 48.0 * 1.5;
    Timer? _hideTimer;
    bool _hideStuff = true;
    bool _buffering = false;
    bool _dragging = false;
    double? _latestVolume;

    @override
    Widget build(BuildContext context) {
        if (this._latestValue.hasError)
            return this._buildError(context);

        return MouseRegion(
            onHover: (_) => this._cancelAndRestartTimer(),
                child: Stack(
                children: [
                    if (this._buffering)
                        this._buildBuffering(context)
                    else
                        this._buildHitArea(context),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: this._buildBottomBar(context),
                    )
                ],
            ),
        );
    }

    @override
    void didChangeDependencies() {
        final ChewieController? oldController = this._chewieController;
        this._chewieController = ChewieController.of(context);
        this.controller = this.chewieController.videoPlayerController;

        if (oldController != this.chewieController) {
            this._dispose();
            this._initialize();
        }

        super.didChangeDependencies();
    }

    @override
    void dispose() {
        this._dispose();
        super.dispose();
    }

    Widget _buildError(BuildContext context) {
        return const Center(
            child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
            ),
        );
    }

    Widget _buildBuffering(BuildContext context) {
        return Expanded(
            child: Container(
                color: Colors.black54,
                child: const Center(
                    child: CircularProgressIndicator(),
                )
            )
        );
    }

    Widget _buildHitArea(BuildContext context) {
        final bool isFinished = this._latestValue.position >= this._latestValue.duration;
        final bool showPlayButton = !this._hideStuff && !this._dragging;

        return GestureDetector(
            onTap: this._playPause,
            child: CenterPlayButton(
                backgroundColor: Colors.black54,
                iconColor: Colors.white,
                isFinished: isFinished,
                isPlaying: controller.value.isPlaying,
                show: showPlayButton,
                onPressed: this._playPause,
            ),
        );
    }

    Widget _buildPosition(BuildContext context) {
        final position = _latestValue.position;
        final duration = _latestValue.duration;

        return Text(
            '${formatDuration(position)} / ${formatDuration(duration)}',
            style: const TextStyle(
                fontSize: 14.0,
                color: Colors.white,
            ),
        );
    }

    Widget _buildPlayPause(BuildContext context) {
        return GestureDetector(
        onTap: this._playPause,
            child: Container(
                height: this._barHeight,
                color: Colors.transparent,
                margin: const EdgeInsets.only(left: 8.0, right: 4.0),
                padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                ),
                child: AnimatedPlayPause(
                    playing: this.controller.value.isPlaying
                ),
            ),
        );
    }

    Widget _buildMuteButton(BuildContext context) {
        return GestureDetector(
            onTap: () {
                this._cancelAndRestartTimer();

                if (this._latestValue.volume == 0)
                    this.controller.setVolume(this._latestVolume ?? 0.5);
                else {
                    this._latestVolume = this.controller.value.volume;
                    this.controller.setVolume(0.0);
                }
            },
            child: AnimatedOpacity(
                opacity: this._hideStuff ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: ClipRect(
                    child: Container(
                        height: this._barHeight,
                            padding: const EdgeInsets.only(
                                right: 15.0,
                            ),
                            child: Icon(
                                this._latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off
                            ),
                        ),
                    ),
                ),
            );
    }

    void _onExpandCollapse() {
        super.setState(() {
            this._cancelAndRestartTimer();
            windowManager.setFullScreen(!this.chewieController.isFullScreen).then((_) =>
                this.chewieController.toggleFullScreen()
            );
        });
    }

    Widget _buildExpandButton(BuildContext context) {
        return GestureDetector(
            onTap: this._onExpandCollapse,
            child: AnimatedOpacity(
                opacity: this._hideStuff ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                    height: this._barHeight + (chewieController.isFullScreen ? 15.0 : 0),
                    margin: const EdgeInsets.only(right: 12.0),
                    padding: const EdgeInsets.only(
                        left: 8.0,
                        right: 8.0,
                    ),
                    child: Center(
                        child: Icon(
                            chewieController.isFullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen
                        ),
                    ),
                ),
            ),
        );
    }

    Widget _buildProgressBar(BuildContext context) {
        return Expanded(
            child: MaterialVideoProgressBar(
                controller,
                onDragStart: () {
                    super.setState(() {
                        this._dragging = true;
                    });

                    this._hideTimer?.cancel();
                },
                onDragUpdate: () {
                    this._hideTimer?.cancel();
                },
                onDragEnd: () {
                    super.setState(() {
                        this._dragging = false;
                    });

                    this._startHideTimer();
                },
                colors: chewieController.materialProgressColors ??
                    ChewieProgressColors(
                        playedColor: Theme.of(context).colorScheme.secondary,
                        handleColor: Theme.of(context).colorScheme.secondary,
                        bufferedColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
                        backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
                    ),
            ),
        );
    }

    Widget _buildBottomBar(BuildContext context) {
        return AnimatedOpacity(
            opacity: this._hideStuff ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
                height: this._barHeight + (chewieController.isFullScreen ? 20.0 : 0),
                padding: EdgeInsets.only(bottom: chewieController.isFullScreen ? 10.0 : 15),
                child: SafeArea(
                    bottom: this.chewieController.isFullScreen,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        verticalDirection: VerticalDirection.up,
                        children: [
                            Flexible(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        this._buildPlayPause(context),
                                        this._buildMuteButton(context),
                                        if (this.chewieController.isLive)
                                            const Expanded(child: Text('LIVE'))
                                        else
                                            this._buildPosition(context),
                                        const Spacer(),
                                        this._buildExpandButton(context)
                                    ]
                                )
                            ),
                            if (!this.chewieController.isLive)
                                Expanded(
                                    child: Container(
                                        padding: EdgeInsets.only(
                                            right: 20,
                                            left: 20,
                                            bottom: this.chewieController.isFullScreen ? 5.0 : 0,
                                        ),
                                        child: Row(
                                            children: [
                                                this._buildProgressBar(context),
                                            ],
                                        ),
                                    ),
                                )
                        ],
                    ),
                )
            )
        );
    }

    void _dispose() {
        this.controller.removeListener(this._updateState);
        this._hideTimer?.cancel();
    }

    Future<void> _initialize() async {
        this.controller.addListener(this._updateState);
        this._updateState();
    }

    void _playPause() {
        final bool isFinished = this._latestValue.position >= this._latestValue.duration;

        super.setState(() {

            if (this.controller.value.isPlaying) {
                this._hideTimer?.cancel();
                this.controller.pause();
                this._hideStuff = false;
            } else {
                this._hideStuff = true;

                if (!this.controller.value.isInitialized)
                    this.controller.initialize().then((_) => controller.play());
                else if (isFinished)
                    this.controller.seekTo(Duration.zero);
                
                this.controller.play();
            }
        });
    }

    void _cancelAndRestartTimer() {
        this._hideTimer?.cancel();
        this._startHideTimer();

        super.setState(() {
            this._hideStuff = false;
        });
    }

    void _startHideTimer() {
        final Duration  hideControlsTimer = chewieController.hideControlsTimer.isNegative
            ? ChewieController.defaultHideControlsTimer
            : chewieController.hideControlsTimer;
        this._hideTimer = Timer(hideControlsTimer, () => super.setState(() => this._hideStuff = true));
    }

    void _updateState() {
        this._buffering = controller.value.isBuffering;

        super.setState(() => this._latestValue = this.controller.value);
    }
}
