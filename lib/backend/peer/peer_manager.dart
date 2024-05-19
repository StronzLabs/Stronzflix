import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:uuid/uuid.dart';

enum PeerConnectionState {
    connected,
    notConnected,
    connecting
}

sealed class PeerManager {
    PeerManager._();

    static late final Peer _peer;
    static String get id => _peer.id!;
    static DataConnection? _connection;

    static final ValueNotifier<PeerConnectionState> notifier = ValueNotifier(PeerConnectionState.notConnected);

    static bool get connected => PeerManager.notifier.value == PeerConnectionState.connected;
    static bool get connectionInProgress => PeerManager.notifier.value == PeerConnectionState.connecting;

    static Future<void> init() async {
        Uuid uuid = const Uuid();
        PeerManager._peer = Peer(
            id: uuid.v4(),
            // options: PeerOptions(
            //     host: "1.peerjs.com"
            // )   
        );

        PeerManager._peer.on<DataConnection>("connection").listen(
            (event) => PeerManager._initConnection(event)
        );
    }

    static void connect(String peer) {
        if(peer == PeerManager.id)
            return;
        DataConnection dataConnection = PeerManager._peer.connect(peer);
        PeerManager._initConnection(dataConnection);
    }

    static void disconnect() {
        PeerManager._connection?.close();
        PeerManager._connection = null;
        PeerManager.notifier.value = PeerConnectionState.notConnected;
    }

    static Future<void> send(String message) async {
        await PeerManager._connection?.send(message);
    }

    static void _initConnection(DataConnection dataConnection) {
        PeerManager._connection = dataConnection;
        PeerManager.notifier.value = PeerConnectionState.connecting;

        PeerManager._connection!.on("open").listen((event) {
            PeerManager.notifier.value = PeerConnectionState.connected;
        });

        PeerManager._connection!.on("close").listen(
            (event) => PeerManager.disconnect()
        );

        PeerManager._connection!.on("error").listen(
            (event) => PeerManager.disconnect()
        );

        PeerManager._connection!.on("data").listen(
            (event) => PeerMessenger.handleMessage(event)
        );
    }
}
