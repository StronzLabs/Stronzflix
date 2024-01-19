import 'package:flutter/material.dart';
import 'package:stronzflix/backend/version.dart';
import 'package:stronzflix/utils/platform.dart';

class UpdateDialog extends StatelessWidget {

    const UpdateDialog({super.key});

    @override
    Widget build(BuildContext context) {
        String action = SPlatform.isMobile ? "Installa" : "Scarica";

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
                        VersionChecker.update().then((updated) {
                            if(!updated)
                                return;
                            if(SPlatform.isMobile)
                                ScaffoldMessenger.of(context).showSnackBar(this._buildUpdateSnackBar());
                            Navigator.of(context).pop();
                        });
                    }
                )
            ]
        );
    }

    SnackBar _buildUpdateSnackBar() {
        return const SnackBar(
            content: Column(
                children: [
                    Text("Aggiornamento in corso..."),
                    Padding(padding: EdgeInsets.only(top: 8)),
                    LinearProgressIndicator()
                ],
            ),
            duration: Duration(hours: 1)
        );
    }

}