import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/components/card_row.dart';
import 'package:stronzflix/widgets/download_card.dart';
import 'package:stronzflix/widgets/delete_title_button.dart';
import 'package:stronzflix/widgets/save_title_button.dart';
import 'package:stronzflix/widgets/title_card.dart';
import 'package:stronzflix/pages/home_page.dart';
import 'package:sutils/utils.dart';

class HomePageBigScreen extends StatefulWidget {
    const HomePageBigScreen({super.key});

    @override
    State<HomePageBigScreen> createState() => _HomePageBigScreenState();
}

class _HomePageBigScreenState extends HomePageState<HomePageBigScreen> {

    Widget _buildSection<T>({
        required Iterable<T> value,
        required String label,
        double cardAspectRatio = 16 / 9,
        bool autofocus = false,
        required Widget Function(BuildContext, T, bool) buildCard,
    }) {
        return CardRow(
            title: label,
            values: value,
            buildCard: buildCard,
            cardAspectRatio: cardAspectRatio,
            autofocus: autofocus,
        );
    }

    Widget _buildListenableSection<T>({
        required ValueListenable<Iterable<T>> listenable,
        required String label,
        double cardAspectRatio = 16 / 9,
        bool autofocus = false,
        required Widget Function(BuildContext, T, bool) buildCard
    }) {
        return ValueListenableBuilder<Iterable<T>>(
            valueListenable: listenable,
            builder: (context, value, _) => this._buildSection(
                value: value,
                label: label,
                cardAspectRatio: cardAspectRatio,
                autofocus: autofocus,
                buildCard: buildCard
            ),
        );
    }

    Widget _buildFutureSection<T>({
        required Future<Iterable<T>> future,
        required String label,
        double cardAspectRatio = 16 / 9,
        bool autofocus = false,
        required Widget Function(BuildContext, T, bool) buildCard
    }) {
        return FutureBuilder(
            future: future,
            builder: (context, snapshot) {
                if(snapshot.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());

                return this._buildSection(
                    value: snapshot.data!,
                    label: label,
                    cardAspectRatio: cardAspectRatio,
                    autofocus: autofocus,
                    buildCard: buildCard
                );
            }
        );
    }

    Widget _buildKeepWatching(BuildContext context, bool autofocus) {
        return this._buildListenableSection(
            listenable: KeepWatching.listener,
            label: "Continua a guardare",
            autofocus: autofocus,
            buildCard: (context, metadata, autofocus) => TitleCard(
                autofocus: autofocus,
                action: IconButton(
                    onPressed: () => KeepWatching.remove(metadata.metadata),
                    icon: const Icon(Icons.close, size: 28)
                ),
                title: metadata.metadata,
            )
        );
    }

    Widget _buildNews(BuildContext context, bool autofocus) {
        return this._buildFutureSection(
            future: super.newsMemoizer.runOnce(Settings.site.latests),
            label: "Novità",
            buildCard: (context, metadata, autofocus) => TitleCard(
                autofocus: autofocus,
                action: Settings.site.isLocal
                    ? DeleteTitleButton(title: metadata)
                    : SaveTitleButton(title: metadata),
                title: metadata,
            )
        );
    }

    Widget _buildSaved(BuildContext context, bool autofocus) {
        return this._buildListenableSection(
            listenable: SavedTitles.listener,
            label: "Salvati",
            autofocus: autofocus,
            buildCard: (context, metadata, autofocus) => TitleCard(
                autofocus: autofocus,
                action: SaveTitleButton(title: metadata),
                title: metadata,
            )
        );
    }

    Widget _buildDownloads(BuildContext context) {
        return this._buildListenableSection(
            listenable: DownloadManager.downloads,
            label: "Download in corso",
            cardAspectRatio: 16 / 5,
            buildCard: (context, metadata, autofocus) => DownloadCard(
                download: metadata,
            )
        );
    }

    @override
    Widget buildBody(BuildContext context) {
        bool focusKeepWatching = EPlatform.isTV && KeepWatching.metadata.isNotEmpty;
        bool focusSaved = EPlatform.isTV && !focusKeepWatching && SavedTitles.all.isNotEmpty;
        bool focusNews = EPlatform.isTV && !focusKeepWatching && !focusSaved;

        return ListView(
            padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10),
            children: [
                this._buildKeepWatching(context, focusKeepWatching),
                this._buildSaved(context, focusSaved),
                this._buildNews(context, focusNews),
                this._buildDownloads(context),
            ]
        );
    }
}
