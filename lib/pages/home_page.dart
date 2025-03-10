import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stronz_cast/ui/stronz_cast_button.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/sink/sink_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/pages/home_page_desktop.dart';
import 'package:stronzflix/pages/home_page_mobile.dart';
import 'package:stronzflix/pages/home_page_tv.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'package:stronzflix/widgets/search_button.dart';
import 'package:stronzflix/widgets/settings_button.dart';
import 'package:stronzflix/widgets/sink_button.dart';
import 'package:sutils/ui/dialogs/loading_dialog.dart';
import 'package:sutils/ui/widgets/tv_traversable.dart';
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
                TvTraversable(
                    child: Row(
                        children: [
                            const StronzCastButton(),
                            const SizedBox(width: 8),
                            SettingsButton(onClosed: () => this.refetchLatests()),
                            const SizedBox(width: 8),
                            const SearchButton(),
                            const SizedBox(width: 8),
                        ]
                    )
                )
            ]
        );        
    }

    NavigationBar? buildBottomNavigationBar(BuildContext context) => null;
    Widget buildBody(BuildContext context);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this._buildAppBar(context),
            floatingActionButton: this._hasPeerConnectivity ? const SinkButton() : null,
            bottomNavigationBar: this.buildBottomNavigationBar(context),
            body: this.buildBody(context),
        );
    }
}
