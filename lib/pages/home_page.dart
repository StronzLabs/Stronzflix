import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';
import 'package:stronzflix/backend/peer/peer_manager.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/components/cast_button.dart';
import 'package:stronzflix/components/delete_title_button.dart';
import 'package:stronzflix/components/downloads_button.dart';
import 'package:stronzflix/components/downloads_drawer.dart';
import 'package:stronzflix/components/save_title_button.dart';
import 'package:stronzflix/components/title_card.dart';
import 'package:stronzflix/components/card_grid.dart';
import 'package:stronzflix/components/title_card_row.dart';
import 'package:stronzflix/dialogs/loading_dialog.dart';
import 'package:stronzflix/dialogs/settings_dialog.dart';
import 'package:stronzflix/dialogs/sink_dialog.dart';
import 'package:stronzflix/pages/search_page.dart';
import 'package:sutils/sutils.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    StreamSubscription<Message>? _peerMessagesSubscription;
    int _currentSection = 0;
    bool get _isBigScreen => MediaQuery.of(super.context).size.width >= 600;
    bool get _hasPeerConnection => EPlatform.isDesktop && Settings.online;
    AsyncMemoizer<List<TitleMetadata>> _newsMemoizer = AsyncMemoizer();

    @override
    void initState() {
        super.initState();
        this._peerMessagesSubscription = PeerMessenger.messages.listen((message) {
            if(message.type == MessageType.startWatching && super.mounted)
                LoadingDialog.load(super.context, () async {
                    SerialMetadata metadata = SerialMetadata.unserialize(jsonDecode(message.data!));
                    return await Watchable.unserialize(metadata.metadata, metadata.info);
                }).then((watchable) {
                    if(super.mounted)
                        Navigator.of(super.context).pushNamed('/player-sink', arguments: watchable);
                });
        });

        LocalSite.instance.addListener(this._refetchLocal);
    }

    @override
    void dispose() {
        this._peerMessagesSubscription?.cancel();
        LocalSite.instance.removeListener(this._refetchLocal);
        super.dispose();
    }

    PreferredSizeWidget _buildAppBar(BuildContext context) {
        return AppBar(
            title: const Text("Stronzflix"),
            leading: const Center(child: DownloadsButton()),
            actions: [
                const CastButton(),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const SettingsDialog()
                    ).then((_) => this._refetchLatests())
                ),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => showSearch(
                        context: context,
                        delegate: SearchPage(),
                        maintainState: true
                    )
                ),
                const SizedBox(width: 8)
            ]
        );        
    }

    Widget _buildSection(BuildContext context, {
        required String label,
        required Iterable<TitleMetadata> values,
        Widget Function(TitleMetadata)? buildAction,
        String? emptyText
    }) {
        if(this._isBigScreen)
            return TitleCardRow(
                title: label,
                values: values,
                buildAction: buildAction
            );

        return CardGrid(
            values: values,
            buildCard: (metadata) => TitleCard(
                buildAction: buildAction,
                title: metadata,
            ),
            emptyWidget: emptyText == null
                ? null
                : Center(child: Text(emptyText))
        );
    }

    Widget _buildFutureSection(BuildContext context, {
        required String label,
        required Future<Iterable<TitleMetadata>> values,
        Widget Function(TitleMetadata)? buildAction,
        String? emptyText
    }) {
        return FutureBuilder(
            future: values,
            builder: (context, snapshot) {
                if(snapshot.connectionState != ConnectionState.done)
                    if(this._isBigScreen)
                        return TitleCardRow.shimmer(title: label);
                    else 
                        return const Center(child: CircularProgressIndicator());

                return RefreshIndicator(
                    onRefresh: () async => this._refetchLatests(), 
                    child: this._buildSection(context,
                        label: label,
                        values: snapshot.data as Iterable<TitleMetadata>,
                        buildAction: buildAction,
                        emptyText: emptyText
                    ),
                );
            }
        );
    }

    List<Widget> _buildSections(BuildContext context) {
        Widget keepWatching = ValueListenableBuilder(
            valueListenable: KeepWatching.listener,
            builder: (context, keepWatching, _) => this._buildSection(context,
                label: "Continua a guardare",
                values: KeepWatching.metadata,
                buildAction: (metadata) => IconButton(
                    onPressed: () => KeepWatching.remove(metadata),
                    icon: const Icon(Icons.close,
                        size: 28,
                    )
                ),
                emptyText: "Non hai ancora guardato nulla"
            )
        );

        Widget saved = ValueListenableBuilder(
            valueListenable: SavedTitles.listener,
            builder: (context, savedTitles, _) => this._buildSection(context,
                label: "Salvati",
                values: savedTitles,
                buildAction: (metadata) => SaveTitleButton(title: metadata),
                emptyText: "Non hai salvato nessun titolo"
            )
        );

        Widget news = this._buildFutureSection(context,
            label: "Novità",
            values: this._newsMemoizer.runOnce(Settings.site.latests),
            buildAction: Settings.site.isLocal
                ? (metadata) => DeleteTitleButton(title: metadata)
                : (metadata) => SaveTitleButton(title: metadata),
        );

        return this._isBigScreen
            ? [ keepWatching, saved, news ]
            : [ keepWatching, news, saved ];
    }

    Widget _buildBottomNavigationBar(BuildContext context) {
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
            ],
            selectedIndex: this._currentSection,
            onDestinationSelected: (index) => super.setState(() => this._currentSection = index),
        );
    }

    Widget _buildSinkButton(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: PeerManager.notifier,
            builder: (context, peerState, _) => FloatingActionButton(
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const SinkDialog()
                ),
                backgroundColor: peerState == PeerConnectionState.connected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
                child: Icon(peerState == PeerConnectionState.connecting
                    ? Icons.sync
                    : Icons.people
                )
            )
        );
    }

    Widget _buildBody(BuildContext context) {
        List<Widget> sections = this._buildSections(context);

        return this._isBigScreen
            ? ListView(
                padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10),
                children: sections
            )
            : sections[this._currentSection];
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this._buildAppBar(context),
            drawer: const DownloadsDrawer(),
            floatingActionButton: !this._hasPeerConnection ? null : this._buildSinkButton(context),
            bottomNavigationBar: this._isBigScreen ? null : this._buildBottomNavigationBar(context),
            body: this._buildBody(context),
        );
    }

    void _refetchLocal() {
        if(!Settings.site.isLocal)
            return;

        this._refetchLatests();
    }

    void _refetchLatests() {
        this._newsMemoizer = AsyncMemoizer();
        if(super.mounted)
            super.setState(() {});
    }
}
