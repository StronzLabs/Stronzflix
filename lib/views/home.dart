import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/player.dart';
import 'package:stronzflix/utils/storage.dart';
import 'package:stronzflix/views/media.dart';
import 'package:stronzflix/views/search.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    AppBar buildSearchBar(BuildContext context) {
        return AppBar(
            title: const Text("Stronzflix"),
            centerTitle: true,
            actions: [
                IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                        showSearch(context: context, delegate: SearchPage()).then((value) => super.setState(() {}));
                    },
                ),
            ],
        );        
    }

    void _playMedia(BuildContext context, TimeStamp timeStamp) {
        LateTitle media = LateTitle(
            name: timeStamp.name,
            url: timeStamp.url,
            player: Player.get(timeStamp.player)!,
            cover: timeStamp.cover
        );
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => MediaPage(
                media: media,
                startAt: Duration(milliseconds: timeStamp.time)
            )
        )).then((value) => super.setState(() {}));
    }

    Widget buildCard(BuildContext context, TimeStamp timestamp) {
        return Card(
            child: InkWell(
                onTap: () => this._playMedia(context, timestamp),
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                        children: [
                            Expanded(
                                child: Container(
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: NetworkImage(timestamp.cover),
                                            fit: BoxFit.contain
                                        ),
                                    ),
                                )
                            ),
                            Text(timestamp.name,
                                overflow: TextOverflow.ellipsis
                            )
                        ],
                    ),
                ),
            ),
        );
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
                    (timestamp) => this.buildCard(context, timestamp)
                ).toList(),
            );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this.buildSearchBar(context),
            body: Center(
                child: this._buildContent(context)
            )
        );
    }
}
