import 'dart:async';

import 'package:cast/cast.dart';

class CastManager {

    final CastSession _session;
    final Map<int, Completer> _subscribedIds = {};
    void Function(Map<String, dynamic>)? _listener;
    int _id;

    CastManager._(this._session) : _id = 1 {
        this._session.messageStream.listen(this._messageHandler);
    }

    Future<Map<String, dynamic>> sendMessage(String namespace, Map<String, dynamic> payload) async {
        int id = this._id++;
        Completer c = Completer();
        payload["requestId"] = id;
        this._subscribedIds[id] = c;

        try {
            this._session.sendMessage(namespace, payload);
        } catch (_) {
            c.complete({"error": "Failed to send message"});
        }

        Map<String, dynamic> response = await c.future;
        this._subscribedIds.remove(id);
        return response;
    }

    void registerListener(void Function(Map<String, dynamic>) listener) {
        this._listener = listener;
    }

    Future<void> disconnect() async {
        await this._session.close();
    }

    void _messageHandler(Map<String, dynamic> message) {
        this._subscribedIds[message["requestId"]]?.complete(message);
        this._listener?.call(message);
    }

    static Future<CastManager> connect(CastDevice device) async {
        final CastSession session = await CastSessionManager().startSession(device);
        return CastManager._(session);
    }
}
