import 'dart:io';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/media.dart' as sf show Title;
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';
import 'package:stronzflix/components/expandable_text.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';
import 'package:stronzflix/dialogs/download_dialog.dart';

class TitlePage extends StatefulWidget {
    const TitlePage({super.key});

    @override
    State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> {

    late /* final */ sf.Title _title;
    late final TitleMetadata _metadata = ModalRoute.of(super.context)!.settings.arguments as TitleMetadata;
    int _selectedSeason = 0;
    
    AsyncMemoizer _memoizer = AsyncMemoizer();

    Widget _buildBanner(BuildContext context) {
        double bannerHeight = 200;
        return ClipRRect(
            child: SizedBox(
                height: bannerHeight + 25,
                child: Stack(
                    children: [
                        Container(
                            height: bannerHeight,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: this._title.banner.startsWith("http")
                                        ? NetworkImage(
                                            this._title.banner,
                                        ) as ImageProvider<Object>
                                        : FileImage(
                                            File(this._title.banner),
                                        ) as ImageProvider<Object>,
                                    fit: BoxFit.cover,
                                ),
                            ),
                            child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: const SizedBox.expand(),
                            ),
                        ),
                        Align(
                            alignment: Alignment.topCenter,
                            child: this._title.banner.startsWith("https")
                                ? Image.network(
                                    this._title.banner,
                                    fit: BoxFit.cover,
                                    height: bannerHeight,
                                )
                                : Image.file(
                                    File(this._title.banner),
                                    fit: BoxFit.cover,
                                    height: bannerHeight,
                                )
                        )
                    ],
                ),
            )
        );
    }

    Widget _buildDescription(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(this._metadata.name,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                    )
                ),
                ExpandableText(this._title.description,
                    maxLines: 3,
                    expandText: "Mostra di più",
                    collapseText: "Mostra meno",
                    expandOnTextTap: true,
                    collapseOnTextTap: true,
                    animation: true,
                    animationDuration: const Duration(seconds: 1),
                    style: const TextStyle(
                        fontSize: 16,
                    ),
                    textAlign: TextAlign.justify,
                )
            ]
        );
    }

    Widget _buildActions(BuildContext context) {
        if (this._title is Film)
            return LayoutBuilder(
                builder: (context, constraints) {
                    bool vertical = constraints.maxWidth < 1200;
                    List<Widget> children = [
                        ElevatedButton(
                            onPressed: () => this._play(this._title as Film),
                            child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                        const Icon(Icons.play_arrow,
                                            size: 40,
                                        ),
                                        const SizedBox(width: 10),
                                        Transform.translate(
                                            offset: const Offset(0, -2.5),
                                            child: const Text('Guarda ',
                                                style: TextStyle(
                                                    fontSize: 30
                                                )
                                            ),
                                        )
                                    ],
                                ),
                            ),
                        ),
                        if(this._title.site.allowsDownload)
                        ...[
                            const SizedBox.square(dimension: 25),
                            ElevatedButton(
                                onPressed: this._title.site.isLocal
                                    ? () => this._delete(this._title as Film)
                                    : () => this._download(this._title as Film),
                                child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                            Icon(this._title.site.isLocal ? Icons.delete : Icons.download,
                                                size: 40,
                                            ),
                                            const SizedBox(width: 10),
                                            Transform.translate(
                                                offset: const Offset(0, -2.5),
                                                child: Text(this._title.site.isLocal ? 'Elimina' : 'Scarica',
                                                    style: const TextStyle(
                                                        fontSize: 30
                                                    )
                                                ),
                                            )
                                        ],
                                    ),
                                )
                            ),
                        ]
                    ];

                    return vertical
                        ? Column(children: children)
                        : Row(children: children);
                }
            );
        else
            return Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton(
                    value: this._selectedSeason,
                    items: [
                        for (int i = 0; i < (this._title as Series).seasons.length; i++)
                            DropdownMenuItem(
                                value: i,
                                child: Text((this._title as Series).seasons[i].name)
                            )
                    ],
                    onChanged: (index) => super.setState(() => this._selectedSeason = index!),
                ),
            );
    }

    Widget _buildEpisodes(BuildContext context) {
        Season season = (this._title as Series).seasons[this._selectedSeason];

        return Expanded(
            child: GridView.extent(
                shrinkWrap: true,
                childAspectRatio: 3 / 2,
                maxCrossAxisExtent: 400,
                children: season.episodes.map((Episode episode) {
                    int? duration = KeepWatching.getDuration(episode);
                    int? timestamp = KeepWatching.getTimestamp(episode);
                    double? progress = duration != null && timestamp != null
                        ? timestamp / duration
                        : null;
                    return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ResultCard(
                            onTap: () => this._play(episode),
                            action: this._title.site.isLocal
                                ? () => this._delete(episode)
                                : this._title.site.allowsDownload
                                    ? () => this._download(episode)
                                    : null,
                            actionIcon: this._title.site.isLocal
                                ? Icons.delete
                                : Icons.download,
                            imageUrl: episode.cover,
                            text: episode.name,
                            progress: progress,
                        )
                    );
                }).toList()
            )
        );
    }

    Widget _buildTitle(BuildContext context) {
        List<Widget> children = [
            this._buildBanner(context),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: LayoutBuilder(
                    builder: (context, constraints) {
                        bool vertical = constraints.maxWidth < 1200;
                        List<Widget> children = [
                            this._buildDescription(context),
                            const SizedBox.square(dimension: 25),
                            this._buildActions(context),
                        ];

                        return vertical
                            ? Column(children: children)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: children.map(
                                    (e) => e == children[0] ? Expanded(child: e) : e
                                ).toList(),
                            );
                    }
                )
            ),
            if (this._title is Series)
                this._buildEpisodes(context)
        ];
        return this._title is Film
            ? ListView(children: children + [ const SizedBox(height: 25) ])
            : Column(children: children);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: Text(this._metadata.name),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                ),
                actions: this._metadata.site is LocalSite ? null : [
                    IconButton(
                        icon: Icon(SavedTitles.isSaved(this._metadata) ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
                        onPressed: this._save,
                    ),
                    const SizedBox(width: 8)
                ],
            ),
            body: FutureBuilder(
                future: this._memoizer.runOnce(() => this._metadata.site.getTitle(this._metadata)),
                builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done)
                        return const Center(child: CircularProgressIndicator());

                    this._title = snapshot.data!;
                    return this._buildTitle(context);
                },
            )
        );
    }

    void _play(Watchable watchable) {
        Navigator.pushNamed(context, '/player', arguments: watchable)
        .then((value) => super.setState(() {}));
    }

    void _save() {
        super.setState(() {
            if(SavedTitles.isSaved(this._metadata))
                SavedTitles.remove(this._metadata);
            else
                SavedTitles.add(this._metadata);
        });
    }

    void _download(Watchable watchable) async {
        DownloadDialog.open(context, watchable);
    }

    void _delete(Watchable watchable) async {
        bool delete = await ConfirmationDialog.ask(context,
            "Elimina ${watchable.name}",
            "Sei sicuro di voler eliminare ${watchable.name}?",
            action: "Elimina"
        );
        if (delete) {
            await DownloadManager.deleteSingle(watchable);
            if(!super.mounted)
                return;
            if(this._title is Series)
                if((this._title as Series).seasons.length == 1 && (this._title as Series).seasons[0].episodes.length == 1)
                    Navigator.of(context).pop();
                else
                    this._memoizer = AsyncMemoizer();
            else
                Navigator.of(context).pop();
        }
    }
}
