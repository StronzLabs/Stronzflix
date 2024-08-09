import 'package:flutter/material.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';

class MediaTitle extends StatelessWidget {
    const MediaTitle({super.key});

    @override
    Widget build(BuildContext context) {
        return Expanded(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                    playerController(context).title,
                    style: const TextStyle(
                        fontSize: 21.0
                    ),
                ),
            ),
        );
    }
}
