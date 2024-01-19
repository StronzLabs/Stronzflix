import 'package:flutter/material.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/backend/version.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:stronzflix/backend/storage.dart';
import 'package:stronzflix/views/info_dialog.dart';
import 'package:stronzflix/views/media.dart';
import 'package:stronzflix/views/search.dart';
import 'package:stronzflix/views/sink_dialog.dart';
import 'package:stronzflix/views/update_dialog.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    late bool _connected;

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
            builder: (context) => const SinkDialog()
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
                        ).then((value) => super.setState(() {}))
                    )
                )
            ]
        );        
    }

    void _removeMedia(SerialInfo serialInfo) {
        super.setState(() => Storage.removeWatching(serialInfo: serialInfo));
    }

    Widget _buildContent(BuildContext context) {
        if(Storage.keepWatching.isEmpty)
            return const Center(
                child: Text("Non hai ancora iniziato a guardare nulla")
            );
        else
            return GridView.extent(
                childAspectRatio: 3 / 2,
                maxCrossAxisExtent: 400,
                children: Storage.keepWatching.values.map(
                    (serialInfo) => ResultCard(
                        imageUrl: serialInfo.cover,
                        text: serialInfo.name,
                        onTap: () => MediaPage.playMedia(context, serialInfo),
                        onLongPress: () => this._removeMedia(serialInfo)
                    )
                ).toList(),
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
                MediaPage.playMedia(super.context, serialInfo, peer: false);
            }
        );
    }

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) => this._checkVersion());
        this._initPeer();
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
            body: Center(
                child: this._buildContent(context)
            ),
            floatingActionButton: SPlatform.isDesktop ? this._buildSinkButton(context) : null
        );
    }
}
