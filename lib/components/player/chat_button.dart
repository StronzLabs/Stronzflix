import 'package:flutter/material.dart';
import 'package:stronzflix/backend/peer/peer_manager.dart';
import 'package:stronzflix/components/player/chat_drawer.dart';

class ChatButton extends StatelessWidget {
    const ChatButton({
        super.key
    });

    void _showChat(BuildContext context) {
        showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
            barrierColor: Colors.transparent,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (buildContext, animation, secondaryAnimation) => const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: ChatDrawer(),
                ),
            ),
            transitionBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
                    position: animation.drive(Tween(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero
                    ).chain(CurveTween(
                        curve: Curves.easeInOut
                    ))
                ),
                child: child,
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        if(!PeerManager.connected)
            return const SizedBox.shrink();

        return IconButton(
            icon: const Icon(Icons.chat),
            iconSize: 28,
            onPressed: () => this._showChat(context),
        );
    }
}
