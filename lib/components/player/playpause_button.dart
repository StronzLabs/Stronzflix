import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';

class PlayPauseButton extends StatefulWidget {
    const PlayPauseButton({
        super.key,
    });

    @override
    State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> with SingleTickerProviderStateMixin {
    late final AnimationController _animation = AnimationController(
        vsync: this,
        value: playerController(super.context).isPlaying ? 1 : 0,
        duration: const Duration(milliseconds: 200),
    );
    StreamSubscription<bool>? _subscription;

    @override
    void setState(VoidCallback fn) {
        if (super.mounted)
            super.setState(fn);
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        this._subscription ??= playerController(super.context).stream.playing.listen((event) {
            if (event)
                this._animation.forward();
            else
                this._animation.reverse();
        });
    }

    @override
    void dispose() {
        this._animation.dispose();
        this._subscription?.cancel();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return IconButton(
            onPressed: playerController(context).playOrPause,
            iconSize: 28, 
            icon: AnimatedIcon(
                progress: this._animation,
                icon: AnimatedIcons.play_pause,
                size: 28,
            )
        );
    }
}
