import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stronzflix/backend/sink/sink_messenger.dart';
import 'package:stronzflix/components/border_text.dart';

class ChatDrawer extends StatefulWidget {
    const ChatDrawer({super.key});

    @override
    State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
    
    final TextEditingController _textController = TextEditingController();
    final ScrollController _scrollController = ScrollController();
    StreamSubscription<Message>? _subscription;
    final FocusNode _focusNode = FocusNode();

    @override
    void initState() {
        super.initState();
        this._subscription = SinkMessenger.messages.listen((message) {
            if(message.type == MessageType.chat)
                super.setState(this._scrollList);
        });
    }

    @override
    void dispose() {
        this._subscription?.cancel();
        this._textController.dispose();
        this._focusNode.dispose();
        super.dispose();
    }

    Widget _buildMessage(String message, bool isLocal) {
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
                        text: isLocal ? "Tu: " : "Sinko: ",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold
                        )
                    ),
                    TextSpan(text: message),
                ]
            )
        );
    }

    void _sendMessage() {
        SinkMessenger.chat(this._textController.text.trim());
        this._textController.clear();
        this._focusNode.requestFocus();
        super.setState(this._scrollList);
    }

    void _scrollList() {
        this._scrollController.animateTo(
            this._scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut
        );
    }

    @override
    Widget build(BuildContext context) {
        return Drawer(
            backgroundColor: const Color.fromARGB(200, 18, 18, 18),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20)
                )
            ),
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Expanded(
                            child: ListView.builder(
                                controller: this._scrollController,
                                itemCount: SinkMessenger.chatHistory.length,
                                itemBuilder: (context, i) => this._buildMessage(
                                    SinkMessenger.chatHistory[i].$2,
                                    SinkMessenger.chatHistory[i].$1
                                ),
                                prototypeItem: this._buildMessage(
                                    "Lorem ipsum",
                                    false
                                ),
                            ),
                        ),
                        TextField(
                            controller: this._textController,
                            focusNode: this._focusNode,
                            autofocus: true,
                            decoration: InputDecoration(
                                suffix: IconButton(
                                    icon: const Icon(Icons.send, size: 20),
                                    onPressed: () => this._sendMessage()
                                )
                            ),
                            onSubmitted: (_) => this._sendMessage(),
                        ),
                    ],
                ),
            )
        );
    }
}
