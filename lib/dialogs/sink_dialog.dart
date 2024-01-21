import 'package:flutter/material.dart';
import 'package:stronzflix/backend/peer_manager.dart';

class SinkDialog extends StatelessWidget {
    
    final TextEditingController _controller = TextEditingController();
    
    SinkDialog({super.key});

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("SinkPlay"),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    SelectableText.rich(
                        TextSpan(
                            children: [
                                const TextSpan(
                                    text: "Questo è il tuo ID: "
                                ),
                                TextSpan(
                                    text: PeerManager.id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                            ]
                        )
                    ),
                    TextField(
                        decoration: const InputDecoration(
                            labelText: "ID a cui connettersi"
                        ),
                        onSubmitted: (value) {
                            PeerManager.connect(value);
                            Navigator.pop(context);
                        },
                        controller: this._controller,
                    )
                ],
            ),
            actions: [
                TextButton(
                    onPressed: () {
                        PeerManager.connect(this._controller.text);
                        Navigator.pop(context);
                    },
                    child: const Text("Connetti")
                )
            ]
        );
    }
}
