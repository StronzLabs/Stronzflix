import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/methods/fullscreen.dart';

class ExitButton extends StatelessWidget {
    const ExitButton({super.key});

    @override
    Widget build(BuildContext context) {
        return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
                if (isFullscreen(context))
                    await exitFullscreen(context);
                if (context.mounted)
                    Navigator.of(context).pop();
            },
        );
    }
}
