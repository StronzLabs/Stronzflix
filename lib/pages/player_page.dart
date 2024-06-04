import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';
import 'package:stronzflix/components/player/cast_view.dart';
import 'package:stronzflix/components/player/videoplayer_view.dart';

class PlayerPage extends StatefulWidget {
    const PlayerPage({super.key});

    @override
    State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
    
    late Watchable _watchable = ModalRoute.of(super.context)!.settings.arguments as Watchable;
    final PlayerInfo _playerInfo = PlayerInfo();
    AsyncMemoizer _memoizer = AsyncMemoizer();

    bool _exited = false;
    StreamSubscription<Message>? _peerMessagesSubscription;

    @override
    void initState() {
        super.initState();
        this._peerMessagesSubscription = PeerMessenger.messages.listen((message) {
            if (message.type == MessageType.stopWatching)
                if(super.mounted && !this._exited)
                    Navigator.of(super.context).pop();
        });
    }

    @override
    void dispose() {
        super.dispose();
        this._peerMessagesSubscription?.cancel();
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        
        this._playerInfo.startWatching(this._watchable);
        this._playerInfo.startCastDiscovery();
        int? timestamp = KeepWatching.getTimestamp(this._watchable);
        if (timestamp != null)
            this._playerInfo.setStartAt(Duration(seconds: timestamp));
    }

    @override
    Widget build(BuildContext context) {
        return PopScope(
            onPopInvoked: (_) => this._exitPlayer(),
            child: Scaffold(
                backgroundColor: Colors.black,
                body: ChangeNotifierProvider(
                    create: (context) => this._playerInfo,
                    child: Consumer<PlayerInfo>(
                        builder: (context, playerInfo, _) {
                            if (playerInfo.watchable != this._watchable) {
                                this._watchable = playerInfo.watchable;
                                this._memoizer = AsyncMemoizer();
                            }
                            return FutureBuilder(
                                future: this._memoizer.runOnce(
                                    () => playerInfo.watchable.player.getSource(playerInfo.watchable)
                                ),
                                builder: (context, snapshot) {
                                    if (snapshot.connectionState != ConnectionState.done)
                                        return const Center(child: CircularProgressIndicator());

                                    Uri uri = snapshot.data!;
                                    return Provider.of<PlayerInfo>(context).isCasting
                                            ? CastView(uri: uri)
                                            : VideoPlayerView(uri: uri);
                                },
                            );
                        }
                    ),
                )
            )
        );
    }

    void _exitPlayer() {
        this._exited = true;
        if(this._playerInfo.hasStarted)
            KeepWatching.add(this._playerInfo.watchable, this._playerInfo.timestamp, this._playerInfo.duration);
        PeerMessenger.stopWatching();
    }
}
