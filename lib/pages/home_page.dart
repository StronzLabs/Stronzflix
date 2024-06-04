import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/keep_watching.dart';
import 'package:stronzflix/backend/saved_titles.dart';
import 'package:stronzflix/backend/peer/peer_manager.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/backend/settings.dart';
import 'package:stronzflix/components/downloads_drawer.dart';
import 'package:stronzflix/components/result_card_row.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';
import 'package:stronzflix/dialogs/loading_dialog.dart';
import 'package:stronzflix/dialogs/settings_dialog.dart';
import 'package:stronzflix/dialogs/sink_dialog.dart';
import 'package:stronzflix/pages/search_page.dart';
import 'package:stronzflix/utils/platform.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    StreamSubscription<Message>? _peerMessagesSubscription;

    AppBar _buildAppBar(BuildContext context) {
        return AppBar(
            centerTitle: true,
            title: const Text("Stronzflix"),
            leading: Builder(
                builder: (context) => IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => Scaffold.of(context).openDrawer()
                )
            ),
            actions: [
                IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const SettingsDialog()
                    ).then((_) {
                        if(super.mounted)
                            super.setState(() {});
                    })
                ),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => showSearch(
                        context: context,
                        delegate: SearchPage()
                    ).then((_) {
                        if(super.mounted)
                            super.setState(() {});
                    })
                ),
                const SizedBox(width: 8)
            ]
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

    @override
    void initState() {
        super.initState();
        this._peerMessagesSubscription = PeerMessenger.messages.listen((message) {
            if(message.type == MessageType.startWatching)
                LoadingDialog.load(super.context, () async {
                    SerialMetadata metadata = SerialMetadata.unserialize(jsonDecode(message.data!));
                    return await Watchable.unserialize(metadata.metadata, metadata.info);
                }).then((watchable) {
                    if(super.mounted)
                        Navigator.of(super.context).pushNamed('/player-sink', arguments: watchable);
                });
        });
    }

    @override
    void dispose() {
        this._peerMessagesSubscription?.cancel();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this._buildAppBar(context),
            drawer: const DownloadsDrawer(),
            floatingActionButton: SPlatform.isDesktop && Settings.online ? this._buildSinkButton(context) : null,
            body: ListView(
                padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10),
                children: [
                    ResultCardRow(
                        title: "Continua a guardare",
                        values: Future.value(KeepWatching.metadata),
                        onTap: this._openMedia,
                        action: (metadata) => super.setState(() => KeepWatching.remove(metadata)),
                        actionIcon: Icons.delete,
                    ),
                    ResultCardRow(
                        title: "Ultime aggiunte",
                        values: Site.get(Settings.site)!.latests(),
                        onTap: (metadata) => this._openTitle(context, metadata),
                        action: Site.get(Settings.site)!.isLocal
                            ? (metadata) => this._delete(context, metadata)
                            : null,
                        actionIcon: Icons.delete,
                    ),
                    ResultCardRow(
                        title: "La mia lista",
                        values: Future.value(SavedTitles.getAll()),
                        onTap: (metadata) => this._openTitle(context, metadata),
                        action: (metadata) => super.setState(() => SavedTitles.remove(metadata)),
                        actionIcon: Icons.delete,
                    ),
                ]
            ),
        );
    }

    void _openMedia(TitleMetadata metadata) async {
        LoadingDialog.load(context, () async => await KeepWatching.getWatchable(metadata))
        .then((watchable) => Navigator.pushNamed(context, '/player', arguments: watchable).then((_) {
                if(super.mounted)
                    super.setState(() {});
            })
        );
    }

    void _delete(BuildContext context, TitleMetadata metadata) async {
        bool delete = await ConfirmationDialog.ask(context,
            "Elimina ${metadata.name}",
            "Sei sicuro di voler eliminare ${metadata.name}?",
            action: "Elimina"
        );
        if (delete) {
            await DownloadManager.delete(await Site.get(Settings.site)!.getTitle(metadata));
            super.setState(() {});
        }
    }

    void _openTitle(BuildContext context, TitleMetadata metadata) {
        Navigator.pushNamed(context, '/title', arguments: metadata).then((value) => super.setState(() {}));
    }
}
