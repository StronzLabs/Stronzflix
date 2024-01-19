import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/components/progress_bar.dart';
import 'package:stronzflix/utils/format.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:stronzflix/views/media.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';
// ignore: implementation_imports
import 'package:chewie/src/animated_play_pause.dart';

class PlayerControls extends StatefulWidget {
  
    final Watchable media;

    const PlayerControls({super.key, required this.media});

    @override
    State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {

    ChewieController? _chewieController;
    ChewieController get chewieController => _chewieController!;
    late VideoPlayerController controller;
    late VideoPlayerValue _latestValue;

    Timer? _hideTimer;
    bool _hideStuff = true;
    bool _buffering = false;
    late bool _fullscreen;
    double? _latestVolume;

    late Watchable _currentMedia;
    Watchable? _nextMedia;

    KeyEventResult _handleKeyControls(RawKeyEvent event) {
        if(event is! RawKeyDownEvent)
            return KeyEventResult.ignored;

        if(event.logicalKey == LogicalKeyboardKey.arrowUp) {
            this._cancelAndRestartTimer();
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.arrowDown) {
            super.setState(() => this._hideStuff = true);
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.space) {
            this._playPause();
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            this._cancelAndRestartTimer();
            final position = this._latestValue.position;
            final seekTo = position - const Duration(seconds: 10);
            this.controller.seekTo(seekTo > Duration.zero ? seekTo : Duration.zero);
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.arrowRight) {
            this._cancelAndRestartTimer();
            final position = this._latestValue.position;
            final seekTo = position + const Duration(seconds: 10);
            this.controller.seekTo(seekTo < this._latestValue.duration ? seekTo : this._latestValue.duration);
            return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
    }

    @override
    Widget build(BuildContext context) {
        if (this._latestValue.hasError)
            return this._buildError(context);

        return FocusScope(
            autofocus: true,
            child: Focus(
                autofocus: true,
                canRequestFocus: true,
                onKey: (data, event) => this._handleKeyControls(event),
                child: MouseRegion(
                    onHover: (_) => this._cancelAndRestartTimer(),
                    child: Stack(
                        children: [
                            if (this._buffering)
                                this._buildBuffering(context)
                            else
                                this._buildHitArea(context),
                            Align(
                                alignment: Alignment.topCenter,
                                child: this._buildTitleBar(context),
                            ),
                            Align(
                                alignment: Alignment.bottomCenter,
                                child: this._buildBottomBar(context),
                            )
                        ],
                    ),
                )
            )
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
                size: 42,
            ),
        );
    }

    Widget _buildBuffering(BuildContext context) {
        return const ColoredBox(
            color: Colors.black54,
            child: Center(
                child: CircularProgressIndicator(),
            )
        );
    }

    Widget _buildTitle(BuildContext context) {
        late String title;
        if (super.widget.media is Film) {
            title = (super.widget.media as Film).name;
        }
        else if (super.widget.media is Episode){
            Episode ep = super.widget.media as Episode;
            title = "${ep.series.name} - ${ep.name}";
        } else {
            title = super.widget.media.name;
        }
        return Text(title);
    }

    Widget _buildTitleBar(BuildContext context) {
        return AnimatedOpacity(
            opacity: this._hideStuff ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 10),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    verticalDirection: VerticalDirection.up,
                    children: [
                        Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                                children: [
                                    IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () {
                                            if(this._fullscreen)
                                                this._onExpandCollapse();
                                            Navigator.of(context).maybePop();
                                        }
                                    ),
                                    this._buildTitle(context)
                                ]
                            )
                        ),
                    ],
                ),
            )
        );
    }

    Widget _buildHitArea(BuildContext context) {
        return GestureDetector(
            onTap: () { if(SPlatform.isDesktop) this._playPause(); },
            child: AnimatedOpacity(
                opacity: !this._hideStuff ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300), 
                child: ColoredBox(
                    color: Colors.black26,
                    child: Container()
                )
            )
        );
    }

    Widget _buildPosition(BuildContext context) {
        final position = _latestValue.position;
        final duration = _latestValue.duration;

        return Text(
            '${formatDuration(position)} / ${formatDuration(duration)}',
            style: const TextStyle(
                fontSize: 14.0
            ),
        );
    }

    Widget _buildPlayPause(BuildContext context) {
        return IconButton(
            onPressed: this._playPause,
            icon: AnimatedPlayPause(
                playing: this.controller.value.isPlaying
            )
        );
    }

    Widget _buildMuteButton(BuildContext context) {
        return IconButton(
            onPressed: () {
                this._cancelAndRestartTimer();

                if (this._latestValue.volume == 0)
                    this.controller.setVolume(this._latestVolume ?? 0.5);
                else {
                    this._latestVolume = this.controller.value.volume;
                    this.controller.setVolume(0.0);
                }
            },
            icon: AnimatedOpacity(
                opacity: this._hideStuff ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                    this._latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off
                ),
            )
        );
    }

    Widget _buildExpandButton(BuildContext context) {
        return IconButton(
            onPressed: this._onExpandCollapse,
            icon: AnimatedOpacity(
                opacity: this._hideStuff ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                    this._fullscreen ? Icons.fullscreen_exit : Icons.fullscreen
                ),
            ),
        );
    }

    Widget _buildProgressBar(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(right: 20, left: 20),
                child: MaterialVideoProgressBar(
                controller,
                onDragStart: () {
                    this._hideTimer?.cancel();
                },
                onDragUpdate: () {
                    this._hideTimer?.cancel();
                    this._updateState();
                },
                onDragEnd: () {
                    this._startHideTimer();
                },
                onSeek: (position) {
                    PeerManager.seek(position.inMilliseconds);
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

    Widget _buildNextButton(BuildContext context) {
        return IconButton(
            onPressed: this._onNextMedia,
            icon: AnimatedOpacity(
                opacity: this._hideStuff ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.skip_next_sharp),
            ),
        );
    }

    Widget _buildBottomBar(BuildContext context) {
        return AnimatedOpacity(
            opacity: this._hideStuff ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 10),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    verticalDirection: VerticalDirection.up,
                    children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Row(
                                children: [
                                    this._buildPlayPause(context),
                                    const SizedBox(width: 12),
                                    this._buildMuteButton(context),
                                    const SizedBox(width: 12),
                                    if (this.chewieController.isLive)
                                        const Text('LIVE')
                                    else
                                        this._buildPosition(context),
                                    const Spacer(),
                                    if (this._nextMedia != null)
                                        this._buildNextButton(context),
                                    if (SPlatform.isDesktop)
                                        this._buildExpandButton(context)
                                ]
                            )
                        ),
                        if (!this.chewieController.isLive)
                            SizedBox(
                                height: 24,
                                child: this._buildProgressBar(context),
                            )
                    ],
                ),
            )
        );
    }

    void _onNextMedia() {
        this._dispose();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => MediaPage(playable: this._nextMedia!),
        ));
    }

    void _onExpandCollapse() {
        this._fullscreen = !this._fullscreen;
        this._cancelAndRestartTimer();
        super.setState(() {
            if(SPlatform.isDesktop)
                windowManager.setFullScreen(this._fullscreen);
        });
    }

    void _dispose() {
        this.controller.removeListener(this._updateState);
        this._hideTimer?.cancel();
    }

    Future<void> _initialize() async {
        this.controller.addListener(this._updateState);
        this._updateState();
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        this.chewieController.notifyListeners();
        this._fullscreen = this.chewieController.isFullScreen;
        this._currentMedia = super.widget.media;
        this._findNextMedia();

        PeerManager.registerHandler(PeerMessageIntent.seek,
            (at) => this.controller.seekTo(Duration(milliseconds: at["time"]))
        );

        PeerManager.registerHandler(PeerMessageIntent.pause,
            (_) {
                if(this.controller.value.isPlaying)
                    this._playPause(peer: false);
            }
        );

        PeerManager.registerHandler(PeerMessageIntent.play,
            (_) {
                if(!this.controller.value.isPlaying)
                    this._playPause(peer: false);
            }
        );
    }

    void _findNextMedia() {
        if(this._currentMedia is! Episode)
            return;

        Series series = (this._currentMedia as Episode).series;

        late int seasonIdx, episodeIdx;
        for (List<Episode> season in series.seasons) {
            for (Episode episode in season) {
                if (episode.playerUrl == (this._currentMedia as Episode).playerUrl) {
                    episodeIdx = season.indexOf(episode);
                    seasonIdx = series.seasons.indexOf(season);
                    break;
                }
            }
        }
        Episode? nextEpisode;
        if (episodeIdx < series.seasons[seasonIdx].length - 1) {
            nextEpisode = series.seasons[seasonIdx][episodeIdx + 1];
        }
        else if (seasonIdx < series.seasons.length - 1) {
            nextEpisode = series.seasons[seasonIdx + 1][0];
        }

        this._nextMedia = nextEpisode;
    }

    void _playPause({bool peer = true}) {
        final bool isFinished = this._latestValue.position >= this._latestValue.duration;

        super.setState(() {

            if (this.controller.value.isPlaying) {
                this._hideTimer?.cancel();
                this.controller.pause();
                this._hideStuff = false;

                if (peer)
                    PeerManager.pause();
            } else {
                this._hideStuff = true;

                if (!this.controller.value.isInitialized)
                    this.controller.initialize().then((_) => controller.play());
                else if (isFinished)
                    this.controller.seekTo(Duration.zero);
                
                this.controller.play();

                if (peer)
                    PeerManager.play();
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

