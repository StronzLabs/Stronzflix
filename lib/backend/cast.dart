import 'dart:async';

import 'package:cast/cast.dart';

class CastManager {

    static List<CastDevice> _devices = [];
    static final StreamController<List<CastDevice>> _devicesController = StreamController.broadcast();
    static final Stream<List<CastDevice>> devicesStream = CastManager._devicesController.stream;
    static List<CastDevice> get devices => CastManager._devices;

    static bool _discovering = false;
    static final StreamController<bool> _discoveringController = StreamController.broadcast();
    static final Stream<bool> discoveringStream = CastManager._discoveringController.stream;
    static bool get discovering => CastManager._discovering;

    static bool _connected = false;
    static final StreamController<bool> _connectedController = StreamController.broadcast();
    static final Stream<bool> connectedStream = CastManager._connectedController.stream;
    static bool get connected => CastManager._connected;

    static bool _connecting = false;
    static final StreamController<bool> _connectingController = StreamController.broadcast();
    static final Stream<bool> connectingStream = CastManager._connectingController.stream;
    static bool get connecting => CastManager._connecting;

    static CastSession? _session;
    static final Map<int, Completer> _subscribedIds = {};
    static int _messageId = 1;

    static Future<void> startDiscovery() async {
        CastManager._discoveringController.add(CastManager._discovering = true);
        List<CastDevice> devices = await CastDiscoveryService().search();
        CastManager._devicesController.add(CastManager._devices = devices);
        CastManager._discoveringController.add(CastManager._discovering = false);
    }

    static Future<void> connect(CastDevice device) async {
        CastManager._connectingController.add(CastManager._connecting = true);
        
        try {
            CastManager._session = await CastSessionManager().startSession(device);
            CastManager._session!.messageStream.listen(
                (message) => CastManager._subscribedIds[message["requestId"]]?.complete(message)
            );
            CastManager._session!.stateStream.listen(
                (state) {
                    if(state == CastSessionState.closed)
                        CastManager.disconnect();
                }
            );

            Map<String, dynamic> status = await CastManager.sendMessage(CastSession.kNamespaceReceiver, {
                'type': 'LAUNCH',
                'appId': 'CC1AD845',
            });

            bool succesfullyLaunched = status["status"]["applications"]?.any((app) => app["appId"] == "CC1AD845") ?? false;

            CastManager._connectingController.add(CastManager._connecting = false);
            CastManager._connectedController.add(CastManager._connected = true);

            if(!succesfullyLaunched)
                await CastManager.disconnect();
        } catch (_) {
            CastManager._connectingController.add(CastManager._connecting = false);
            CastManager._connectedController.add(CastManager._connected = false);
        }
    }

    static Future<void> disconnect() async {
        try {
            await CastManager._session?.close();
        } catch (_) {}
        CastManager._session = null;
        CastManager._connectedController.add(CastManager._connected = false);
    }

    static Future<Map<String, dynamic>> sendMessage(String namespace, Map<String, dynamic> payload) async {
        int id = CastManager._messageId++;
        Completer c = Completer();
        payload["requestId"] = id;
        CastManager._subscribedIds[id] = c;

        try {
            CastManager._session?.sendMessage(namespace, payload);
        } catch (_) {
            c.complete({"error": "Failed to send message"});
        }

        Map<String, dynamic> response = await c.future;
        CastManager._subscribedIds.remove(id);
        return response;
    }
}
