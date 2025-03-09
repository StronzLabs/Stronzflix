import 'dart:ui';

import 'package:async/async.dart';
import 'package:flutter/material.dart' hide Title;
import 'package:stronz_cast/ui/stronz_cast_button.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/card_grid.dart';
import 'package:stronzflix/components/episode_card.dart';
import 'package:stronzflix/components/expandable_text.dart';
import 'package:stronzflix/widgets/save_title_button.dart';
import 'package:stronzflix/dialogs/download_dialog.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'package:stronzflix/widgets/seasons_dropdown_button.dart';
import 'package:sutils/ui/widgets/circular_progress_button.dart';
import 'package:sutils/ui/widgets/resource_image.dart';
import 'package:sutils/utils.dart';

class TitlePageArguments {
    final String heroUuid;
    final TitleMetadata metadata;
    
    const TitlePageArguments(this.heroUuid, this.metadata);
}

class TitlePage extends StatefulWidget {
    final String heroUuid;
    final TitleMetadata metadata;
    
    const TitlePage({
        required this.heroUuid,
        required this.metadata,
        super.key
    });

    @override
    State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> {

    Title? _title;
    Title get title => this._title!;
    late Season _selectedSeason;
    bool _discarding = false;
    
    final AsyncMemoizer _memoizer = AsyncMemoizer();

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

    Widget _buildBanner(BuildContext context) {
        return ClipRRect(
            child: Stack(
                children: [
                    Hero(
                        tag: super.widget.heroUuid,
                        child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: ResourceImage.provider(
                                        uri: super.widget.metadata.poster
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
            leading: BackButton(),
            actions: [
                const StronzCastButton(),
                if(super.widget.metadata.site is! LocalSite) ...[
                    const SizedBox(width: 8),
                    SaveTitleButton(title: super.widget.metadata),
                ],
                const SizedBox(width: 8)
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
            title: Text(super.widget.metadata.name,
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
                Text(super.widget.metadata.name,
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
        int? duration = KeepWatching.getDuration(this.title as Film);
        int? timestamp = KeepWatching.getTimestamp(this.title as Film);
        double? progress = duration != null && timestamp != null
            ? timestamp / duration
            : null;

        return Align(
            alignment: Alignment.center,
            child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 20.0,
                children: [
                    CircularProgressButton(
                        icon: progress != null ? Icons.fast_forward : Icons.play_arrow,
                        borderPercentage: progress ?? 0.0,
                        autofocus: EPlatform.isTV,
                        action: () => Navigator.pushNamed(context, '/player', arguments: PlayerPageArguments(this.title as Film))
                    ),
                    if(this.title.site.isLocal)
                        CircularProgressButton(
                            icon: Icons.delete_outline,
                            action: () => DownloadManager.deleteDialog(context, this.title as Film)
                        )
                    else if(this.title.site.allowsDownload)
                        FutureBuilder(
                            future: DownloadManager.alreadyDownloaded(this.title as Film),
                            builder: (context, snapshot) => CircularProgressButton(
                                icon: snapshot.hasData && snapshot.data!
                                    ? Icons.download_done_rounded
                                    : Icons.file_download_outlined,
                                action: snapshot.hasData && !snapshot.data!
                                    ? () => DownloadDialog.open(context, this.title as Film)
                                    : null,
                            )
                        )
                ]
            ),
        );
    }

    Widget _buildSeriesActions(BuildContext context) {
        return Align(
            alignment: Alignment.centerRight,
            child: SeasonsDropdownButton(
                selectedSeason: this._selectedSeason,
                seasons: (this.title as Series).seasons,
                onSeasonSelected: (selected) => super.setState(() => this._selectedSeason = selected),
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
            buildCard: (context, episode) => EpisodeCard(episode: episode)
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
        Title title = await super.widget.metadata.site.getTitle(super.widget.metadata);
        this._title = title;
        if(title is Series && title.seasons.isNotEmpty) {
            Watchable? episode = await KeepWatching.getWatchable(super.widget.metadata, title: this._title);
            int? seasonNo = (episode as Episode?)?.season.seasonNo;
            this._selectedSeason = title.seasons.firstWhere(
                (season) => season.seasonNo == seasonNo,
                orElse: () => title.seasons.first
            );
        }
    }

    Future<void> _refetchLocal() async {
        if(!(this._title?.site.isLocal ?? false))
            return;

        try {
            Title updatedTitle = await LocalSite.instance.getTitle(super.widget.metadata);
            
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
}
