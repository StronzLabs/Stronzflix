import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
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

    void _showInfo(BuildContext context) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Crediti"),
                content: RichText(
                    text: TextSpan(
                        children: [
                            const TextSpan(
                                text: "Stronzflix è un progetto open source rilasciato sotto licenza GNU GPLv3.\nIl codice sorgente è disponibile su "
                            ),
                            TextSpan(
                                text: "GitHub",
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary
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
                media: LateTitle.fromTimestamp(timeStamp: timeStamp),
                startAt: Duration(milliseconds: timeStamp.time)
            )
        )).then((value) => super.setState(() {}));
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
                        onTap: () => this._playMedia(context, timestamp),
                        imageUrl: timestamp.cover,
                        text: timestamp.name
                    )
                ).toList(),
            );
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
