import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/components/stronzflix_player/stronzflix_player.dart';

class MediaPage extends StatefulWidget {

    final Playable playable;
    const MediaPage({super.key, required this.playable});

    @override
    State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> with WidgetsBindingObserver {

    late final AppLifecycleListener _lifecycleListener;
    late Watchable _watchable;

    Future<void> _loadWatchable() async {
        this._watchable = await super.widget.playable.resolve();
    }

    void _saveState() {
        Backend.serialize();
    }

    @override
    void initState() {
        super.initState();

        WidgetsBinding.instance.addObserver(this);
        this._lifecycleListener = AppLifecycleListener(
            onStateChange: (_) => this._saveState,
            onExitRequested: () async { this._saveState(); return AppExitResponse.exit; }
        );

        PeerManager.registerHandler(PeerMessageIntent.stopWatching,
            (_) => Navigator.of(super.context).pop()
        );
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        this._lifecycleListener.dispose();
        this._saveState();
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
        if (state == AppLifecycleState.detached)
            this._saveState();
    }

    @override
    Widget build(BuildContext context) {
        return PopScope(
            onPopInvoked: (_) => this._saveState(),
            child: Scaffold(
                backgroundColor: Colors.black,
                body: FutureBuilder(
                    future: this._loadWatchable(),
                    builder: (context, snapshot) {
                        if(snapshot.hasError)
                            return const Icon(Icons.error);
                        else if(snapshot.connectionState != ConnectionState.done)
                            return const Center(child: CircularProgressIndicator());
                        else
                            return StronzflixPlayer(
                                media: this._watchable,
                            );
                    },
                )
            )
        );
    }
}
