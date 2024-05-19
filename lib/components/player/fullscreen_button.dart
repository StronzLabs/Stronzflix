import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FullscreenButton extends StatelessWidget {
    const FullscreenButton({
        super.key
    });

    @override
    Widget build(BuildContext context) {
        return IconButton(
            onPressed: () => toggleFullscreen(context),
            icon: (isFullscreen(context)
                    ? const Icon(Icons.fullscreen_exit)
                    : const Icon(Icons.fullscreen)),
            iconSize: 28
        );
    }
}
