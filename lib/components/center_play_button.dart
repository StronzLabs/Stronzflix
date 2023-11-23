import 'package:flutter/material.dart';
import 'package:chewie/src/animated_play_pause.dart';

class CenterPlayButton extends StatelessWidget {
    const CenterPlayButton({
        super.key,
        required this.backgroundColor,
        this.iconColor,
        required this.show,
        required this.isPlaying,
        required this.isFinished,
        this.onPressed,
    });

    final Color backgroundColor;
    final Color? iconColor;
    final bool show;
    final bool isPlaying;
    final bool isFinished;
    final VoidCallback? onPressed;

    @override
    Widget build(BuildContext context) {
        return AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300), 
            child: ColoredBox(
            color: Colors.black26,
                child: Center(
                    child: UnconstrainedBox(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: backgroundColor,
                                shape: BoxShape.circle,
                            ),
                            child: IconButton(
                                iconSize: 32,
                                padding: const EdgeInsets.all(12.0),
                                icon: isFinished
                                    ? Icon(Icons.replay, color: iconColor)
                                    : AnimatedPlayPause(
                                        color: iconColor,
                                        playing: isPlaying,
                                    ),
                                onPressed: onPressed,
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}