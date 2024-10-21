import 'package:flutter/material.dart';
import 'package:stronzflix/backend/sink/peer.dart';
import 'package:stronzflix/backend/sink/sink_messenger.dart';

class SinkDevice {    
    const SinkDevice();
}

enum SinkConnectionState {
    connected,
    notConnected,
    connecting
}

abstract class SinkInterface {
    final void Function(String) onMessageReceived;
    final Future<void> Function(SinkInterface) onRemoteConnection;

    const SinkInterface(this.onMessageReceived, this.onRemoteConnection);
    Future<void> init();

    Future<List<SinkDevice>> discoverNearDevices();
    Future<void> connect(SinkDevice device);
    Future<void> disconnect();

    Future<void> sendMessage(String message);
}

class SinkManager {
    static final ValueNotifier<SinkConnectionState> notifier = ValueNotifier(SinkConnectionState.notConnected);
    static SinkConnectionState get state => SinkManager.notifier.value;
    static set state(SinkConnectionState value) => SinkManager.notifier.value = value;
    static bool get connected => SinkManager.notifier.value == SinkConnectionState.connected;
    static bool get connecting => SinkManager.notifier.value == SinkConnectionState.connecting;

    static final List<SinkInterface> _interfaces = [
        PeerInterface(SinkManager._onMessageReceived, SinkManager._onRemoteConnection),
    ];

    static SinkInterface? _activeInterface;

    static Future<void> init() async {
        for(SinkInterface interface in SinkManager._interfaces)
            await interface.init();
    }

    static Future<void> connect(SinkDevice device) async {
        SinkManager.state = SinkConnectionState.connecting;

        switch (device.runtimeType) {
            case PeerDevice:
                SinkManager._activeInterface = SinkManager._interfaces.firstWhere((element) => element is PeerInterface);
                break;
            default:
                throw UnimplementedError();
        }

        await SinkManager._activeInterface!.connect(device);
        SinkManager.state = SinkConnectionState.connected;
    }

    static Future<void> _onRemoteConnection(SinkInterface interface) async {
        await SinkManager._activeInterface?.disconnect();
        SinkManager._activeInterface = interface;
        SinkManager.state = SinkConnectionState.connected;
    }

    static Future<void> disconnect() async {
        await SinkManager._activeInterface?.disconnect();
        SinkManager.state = SinkConnectionState.notConnected;
    }

    static Future<List<SinkDevice>> discoverNearDevices() async {
        return [];
    }

    static Future<void> sendMessage(String message) async {
        await SinkManager._activeInterface?.sendMessage(message);
    }

    static void _onMessageReceived(String message) {
        SinkMessenger.handleMessage(message);
    }
}
