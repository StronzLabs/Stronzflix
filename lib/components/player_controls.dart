import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/components/animated_play_pause.dart';
import 'package:stronzflix/components/chat_drawer.dart';
import 'package:stronzflix/components/control_widget.dart';
import 'package:stronzflix/components/progress_bar.dart';
import 'package:stronzflix/utils/format.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:stronzflix/pages/media_page.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

class PlayerControls extends StatefulWidget {
  
    final VideoPlayerController controller;
    final Watchable media;

    const PlayerControls({super.key, required this.media, required this.controller});

    @override
    State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {

    late VideoPlayerController _controller;

    Timer? _hideTimer;
    bool _hidden = true;
    bool _buffering = false;
    bool _fullscreen = false;
    bool _chatOpened = false;

    late Watchable _currentMedia;
    Watchable? _nextMedia;
    late FocusScopeNode _focusNode;

    @override
    void initState() {
        super.initState();
        this._initialize();
    }

    @override
    void dispose() {
        this._dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        if (this._controller.value.hasError)
            return this._buildError(context);

        return FocusScope(
            node: this._focusNode,
            autofocus: true,
            canRequestFocus: true,
            onKey: (data, event) => this._handleKeyControls(event),
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
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: this._buildChatDrawer(context),
                    )
                ]
            )
        );
    }

    Widget _buildChatDrawer(BuildContext context) {
        return ChatDrawer(
            shown: this._chatOpened,
        );
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
        else if (super.widget.media is Episode) {
            Episode ep = super.widget.media as Episode;
            title = "${ep.series.name} - ${ep.name}";
        } else
            throw Exception("Unknown media type");
        return Text(title);
    }

    Widget _buildTitleBar(BuildContext context) {
        return ControlWidget(
            hidden: this._hidden,
            child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                    children: [
                        IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                                if(this._fullscreen)
                                    this._onExpandCollapse();
                                Backend.stopWatching();
                                Navigator.of(context).pop();
                            }
                        ),
                        this._buildTitle(context),
                        const Spacer(),
                        if (PeerManager.connected)
                            IconButton(
                                icon: const Icon(Icons.chat),
                                onPressed: () => super.setState(() =>
                                    this._chatOpened = !this._chatOpened
                                )
                            )
                    ]
                )
            )
        );
    }

    Widget _buildHitArea(BuildContext context) {
        return ControlWidget(
            hidden: this._hidden,
            ignorePointer: false,
            child: ColoredBox(
                color: Colors.black26,
                child: Container()
            ),
            onHover: (_) => this._cancelAndRestartTimer(),
            onTap: () {
                if(SPlatform.isDesktop)
                this._playPause(); 
            }
        );
    }

    Widget _buildPosition(BuildContext context) {
        Duration position = this._controller.value.position;
        Duration duration = this._controller.value.duration;

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
                playing: this._controller.value.isPlaying
            )
        );
    }

    Widget _buildMuteButton(BuildContext context) {
        return IconButton(
            onPressed: () {
                this._cancelAndRestartTimer();

                if (this._controller.value.volume == 0)
                    this._controller.setVolume(1.0);
                else
                    this._controller.setVolume(0.0);
            },
            icon: Icon(
                this._controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off
            )
        );
    }

    Widget _buildExpandButton(BuildContext context) {
        return IconButton(
            onPressed: this._onExpandCollapse,
            icon: Icon(this._fullscreen ? Icons.fullscreen_exit : Icons.fullscreen)
        );
    }

    Widget _buildProgressBar(BuildContext context) {
        return MaterialVideoProgressBar(
            _controller,
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
            colors: ChewieProgressColors(
                playedColor: Theme.of(context).colorScheme.secondary,
                handleColor: Theme.of(context).colorScheme.secondary,
                bufferedColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
                backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
            ),
        );
    }

    Widget _buildNextButton(BuildContext context) {
        return IconButton(
            onPressed: this._onNextMedia,
            icon: const Icon(Icons.skip_next_sharp)
        );
    }

    Widget _buildBottomBar(BuildContext context) {
        return ControlWidget(
            hidden: this._hidden,
            child: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    verticalDirection: VerticalDirection.up,
                    children: [
                        Row(
                            children: [
                            this._buildPlayPause(context),
                            const SizedBox(width: 12),
                            this._buildMuteButton(context),
                            const SizedBox(width: 12),
                            this._buildPosition(context),
                            const Spacer(),
                            if (this._nextMedia != null)
                                this._buildNextButton(context),
                            if (SPlatform.isDesktop)
                                this._buildExpandButton(context)
                            ]
                        ),
                        SizedBox(
                            height: 24,
                            child: this._buildProgressBar(context),
                        )
                    ]
                )
            )
        );
    }

    void _onNextMedia() {
        Backend.watchNext((this._currentMedia as Episode).series.seasons.map((e) => e.length).toList());
        
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => MediaPage(playable: this._nextMedia!),
        ));
    }

    void _onExpandCollapse() {
        this._fullscreen = !this._fullscreen;
        this._cancelAndRestartTimer();
        windowManager.setFullScreen(this._fullscreen);
    }

    void _dispose() {
        this._controller.removeListener(this._updateState);
        this._hideTimer?.cancel();
    }

    Future<void> _initialize() async {
        this._focusNode = FocusScopeNode();
        this._controller = super.widget.controller;
        this._controller.addListener(this._updateState);
        this._updateState();
        this._currentMedia = super.widget.media;
        this._findNextMedia();

        PeerManager.registerHandler(PeerMessageIntent.seek,
            (at) => this._controller.seekTo(Duration(milliseconds: at["time"]))
        );

        PeerManager.registerHandler(PeerMessageIntent.pause,
            (_) {
                if(this._controller.value.isPlaying)
                    this._playPause(peer: false);
            }
        );

        PeerManager.registerHandler(PeerMessageIntent.play,
            (_) {
                if(!this._controller.value.isPlaying)
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
        final bool isFinished = this._controller.value.position >= this._controller.value.duration;

        super.setState(() {

            if (this._controller.value.isPlaying) {
                this._hideTimer?.cancel();
                this._controller.pause();
                this._hidden = false;

                if (peer)
                    PeerManager.pause();
            } else {
                this._hidden = true;

                if (!this._controller.value.isInitialized)
                    this._controller.initialize().then((_) => _controller.play());
                else if (isFinished)
                    this._controller.seekTo(Duration.zero);
                
                this._controller.play();

                if (peer)
                    PeerManager.play();
            }
        });
    }

    void _cancelAndRestartTimer() {
        this._hideTimer?.cancel();
        this._startHideTimer();

        super.setState(() => this._hidden = false);
    }

    void _startHideTimer() {
        const Duration hideControlsTimer = Duration(seconds: 1, milliseconds: 500);
        this._hideTimer = Timer(hideControlsTimer, () => super.setState(() => this._hidden = true));
    }

    void _updateState() {
        super.setState(() => this._buffering = this._controller.value.isBuffering);
    }

    KeyEventResult _handleKeyControls(RawKeyEvent event) {
        if(FocusManager.instance.primaryFocus != this._focusNode)
            return KeyEventResult.ignored;

        if(event is! RawKeyDownEvent)
            return KeyEventResult.ignored;

        if(event.logicalKey == LogicalKeyboardKey.arrowUp) {
            this._cancelAndRestartTimer();
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.arrowDown) {
            super.setState(() => this._hidden = true);
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.space) {
            this._playPause();
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            this._cancelAndRestartTimer();
            final position = this._controller.value.position;
            final seekTo = position - const Duration(seconds: 10);
            this._controller.seekTo(seekTo > Duration.zero ? seekTo : Duration.zero);
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.arrowRight) {
            this._cancelAndRestartTimer();
            final position = this._controller.value.position;
            final seekTo = position + const Duration(seconds: 10);
            this._controller.seekTo(seekTo < this._controller.value.duration ? seekTo : this._controller.value.duration);
            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.keyM) {
            this._cancelAndRestartTimer();

            if (this._controller.value.volume == 0)
                this._controller.setVolume(1.0);
            else
                this._controller.setVolume(0.0);

            return KeyEventResult.handled;
        }

        if(event.logicalKey == LogicalKeyboardKey.keyF) {
            this._onExpandCollapse();
            return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
    }
}
