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
                child: RichText(
                    text: playerController(context).isEpisode
                            ? TextSpan(
                                text: playerController(context).seriesTitle,
                                style: const TextStyle(fontSize: 21.0, fontWeight: FontWeight.bold),
                                children: <TextSpan>[
                                    TextSpan(
                                        text: '     ${playerController(context).episodeTitle}',
                                        style: const TextStyle(fontSize: 21.0, fontWeight: FontWeight.w300)
                                    )
                                ]
                            )
                            : TextSpan(
                                text: playerController(context).title,
                                style: const TextStyle(fontSize: 21.0, fontWeight: FontWeight.normal)
                            )
                )
            ),
        );
    }
}
