import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/components/card_grid.dart';
import 'package:stronzflix/components/download_card.dart';
import 'package:stronzflix/widgets/delete_title_button.dart';
import 'package:stronzflix/widgets/downloads_icon.dart';
import 'package:stronzflix/widgets/save_title_button.dart';
import 'package:stronzflix/components/title_card.dart';
import 'package:stronzflix/pages/home_page.dart';

class HomePageMobile extends StatefulWidget {
    const HomePageMobile({super.key});

    @override
    State<HomePageMobile> createState() => _HomePageMobileState();
}

enum _CurrentSection {
    keepWatching,
    news,
    saved,
    downloads,
}

class _HomePageMobileState extends HomePageState<HomePageMobile> {
    _CurrentSection _currentSection = _CurrentSection.news;

    @override
    NavigationBar buildBottomNavigationBar(BuildContext context) {
        return NavigationBar(
            destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.fast_forward),
                    label: "Riprendi",
                ),
                NavigationDestination(
                    icon: Icon(Icons.newspaper_outlined),
                    label: "Novità",
                ),
                NavigationDestination(
                    icon: Icon(Icons.bookmark_outline),
                    label: "Salvati",
                ),
                NavigationDestination(
                    icon: DownloadsIcon(),
                    label: "Download",
                ),
            ],
            selectedIndex: this._currentSection.index,
            onDestinationSelected: (index) => super.setState(() => this._currentSection = _CurrentSection.values[index]),
        );
    }

    Widget _buildSection<T>({
        required Iterable<T> value,
        String? emptyText,
        double cardAspectRatio = 16 / 9,
        required Widget Function(BuildContext, T) buildCard,
    }) {
        return CardGrid(
            values: value,
            emptyWidget: emptyText == null
                ? null
                : Center(child: Text(emptyText)),
            aspectRatio: cardAspectRatio,
            minCardHeight: 120,
            buildCard: buildCard,
        );
    }

    Widget _buildListenableSection<T>({
        required ValueListenable<Iterable<T>> listenable,
        String? emptyText,
        double cardAspectRatio = 16 / 9,
        required Widget Function(BuildContext, T) buildCard
    }) {
        return ValueListenableBuilder<Iterable<T>>(
            valueListenable: listenable,
            builder: (context, value, _) => this._buildSection(
                value: value,
                emptyText: emptyText,
                cardAspectRatio: cardAspectRatio,
                buildCard: buildCard
            ),
        );
    }

    Widget _buildFutureSection<T>({
        required Future<Iterable<T>> future,
        String? emptyText,
        double cardAspectRatio = 16 / 9,
        required Widget Function(BuildContext, T) buildCard
    }) {
        return FutureBuilder(
            future: future,
            builder: (context, snapshot) {
                if(snapshot.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());

                return RefreshIndicator(
                    onRefresh: () async => super.refetchLatests(), 
                    child: this._buildSection(
                        value: snapshot.data!,
                        emptyText: emptyText,
                        cardAspectRatio: cardAspectRatio,
                        buildCard: buildCard
                    ),
                );
            }
        );
    }

    Widget _buildKeepWatching(BuildContext context) {
        return this._buildListenableSection(
            listenable: KeepWatching.listener,
            emptyText: "Non hai ancora guardato nulla",
            buildCard: (context, metadata) => TitleCard(
                action: IconButton(
                    onPressed: () => KeepWatching.remove(metadata.metadata),
                    icon: const Icon(Icons.close, size: 28)
                ),
                title: metadata.metadata,
            )
        );
    }

    Widget _buildNews(BuildContext context) {
        return this._buildFutureSection(
            future: super.newsMemoizer.runOnce(Settings.site.latests),
            emptyText: "Non ci sono novità",
            buildCard: (context, metadata) => TitleCard(
                action: Settings.site.isLocal
                    ? DeleteTitleButton(title: metadata)
                    : SaveTitleButton(title: metadata),
                title: metadata,
            )
        );
    }

    Widget _buildSaved(BuildContext context) {
        return this._buildListenableSection(
            listenable: SavedTitles.listener,
            emptyText: "Non hai salvato nessun titolo",
            buildCard: (context, metadata) => TitleCard(
                action: SaveTitleButton(title: metadata),
                title: metadata,
            )
        );
    }

    Widget _buildDownloads(BuildContext context) {
        return this._buildListenableSection(
            listenable: DownloadManager.downloads,
            emptyText: "Nessun download in corso",
            cardAspectRatio: 16 / 5,
            buildCard: (context, metadata) => DownloadCard(
                download: metadata,
            )
        );
    }

    @override
    Widget buildBody(BuildContext context) {
        return switch(this._currentSection) {
            _CurrentSection.keepWatching => this._buildKeepWatching(context),
            _CurrentSection.news => this._buildNews(context),
            _CurrentSection.saved => this._buildSaved(context),
            _CurrentSection.downloads => this._buildDownloads(context),
        };
    }
    
}