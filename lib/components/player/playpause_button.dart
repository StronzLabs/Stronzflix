import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';

class PlayPauseButton extends StatefulWidget {
    final double iconSize;
    final void Function()? onFocus;
    final void Function()? onFocusLost;

    const PlayPauseButton({
        super.key,
        this.iconSize = 28,
        this.onFocus,
        this.onFocusLost,
    });

    @override
    State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> with SingleTickerProviderStateMixin {
    
    final FocusNode _focusNode = FocusNode();
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
    void initState() {
        super.initState();
        this._focusNode.addListener(() {
            if (this._focusNode.hasFocus)
                super.widget.onFocus?.call();
            else
                super.widget.onFocusLost?.call();
        });
    }

    @override
    Widget build(BuildContext context) {
        return IconButton(
            onPressed: playerController(context).playOrPause,
            focusNode: this._focusNode,
            iconSize: super.widget.iconSize, 
            icon: AnimatedIcon(
                progress: this._animation,
                icon: AnimatedIcons.play_pause,
                size: super.widget.iconSize,
            )
        );
    }
}
