import 'dart:ui';

import 'package:async/async.dart';
import 'package:flutter/material.dart' hide Title;
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/components/card_grid.dart';
import 'package:stronzflix/components/cast_button.dart';
import 'package:stronzflix/components/episode_card.dart';
import 'package:stronzflix/components/expandable_text.dart';
import 'package:stronzflix/components/resource_image.dart';
import 'package:stronzflix/components/save_title_button.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';
import 'package:stronzflix/dialogs/download_dialog.dart';

class TitlePage extends StatefulWidget {
    const TitlePage({super.key});

    @override
    State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> {

    Title? _title;
    Title get title => this._title!;
    late TitleMetadata _metadata;
    late String _heroUuid;
    late Season _selectedSeason;
    bool _discarding = false;
    
    AsyncMemoizer _memoizer = AsyncMemoizer();

    @override
    void initState() {
        super.initState();
        LocalSite.instance.addListener(this._refetchLocal);
    }

    @override
    void dispose() {
        LocalSite.instance.removeListener(this._refetchLocal);
        super.dispose();
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        List args = ModalRoute.of(super.context)!.settings.arguments as List;
        this._heroUuid = args[0];
        this._metadata = args[1];
    }

    Widget _buildBanner(BuildContext context) {
        return ClipRRect(
            child: Stack(
                children: [
                    Hero(
                        tag: this._heroUuid,
                        child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: resourceImageProvider(
                                        uri: this._metadata.poster
                                    ),
                                    fit: BoxFit.cover,
                                ),
                            ),
                            child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: const SizedBox.expand(),
                            ),
                        ),
                    ),
                    if(this._title != null)
                        Align(
                            alignment: Alignment.topCenter,
                            child: ResourceImage(
                                uri: this.title.banner,
                                fit: BoxFit.fitHeight,
                                height: 300,
                                alignment: this.title.site.cropPolicy,
                            )
                        )
                ],
            ),
        );
    }

    Widget _buildGradient(BuildContext context) {
        return Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                        0.0,
                        0.2,
                    ],
                    colors: [
                        Color(0x61000000),
                        Color(0x00000000),
                    ],
                )
            )
        );
    }

    Widget _buildTopBar(BuildContext context) {
        return SliverAppBar.large(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
                const CastButton(),
                if( this._metadata.site is! LocalSite) ...[
                    const SizedBox(width: 8),
                    SaveTitleButton(title: this._metadata),
                    const SizedBox(width: 8)
                ]
            ],
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                    children: [
                        this._buildBanner(context),
                        this._buildGradient(context)
                    ],
                ),
            ),
            title: Text(this._metadata.name,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold
                )
            ),
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
                ExpandableText(this.title.description,
                    collapsedLabel: "Mostra altro",
                    expandedLabel: "Mostra meno",
                    maxLines: 3,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                        fontSize: 16,
                    )
                )
            ]
        );
    }

    Widget _buildFilmActions(BuildContext context) {
        Widget buildButton(String label, IconData icon, void Function() onPressed) {
            return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(17.0),
                    minimumSize: const Size(300, 0),
                ),
                onPressed: onPressed,
                label: Text(label,
                    style: const TextStyle(
                        fontSize: 30
                    )
                ),
                icon: Icon(icon,
                    size: 40
                )
            );
        }

        return OverflowBar(
            spacing: 30.0,
            overflowSpacing: 20.0,
            overflowAlignment: OverflowBarAlignment.center,
            children: [
                buildButton("Guarda", Icons.play_arrow, () => this._play(this._title! as Film)),
                if(this.title.site.allowsDownload) ...[
                    buildButton("Scarica", Icons.download, () => this._download(this._title! as Film))
                ]
                else if(this.title.site is LocalSite) ...[
                    buildButton("Elimina", Icons.delete, () => this._delete(this._title! as Film))
                ]
            ]
        );
    }

    Widget _buildSeriesActions(BuildContext context) {
        Series series = this.title as Series;

        return Align(
            alignment: Alignment.centerRight,
            child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).disabledColor, width: 2.0),
                    borderRadius: BorderRadius.circular(20.0),
                ),
                child: DropdownButton<Season>(
                    focusColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    underline: const SizedBox.shrink(),
                    value: this._selectedSeason,
                    items: [
                        for (Season season in series.seasons)
                            DropdownMenuItem(
                                value: season,
                                child: Text(season.name ?? "Stagione ${season.seasonNo}")
                            )
                    ],
                    onChanged: series.seasons.length == 1 ? null
                        : (selected) => super.setState(() => this._selectedSeason = selected!),
                )
            )
        );
    }

    Widget _buildActions(BuildContext context) {
        if (this.title.comingSoon != null)
            return const SizedBox.shrink();

        return switch(this.title.runtimeType) {
            Film => this._buildFilmActions(context),
            Series => this._buildSeriesActions(context),
            _ => throw Exception("Unknown title type ${this._title.runtimeType}")
        };
    }

    Widget _buildEpisodes(BuildContext context) {
        return CardGrid(
            physics: const NeverScrollableScrollPhysics(),
            values: this._selectedSeason.episodes,
            aspectRatio: 3 / 2,
            shrinkWrap: true,
            buildCard: (episode) => EpisodeCard(episode: episode)
        );
    }

    Widget _buildTitle(BuildContext context) {
        return SliverList.list(
            children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                        children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: this._buildDescription(context),
                            ),
                            const SizedBox(height: 10.0),
                            this._buildActions(context)
                        ],
                    )
                ),
                if (this.title.comingSoon != null)
                    this._buildComingSoon(context)
                else if(this.title is Series)
                    this._buildEpisodes(context)
            ]
        );
    }

    Widget _buildComingSoon(BuildContext context) {
        String date = this.title.comingSoon!.toIso8601String().substring(0, 10).split("-").reversed.join("/");
        return Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
                children: [
                    const Text("Prossimamente",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    const SizedBox(height: 20),
                    Text("Data prevista di rilascio: ${date}",
                        style: const TextStyle(
                            fontSize: 16
                        ),
                        textAlign: TextAlign.justify,
                    )
                ]
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: FutureBuilder(
                future: this._memoizer.runOnce(() => this._fetchTitle()),
                builder: (context, snapshot) {

                    return CustomScrollView(
                        slivers: [
                            this._buildTopBar(context),
                             if (snapshot.hasError)
                                const SliverFillRemaining(
                                    child: Center(
                                        child: Text("Errore durante il caricamento del titolo"),
                                    ),
                                )
                            else if (snapshot.connectionState != ConnectionState.done)
                                const SliverFillRemaining(
                                    child: Center(
                                        child: CircularProgressIndicator(),
                                    ),
                                )
                            else
                                this._buildTitle(context)
                        ],
                    );
                }
            )
        );
    }

    Future<void> _fetchTitle() async {
        Title title = await this._metadata.site.getTitle(this._metadata);
        this._title = title;
        if(title is Series)
            this._selectedSeason = title.seasons.first;
    }

    Future<void> _refetchLocal() async {
        if(!(this._title?.site.isLocal ?? false))
            return;

        try {
            Title updatedTitle = await LocalSite.instance.getTitle(this._metadata);
            
            if(updatedTitle is Series) {
                this._selectedSeason = updatedTitle.seasons.firstWhere(
                    (season) => season.seasonNo == this._selectedSeason.seasonNo,
                    orElse: () => updatedTitle.seasons.first);
            }
 
            if(super.mounted)
                super.setState(() {
                    this._title = updatedTitle;
                });
        } catch (e) {
            if(super.mounted && !this._discarding) {
                this._discarding = true;
                Navigator.of(super.context).pop();
            }
        }
    }

    void _play(Watchable watchable) {
        Navigator.pushNamed(context, '/player', arguments: watchable)
            .then((value) => super.setState(() {}));
    }

    void _download(Watchable watchable) async {
        DownloadDialog.open(context, watchable);
    }

    void _delete(Watchable watchable) async {
        bool delete = await ConfirmationDialog.ask(context,
            "Elimina ${watchable.title}",
            "Sei sicuro di voler eliminare ${watchable.title}?",
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
