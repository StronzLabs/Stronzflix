import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';

class SourcesDialog extends StatelessWidget {

    final List<WatchOption> options;

    const SourcesDialog({
        super.key,
        required this.options
    });

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Seleziona una sorgente'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    for (WatchOption option in this.options)
                        Card(
                            child: InkWell(
                                onTap: () => Navigator.of(context).pop(option),
                                child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(option.player.name),
                                ),
                            )
                        )
                ]
            )
        );
    }
}
