import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/components/border_text.dart';
import 'package:uuid/uuid.dart';

enum PeerMessageIntent {
    message,
    seek,
    play,
    pause,
    startWatching,
    stopWatching;

    PeerMessageIntent fromString(String intent) {
        switch(intent) {
            case "seek": return PeerMessageIntent.seek;
            case "play": return PeerMessageIntent.play;
            case "pause": return PeerMessageIntent.pause;
            case "start_watching": return PeerMessageIntent.startWatching;
            case "stop_watching": return PeerMessageIntent.stopWatching;
            case "message": return PeerMessageIntent.message;
            default: throw Exception("Invalid intent");
        }
    }
}

class PeerManager {
    static late final Peer _peer;
    static DataConnection? _connection;

    static late final Function()? onConnect;
    static late final Function()? onDisconnect;
    static late Map<PeerMessageIntent, Function(Map<String, dynamic>)> intentHandlers;

    static String get id => _peer.id!;

    static bool get connected => PeerManager._connection != null;
    static bool _initialized = false;
    static bool get _ready => PeerManager._initialized && PeerManager.connected;
    static bool get _notReady => !PeerManager._ready;

    static void init({Function()? onConnect, Function()? onDisconnect}) {
        if(PeerManager._initialized)
            return;

        PeerManager._initialized = true;
        PeerManager.onConnect = onConnect;
        PeerManager.onDisconnect = onDisconnect;
        PeerManager.intentHandlers = {};

        Uuid uuid = const Uuid();
        PeerManager._peer = Peer(id: uuid.v4());

        PeerManager._peer.on<DataConnection>("connection").listen((event) {
            PeerManager._initConnection(event);
        });
    }

    static void registerHandler(PeerMessageIntent intent, Function(Map<String, dynamic>) handler) {
        if(!PeerManager._initialized)
            return;
        PeerManager.intentHandlers[intent] = handler;
    }

    static void _initConnection(dataConnection) {
        PeerManager._connection = dataConnection;

        PeerManager._connection!.on("open").listen((event) { 
            if(PeerManager.onConnect != null)
                PeerManager.onConnect!();
        });
        
        PeerManager._connection!.on("close").listen((event) { 
            if(PeerManager.onDisconnect != null)
                PeerManager.onDisconnect!();
            PeerManager._connection = null;
        });

        PeerManager._connection!.on("data").listen((data) {
            Map<String, dynamic> json = jsonDecode(data);
            PeerMessageIntent intent = PeerMessageIntent.startWatching.fromString(json["intent"]);
            Map<String, dynamic> message = json["data"];
            if(PeerManager.intentHandlers.containsKey(intent))
                PeerManager.intentHandlers[intent]!(message);
        });
    }

    static void connect(String peer) {
        if(peer == PeerManager.id)
            return;
        DataConnection dataConnection = PeerManager._peer.connect(peer);
        PeerManager._initConnection(dataConnection);
    }

    static void startWatching(SerialInfo serialInfo) {
        if(PeerManager._notReady)
            return;

        Map<String, dynamic> message = {
            "intent": "start_watching",
            "data": serialInfo.toJson()
        };
        String json = jsonEncode(message);
        PeerManager._connection!.send(json);
    }

    static void stopWatching() {
        if(PeerManager._notReady)
            return;

        Map<String, dynamic> message = {
            "intent": "stop_watching",
            "data": {}
        };
        String json = jsonEncode(message);
        PeerManager._connection!.send(json);
    }

    static void seek(int time) {
        if(PeerManager._notReady)
            return;

        Map<String, dynamic> message = {
            "intent": "seek",
            "data": {
                "time": time
            }
        };
        String json = jsonEncode(message);
        PeerManager._connection!.send(json);
    }

    static void pause() {
        if(PeerManager._notReady)
            return;

        Map<String, dynamic> message = {
            "intent": "pause",
            "data": {}
        };
        String json = jsonEncode(message);
        PeerManager._connection!.send(json);
    }

    static void play() {
        if(PeerManager._notReady)
            return;

        Map<String, dynamic> message = {
            "intent": "play",
            "data": {}
        };
        String json = jsonEncode(message);
        PeerManager._connection!.send(json);
    }

    static void sendMessage(String message) {
        if(PeerManager._notReady)
            return;

        Map<String, dynamic> msg = {
            "intent": "message",
            "data": {
                "message": message
            }
        };
        String json = jsonEncode(msg);
        PeerManager._connection!.send(json);
    }
}

enum MessageSender {
    local, peer
}

class Message {
    final MessageSender sender;
    final String message;
    final DateTime time;
    const Message({required this.sender, required this.message, required this.time});

    Widget toWidget() {
        return BorderText(
            builder: (style) => TextSpan(
                style: style?.copyWith(
                    color: Colors.white,
                    fontSize: 16
                ) ?? const TextStyle(
                    color: Colors.white,
                    fontSize: 16
                ),
                children: [
                    TextSpan(
                        text: this.sender == MessageSender.local ? "Tu: " : "Sinko: ",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold
                        )
                    ),
                    TextSpan(text: this.message),
                ]
            )
        );
    }
}
