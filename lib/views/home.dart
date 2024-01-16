import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/version.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:stronzflix/utils/storage.dart';
import 'package:stronzflix/views/media.dart';
import 'package:stronzflix/views/search.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    void _showInfo(BuildContext context) async {
        String version = await VersionChecker.getCurrentVersion();
        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text("Stronzflix ${version}"),
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
            )
        );
    }

    void _checkVersion() async {
        if(SPlatform.isMobile)
            await VersionChecker.cleanCache();
        if(!await VersionChecker.shouldUpdate())
            return;

        String action = SPlatform.isMobile ? "Installa" : "Scarica";

        // ignore: use_build_context_synchronously
        showDialog(
            context: super.context,
            builder: (context) => AlertDialog(
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
            )
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

    AppBar _buildSearchBar(BuildContext context) {
        return AppBar(
            title: const Text("Stronzflix"),
            leading: IconButton(
                icon: const Icon(Icons.info_outlined),
                onPressed: () => this._showInfo(context)
            ),
            actions: [
                Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => showSearch(
                            context: context,
                            delegate: SearchPage()
                        ).then((value) => super.setState(() {}))
                    )
                )
            ]
        );        
    }

    void _playMedia(BuildContext context, TimeStamp timeStamp) {
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => MediaPage(
                media: LateTitle.fromTimestamp(timeStamp: timeStamp)
            )
        )).then((value) => super.setState(() {}));
    }

    void _removeMedia(TimeStamp timeStamp) {
        super.setState(() => Storage.removeWatching(timeStamp));
    }

    Widget _buildContent(BuildContext context) {
        if(Storage.keepWatching.isEmpty)
            return const Center(
                child: Text("Non hai ancora iniziato a guardare nulla")
            );
        else
            return GridView.extent(
                childAspectRatio: 3 / 2,
                maxCrossAxisExtent: 400,
                children: Storage.keepWatching.values.map(
                    (timestamp) => ResultCard(
                        imageUrl: timestamp.cover,
                        text: timestamp.name,
                        onTap: () => this._playMedia(context, timestamp),
                        onLongPress: () => this._removeMedia(timestamp)
                    )
                ).toList(),
            );
    }

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) => this._checkVersion());
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this._buildSearchBar(context),
            body: Center(
                child: this._buildContent(context)
            )
        );
    }
}
