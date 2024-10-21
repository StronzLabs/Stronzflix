import 'dart:async';
import 'dart:convert';

import 'package:stronzflix/backend/sink/sink_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';

enum MessageType {
    play("play"),
    pause("pause"),
    buffering("buffering"),
    ready("ready"),
    chat("chat"),
    seek("seek"),
    startWatching("start_watching"),
    stopWatching("stop_watching");

    final String value;
    const MessageType(this.value);

    @override
    String toString() => this.value;

    static MessageType fromString(String value) {
        return switch (value) {
            "play" => MessageType.play,
            "pause" => MessageType.pause,
            "buffering" => MessageType.buffering,
            "ready" => MessageType.ready,
            "chat" => MessageType.chat,
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

class SinkMessenger {

    static final StreamController<Message> _messagesController = StreamController<Message>.broadcast();
    static Stream<Message> get messages => SinkMessenger._messagesController.stream;

    static List<(bool, String)> _chatHistory = [];
    static List<(bool, String)> get chatHistory => List.unmodifiable(SinkMessenger._chatHistory);

    static Future<void> sendMessage(MessageType type, [String? data]) {
        return SinkManager.sendMessage(jsonEncode({
            "type": type.toString(),
            "data": data
        }));
    }

    static void handleMessage(String message) {
        dynamic json = jsonDecode(message);
        MessageType type = MessageType.fromString(json["type"]);
        String? data = json["data"];

        if(type == MessageType.chat)
            SinkMessenger._chatHistory.add((false, data!));

        SinkMessenger._messagesController.add(Message(type, data));
    }

    static Future<void> startWatching(SerialMetadata metadata)
        => SinkMessenger.sendMessage(MessageType.startWatching, jsonEncode(metadata.serialize()));

    static Future<void> stopWatching()
        => SinkMessenger.sendMessage(MessageType.stopWatching);

    static Future<void> play()
        => SinkMessenger.sendMessage(MessageType.play);

    static Future<void> pause()
        => SinkMessenger.sendMessage(MessageType.pause);

    static Future<void> buffering()
        => SinkMessenger.sendMessage(MessageType.buffering);

    static Future<void> ready()
        => SinkMessenger.sendMessage(MessageType.ready);

    static Future<void> seek(int position)
        => SinkMessenger.sendMessage(MessageType.seek, position.toString());

    static Future<void> buffer()
        => SinkMessenger.sendMessage(MessageType.buffering);

    static Future<void> chat(String message) {
        SinkMessenger._chatHistory.add((true, message));
        return SinkMessenger.sendMessage(MessageType.chat, message);
    }
}
