import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/sink/sink_manager.dart';
import 'package:stronzflix/backend/sink/sink_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/components/cast_button.dart';
import 'package:stronzflix/dialogs/settings_dialog.dart';
import 'package:stronzflix/dialogs/sink_dialog.dart';
import 'package:stronzflix/pages/home_page_desktop.dart';
import 'package:stronzflix/pages/home_page_mobile.dart';
import 'package:stronzflix/pages/home_page_tv.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'package:stronzflix/pages/search_page.dart';
import 'package:sutils/ui/dialogs/loading_dialog.dart';
import 'package:sutils/utils.dart';

class HomePage extends StatelessWidget {
    const HomePage({super.key});

    @override
    Widget build(BuildContext context) {
        if(EPlatform.isDesktop)
            return HomePageDesktop();
        else if(EPlatform.isMobile)
            return HomePageMobile();
        else if(EPlatform.isTV)
            return HomePageTV();
        
        throw Exception("Unsupported platform");
    }
}

abstract class HomePageState<T extends StatefulWidget> extends State<T> {

    late final StreamSubscription<Message>? _peerMessagesSubscription;
    AsyncMemoizer<List<TitleMetadata>> newsMemoizer = AsyncMemoizer();
    bool get _hasPeerConnectivity => EPlatform.isDesktop && Settings.online;

    @override
    void initState() {
        super.initState();
        this._peerMessagesSubscription = SinkMessenger.messages.listen((message) {
            if(message.type == MessageType.startWatching && super.mounted)
                LoadingDialog.load(super.context, () async {
                    SerialMetadata metadata = SerialMetadata.unserialize(jsonDecode(message.data!));
                    return await Watchable.unserialize(metadata.metadata, metadata.info);
                }).then((watchable) {
                    if(super.mounted)
                        Navigator.pushNamed(super.context, '/player-sink', arguments: PlayerPageArguments(watchable));
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

    void _refetchLocal() {
        if(!Settings.site.isLocal)
            return;

        this.refetchLatests();
    }

    void refetchLatests() {
        this.newsMemoizer = AsyncMemoizer();
        if(super.mounted)
            super.setState(() {});
    }

    PreferredSizeWidget _buildAppBar(BuildContext context) {
        return AppBar(
            title: const Text("Stronzflix"),
            leading: Padding(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset("assets/logo.svg"),
            ),
            actions: [
                const CastButton(),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const SettingsDialog()
                    ).then((_) => this.refetchLatests())
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

    Widget _buildSinkButton(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: SinkManager.notifier,
            builder: (context, peerState, _) => FloatingActionButton(
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const SinkDialog()
                ),
                backgroundColor: peerState == SinkConnectionState.connected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
                child: Icon(peerState == SinkConnectionState.connecting
                    ? Icons.sync
                    : Icons.people
                )
            )
        );
    }

    NavigationBar? buildBottomNavigationBar(BuildContext context) => null;
    Widget buildBody(BuildContext context);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this._buildAppBar(context),
            floatingActionButton: !this._hasPeerConnectivity ? null : this._buildSinkButton(context),
            bottomNavigationBar: this.buildBottomNavigationBar(context),
            body: this.buildBody(context),
        );
    }
}
