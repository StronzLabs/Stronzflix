import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/backend/version.dart';
import 'package:stronzflix/components/card_row.dart';
import 'package:stronzflix/pages/title_page.dart';
import 'package:stronzflix/stronzflix.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:stronzflix/backend/storage.dart';
import 'package:stronzflix/dialogs/info_dialog.dart';
import 'package:stronzflix/pages/media_page.dart';
import 'package:stronzflix/pages/search_page.dart';
import 'package:stronzflix/dialogs/sink_dialog.dart';
import 'package:stronzflix/dialogs/update_dialog.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {

    late bool _connected;

    void _playSerialMedia(BuildContext context, SerialInfo serialInfo) {
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => MediaPage(
                playable: LatePlayable(serialInfo: serialInfo)
            )
        ));
    }

    void _showInfo(BuildContext context) {
        showDialog(
            context: context,
            builder: (context) => const InfoDialog()
        );
    }

    void _checkVersion() async {
        if(SPlatform.isMobile)
            await VersionChecker.cleanCache();
        if(!await VersionChecker.shouldUpdate())
            return;

        // ignore: use_build_context_synchronously
        showDialog(
            context: super.context,
            builder: (context) => const UpdateDialog()
        );
    }

    void _showSink(BuildContext context) {
        showDialog(
            context: context,
            builder: (context) => SinkDialog()
        );
    }

    AppBar _buildSearchBar(BuildContext context) {
        return AppBar(
            title: const Text("Stronzflix"),
            leading: IconButton(
                icon: const Icon(Icons.info_outlined),
                onPressed: () => this._showInfo(context)
            ),
            actions: [
                Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => showSearch(
                            context: context,
                            delegate: SearchPage()
                        )
                    )
                )
            ]
        );        
    }

    Widget _buildContent(BuildContext context) {
        return ListView(
            padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10),
            children: [
                CardRow(
                    title: "Continua a guardare",
                    values: Future.value(Storage.keepWatching.values),
                    onTap: (serialInfo) {
                        Backend.startWatching(serialInfo.site, serialInfo.siteUrl, episode: serialInfo.episode);
                        this._playSerialMedia(context, serialInfo);
                    },
                    onLongPress: (serialInfo) {
                        super.setState(() {
                            Backend.removeWatching(serialInfo.site, serialInfo.siteUrl);
                            Backend.serialize();
                        });
                    },
                ),
                CardRow(
                    title: "Ultime aggiunte",
                    values: Site.get("StreamingCommunity")!.latests(),
                    onTap: (result) => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => TitlePage(
                            result: result
                        )
                    ))
                )
            ]
        );
    }

    void _initPeer() {
        this._connected = false;

        PeerManager.init(
            onConnect: () => super.setState(() => this._connected = true),
            onDisconnect: () => super.setState(() => this._connected = false)
        );

        PeerManager.registerHandler(
            PeerMessageIntent.startWatching,
            (data) {
                SerialInfo serialInfo = SerialInfo.fromJson(data);
                this._playSerialMedia(super.context, serialInfo);
            }
        );
    }

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) => this._checkVersion());
        this._initPeer();
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        Stronzflix.routeObserver.subscribe(this, ModalRoute.of(context)!);
    }

    @override
    void dispose() {
        Stronzflix.routeObserver.unsubscribe(this);
        super.dispose();
    }

    @override
    void didPopNext() {
        Future.delayed(const Duration(seconds: 1), () => super.setState(() {}));
    }

    Widget _buildSinkButton(BuildContext context) {
        return FloatingActionButton(
            backgroundColor: this._connected ?
                Theme.of(context).colorScheme.primary :
                Theme.of(context).disabledColor,
            child: const Icon(Icons.people),
            onPressed: () => this._showSink(context)
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this._buildSearchBar(context),
            body: this._buildContent(context),
            floatingActionButton: SPlatform.isDesktop ? this._buildSinkButton(context) : null
        );
    }
}
