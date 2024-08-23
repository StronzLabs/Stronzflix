import 'package:flutter/material.dart';
import 'package:stronzflix/utils/platform.dart';

class FullscreenButton extends StatelessWidget {
    const FullscreenButton({
        super.key
    });

    @override
    Widget build(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: SPlatform.isFullScreenSync(),
            builder: (context, isFullScreen, child) => IconButton(
                icon: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                onPressed: () {
                    SPlatform.toggleFullScreen();
                }
            )
        );
    }
}
