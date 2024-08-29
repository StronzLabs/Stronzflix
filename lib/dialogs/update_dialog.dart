import 'package:flutter/material.dart';
import 'package:stronzflix/backend/update/version.dart';
import 'package:sutils/sutils.dart';

class UpdateDialog extends StatelessWidget {

    const UpdateDialog({super.key});

    @override
    Widget build(BuildContext context) {
        String action = EPlatform.isMobile ? "Installa" : "Scarica";

        return AlertDialog(
            title: const Text('Aggiornamento disponibile!'),
            content: RichText(
                text: const TextSpan(
                    children: [
                        TextSpan(
                            text: 'Una nuova versione di Stronzflix è disponibile.\n',
                        ),
                        TextSpan(
                            text: 'Vuoi aggiornare?',
                        )]
                )
            ),
            actions: [
                TextButton(
                    child: const Text('Ignora'),
                    onPressed: () => Navigator.of(context).pop()
                ),
                TextButton(
                    child: Text(action),
                    onPressed: () async {
                        VersionChecker.update().then((progressStream) =>
                            Navigator.of(context).pop(progressStream)
                        );
                    }
                )
            ]
        );
    }
}