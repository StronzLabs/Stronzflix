import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/version.dart';
import 'package:stronzflix/utils/platform.dart';

class InfoDialog extends StatelessWidget {

    const InfoDialog({super.key});

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: FutureBuilder(
                future: VersionChecker.getCurrentVersion(),
                builder: (context, snapshot) {
                    if(snapshot.hasData)
                        return Text("Stronzflix ${snapshot.data}");
                    return const Text("Stronzflix");
                }
            ),
            content: RichText(
                text: TextSpan(
                    children: [
                        const TextSpan(
                            text: "Stronzflix è un progetto open source rilasciato sotto licenza GNU GPLv3.\nIl codice sorgente è disponibile su "
                        ),
                        TextSpan(
                            text: "GitHub",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                decoration: TextDecoration.underline
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () => SPlatform.launchURL("https://github.com/Bonfra04/Stronzflix")
                        ),
                        const TextSpan(
                            text: "."
                        ),
                    ]
                )
            )
        );
    }

}