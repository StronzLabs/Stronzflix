import 'package:flutter/material.dart';

class AnimatedPlayPause extends StatefulWidget {
    final double? size;
    final bool playing;
    final Color? color;

    const AnimatedPlayPause({
        super.key,
        required this.playing,
        this.size,
        this.color,
    });

    @override
    State<StatefulWidget> createState() => AnimatedPlayPauseState();
}

class AnimatedPlayPauseState extends State<AnimatedPlayPause> with SingleTickerProviderStateMixin {
    late final AnimationController animationController;

    @override
    void initState() {
        super.initState();
        this.animationController = AnimationController(
            vsync: this,
            value: super.widget.playing ? 1 : 0,
            duration: const Duration(milliseconds: 400),
        );
    }

    @override
    void didUpdateWidget(AnimatedPlayPause oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (super.widget.playing != oldWidget.playing) {
            if (super.widget.playing)
                this.animationController.forward();
            else
                this.animationController.reverse();
        }
    }

    @override
    void dispose() {
        this.animationController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Center(
            child: AnimatedIcon(
                color: widget.color,
                size: widget.size,
                icon: AnimatedIcons.play_pause,
                progress: animationController
            )
        );
    }
}
