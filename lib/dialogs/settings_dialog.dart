import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/backend/update/version.dart';
import 'package:stronzflix/components/labeled_checkbox.dart';
import 'package:stronzflix/components/select_dropdown.dart';
import 'package:stronzflix/dialogs/loading_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsDialog extends StatelessWidget {
    const SettingsDialog({super.key});

    void _launchURL(String url) async {
        Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri))
            await launchUrl(uri);
        else
            throw 'Could not launch ${url}';
    }

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
                        recognizer: TapGestureRecognizer()..onTap = () => this._launchURL("https://github.com/StronzLabs/Stronzflix")
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
                        recognizer: TapGestureRecognizer()..onTap = () => this._launchURL("https://StronzLabs.github.io/Stronzflix/")
                    ),const TextSpan(
                        text: ".\n"
                    ),
                    const TextSpan(
                        text: "\nGli sviluppatori di questa applicazione non ospitano né distribuiscono nessuno dei contenuti visualizzabili tramite la stessa né hanno alcuna affiliazione con i fornitori di contenuti.",
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
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        const SizedBox(height: 16),
                        SelectDropDown<Site>(
                            label: "Canale",
                            options: Site.sites,
                            selectedValue: Settings.site,
                            onSelected: (selection) {
                                Settings.site = selection;
                                Settings.instance.serialize();
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
                        LabeledCheckbox(
                            label: const Text("Scelta avanzata delle sorgenti",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold
                                )
                            ),
                            initialValue: Settings.pickSource,
                            onChanged: (value) {
                                Settings.pickSource = value;
                                Settings.instance.serialize();
                            } 
                        ),
                        const Divider(),
                        this._buildLegalClause(context)
                    ],
                )
            ),
        );
    }
}