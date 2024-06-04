import 'dart:async';
import 'dart:convert';

import 'package:stronzflix/backend/peer/peer_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';

enum MessageType {
    chat("chat"),
    play("play"),
    pause("pause"),
    seek("seek"),
    startWatching("start_watching"),
    stopWatching("stop_watching");

    final String value;
    const MessageType(this.value);

    @override
    String toString() => this.value;

    static MessageType fromString(String value) {
        return switch (value) {
            "chat" => MessageType.chat,
            "play" => MessageType.play,
            "pause" => MessageType.pause,
            "seek" => MessageType.seek,
            "start_watching" => MessageType.startWatching,
            "stop_watching" => MessageType.stopWatching,
            _ => throw ArgumentError("Invalid message type")
        };
    }
}

class Message {
    final MessageType type;
    final String? data;

    const Message(this.type, this.data);
}

class PeerMessenger {

    static final StreamController<Message> _messagesController = StreamController<Message>.broadcast();
    static Stream<Message> get messages => PeerMessenger._messagesController.stream;

    static List<(bool, String)> _chatHistory = [];
    static List<(bool, String)> get chatHistory => List.unmodifiable(PeerMessenger._chatHistory);

    static Future<void> sendMessage(MessageType type, [String? data]) {
        return PeerManager.send(jsonEncode({
            "type": type.toString(),
            "data": data
        }));
    }

    static void handleMessage(String message) {
        dynamic json = jsonDecode(message);
        MessageType type = MessageType.fromString(json["type"]);
        String? data = json["data"];

        if(type == MessageType.chat)
            PeerMessenger._chatHistory.add((false, data!));

        PeerMessenger._messagesController.add(Message(type, data));
    }

    static Future<void> startWatching(SerialMetadata metadata)
        => PeerMessenger.sendMessage(MessageType.startWatching, jsonEncode(metadata.serialize()));

    static Future<void> stopWatching()
        => PeerMessenger.sendMessage(MessageType.stopWatching);

    static Future<void> play()
        => PeerMessenger.sendMessage(MessageType.play);

    static Future<void> pause()
        => PeerMessenger.sendMessage(MessageType.pause);

    static Future<void> seek(int position)
        => PeerMessenger.sendMessage(MessageType.seek, position.toString());

    static Future<void> chat(String message) {
        PeerMessenger._chatHistory.add((true, message));
        return PeerMessenger.sendMessage(MessageType.chat, message);
    }
}
