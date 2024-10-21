import 'dart:async';

import 'package:peerdart/peerdart.dart';
import 'package:stronzflix/backend/sink/sink_manager.dart';
import 'package:uuid/uuid.dart';

class PeerDevice extends SinkDevice {
    final String id;

    const PeerDevice(this.id);
}

class PeerInterface extends SinkInterface {

    static late String _currentId;
    static String get currentId => PeerInterface._currentId;
    
    late Peer _peer;
    String get id => this._peer.id!;
    DataConnection? _connection;

    PeerInterface(super.onMessageReceived, super.onRemoteConnection);

    @override
    Future<void> init() async {
        Uuid uuid = const Uuid();
        this._peer = Peer(
            id: uuid.v4(),
        );

        this._peer.on<DataConnection>("connection").listen(
            (event) async {
                await this._initConnection(event);
                await super.onRemoteConnection(this);
            }
        );

        PeerInterface._currentId = this.id;
    }

    @override
    Future<void> connect(SinkDevice device) async {
        if(device is! PeerDevice)
            return;
        if(device.id == this.id)
            return;
        
        DataConnection dataConnection = this._peer.connect(device.id);
        await this._initConnection(dataConnection);
    }

    @override
    Future<void> disconnect() async {
        this._connection?.close();
        this._connection = null;
    }

    @override
    Future<List<SinkDevice>> discoverNearDevices() => Future.value([]);

    @override
    Future<void> sendMessage(String message) async {
        await this._connection?.send(message);
    }

    Future<void> _initConnection(DataConnection dataConnection) {
        this._connection = dataConnection;

        Completer<void> completer = Completer();

        this._connection!.on("open").listen((event) {
            completer.complete();
        });

        this._connection!.on("close").listen(
            (event) => this.disconnect()
        );

        this._connection!.on("error").listen(
            (event) => this.disconnect()
        );

        this._connection!.on("data").listen(
            (event) => super.onMessageReceived(event)
        );

        return completer.future;
    }
}