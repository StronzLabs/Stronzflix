import 'package:flutter/material.dart';
import 'package:stronzflix/backend/peer_manager.dart';
import 'package:stronzflix/components/border_text.dart';

class ChatDrawer extends StatefulWidget {
    
    final bool shown;
    const ChatDrawer({super.key, required this.shown});

    @override
    State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> with SingleTickerProviderStateMixin {

    late final AnimationController _animationController;
    late final Animation<Offset> _animation;

    late final TextEditingController _textEditingController;
    late final List<Message> _messages;

    @override
    void initState() {
        super.initState();

        this._animationController = AnimationController(
            vsync: this,
            value: super.widget.shown ? 1 : 0,
            duration: const Duration(milliseconds: 200),
        );
        this._animation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: const Offset(0, 0)
        ).animate(CurvedAnimation(
            parent: this._animationController,
            curve: Curves.easeInOut
        ));

        this._textEditingController = TextEditingController();

        this._messages = [];

        PeerManager.registerHandler(PeerMessageIntent.message, (msg) {
            super.setState(() {
                this._messages.add(Message(
                    sender: MessageSender.peer,
                    message: msg["message"],
                    time: DateTime.now())
                );
            });

            if(!super.widget.shown) {
                OverlayEntry overlay = this._buildNotificationOverlay(context, msg["message"]);
                Overlay.of(context).insert(overlay);
                Future.delayed(const Duration(seconds: 2), () => overlay.remove());
            }
        });
    }

    OverlayEntry _buildNotificationOverlay(BuildContext context, String message) {
        return OverlayEntry(
            builder: (context) => Align(
                alignment: Alignment.topCenter,
                child: Padding(
                    padding: const EdgeInsets.only(top: 32, left: 32, right: 32),
                    child: Container(
                        decoration: const BoxDecoration(
                            color: Color.fromARGB(200, 18, 18, 18),
                            borderRadius: BorderRadius.all(Radius.circular(20))
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: BorderText(
                                builder: (style) => TextSpan(
                                    style: style?.copyWith(
                                        color: Colors.white,
                                        fontSize: 16
                                    ) ?? const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16
                                    ),
                                    text: message
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    @override
    void didUpdateWidget(ChatDrawer oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (super.widget.shown != oldWidget.shown) {
            if (super.widget.shown)
                this._animationController.forward();
            else
                this._animationController.reverse();
        }
    }

    void _sendMessage() {
        String message = this._textEditingController.text.trim();
        this._textEditingController.text = "";
        if(message.isEmpty)
            return;

        super.setState(() {
            this._messages.add(Message(
                sender: MessageSender.local,
                message: message,
                time: DateTime.now())
            );
        });
        PeerManager.sendMessage(message);
    }

    Widget _buildChat(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Expanded(
                    child: ListView(
                        children: this._messages.map((message) => message.toWidget()).toList(),
                    )
                ),
                TextField(
                    controller: this._textEditingController,
                    decoration: InputDecoration(
                        suffix: IconButton(
                            icon: const Icon(Icons.send, size: 20),
                            onPressed: () => this._sendMessage()
                        )
                    ),
                    onSubmitted: (_) => this._sendMessage(),
                ),
            ],
        );
    }

    @override
    Widget build(BuildContext context) {
        return SlideTransition(
            position: this._animation,
            child: Padding(
                padding: const EdgeInsets.only(
                    top: 55,
                    bottom: 100
                ),
                child: Drawer(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20)
                        )
                    ),
                    child: Padding(
                        padding: const EdgeInsets.only(
                            top: 10,
                            left: 10,
                            right: 10,
                            bottom: 20
                        ),
                        child: this._buildChat(context),
                    ),
                )
            )
        );
    }
}