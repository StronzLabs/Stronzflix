import 'package:flutter/material.dart';
import 'package:stronzflix/utils/platform.dart';

class ExitButton extends StatelessWidget {
    const ExitButton({super.key});

    @override
    Widget build(BuildContext context) {
        return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
                if(await SPlatform.isFullScreen())
                    await SPlatform.setFullScreen(false);
                if (context.mounted)
                    Navigator.of(context).pop();
            },
        );
    }
}
