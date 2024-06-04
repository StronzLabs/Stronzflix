import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/backend/version.dart';
import 'package:stronzflix/components/select_dropdown.dart';
import 'package:stronzflix/dialogs/loading_dialog.dart';
import 'package:stronzflix/utils/platform.dart';

class SettingsDialog extends StatelessWidget {
    const SettingsDialog({super.key});

    Widget _buildLegalClause(BuildContext context) {
        return RichText(
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
                        text: ".\nSegui gli aggiornamenti o scarica la versione più recente sul "
                    ),
                    TextSpan(
                        text: "sito web",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            decoration: TextDecoration.underline
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () => SPlatform.launchURL("https://bonfra04.github.io/Stronzflix/")
                    ),const TextSpan(
                        text: ".\n"
                    ),
                    const TextSpan(
                        text: "\nGli sviluppatori di questa applicazione non ospitano né distribuiscono nessuno dei contenutivisualizzabili tramite la stessa né hanno alcuna affiliazione con i fornitori di contenuti.",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey
                        )
                    )
                ]
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Row(
                children: [
                    FutureBuilder(
                        future: VersionChecker.getCurrentVersion(),
                        builder: (context, snapshot) {
                            if(snapshot.hasData)
                                return Text("Stronzflix ${snapshot.data}");
                            return const Text("Stronzflix");
                        }
                    ),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                    )
                ],
            ),
            content: SizedBox(
                width: 444,
                child: ListView(
                    shrinkWrap: true,
                    children: [
                        const SizedBox(height: 16),
                        SelectDropDown<Site>(
                            label: "Sorgente",
                            options: Site.sites,
                            selectedValue: Settings.site,
                            onSelected: (selection) {
                                Settings.site = selection;
                                Settings.update();
                            },
                            actionIcon: Icons.find_replace_rounded,
                            action: (site) {
                                LoadingDialog.progress(
                                    context,
                                    () async* {
                                        await for(dynamic res in site.tune()) {
                                            if(res is double)
                                                yield res;
                                            else if (res == null)
                                                await showDialog(
                                                    context: context,
                                                    builder: (context) => const AlertDialog(
                                                        title: Text("Errore"),
                                                        content: Text("La sintonizzazione non è andata a buon fine.")
                                                    )
                                                );
                                        }
                                    }
                                );
                            },
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        this._buildLegalClause(context)
                    ],
                )
            ),
        );
    }
}