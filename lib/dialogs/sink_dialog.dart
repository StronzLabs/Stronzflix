import 'package:flutter/material.dart';
import 'package:stronzflix/backend/peer/peer_manager.dart';

class SinkDialog extends StatefulWidget {

    const SinkDialog({
        super.key
    });

    @override
    State<SinkDialog> createState() => _SinkDialogState();
}

class _SinkDialogState extends State<SinkDialog> {
    final TextEditingController _controller = TextEditingController();
    final FocusNode _focusNode = FocusNode();

    Widget _buildConnectView(BuildContext context) {
        return AlertDialog(
            title: const Text("Sinkplay"),
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
                        autofocus: true,
                        focusNode: this._focusNode,
                        decoration: const InputDecoration(
                            labelText: "ID a cui connettersi"
                        ),
                        onSubmitted: (value) {
                            PeerManager.connect(value.trim());
                            Navigator.pop(context);
                        },
                        controller: this._controller,
                    )
                ],
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Chiudi")
                ),
                TextButton(
                    onPressed: () {
                        PeerManager.connect(this._controller.text.trim());
                        Navigator.of(context).pop();
                    },
                    child: const Text("Connetti")
                )
            ],
        );
    }

    Widget _buildDisconnectView(BuildContext context) {
        return AlertDialog(
            title: const Text("Sinkplay"),
            content: const Text("La connessione è già stata stabilita."),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Chiudi")
                ),
                TextButton(
                    onPressed: () {
                        PeerManager.disconnect();
                        Navigator.of(context).pop();
                    },
                    child: const Text("Disconnetti")
                )
            ],
        );
    }

    Widget _buildConnectingView(BuildContext context) {
        return AlertDialog(
            title: const Text("Sinkplay"),
            content: const Text("Un tentativo di connessone è ancora in corso. Vuoi annulare?"),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Chiudi")
                ),
                TextButton(
                    onPressed: () {
                        PeerManager.disconnect();
                        Navigator.of(context).pop();
                    },
                    child: const Text("Annulla")
                )
            ],
        );
    }

    void _updateListener() {
        if(!super.mounted)
            return;

        if(PeerManager.connected && this._state != PeerConnectionState.connected)
            Navigator.of(context).pop();
        else if (PeerManager.connectionInProgress && this._state != PeerConnectionState.connecting)
            super.setState(() => this._state = PeerManager.notifier.value);
        else if (!PeerManager.connected && !PeerManager.connectionInProgress && this._state != PeerConnectionState.notConnected)
            super.setState(() => this._state = PeerManager.notifier.value);
    }

    PeerConnectionState _state = PeerManager.notifier.value;

    @override
    void initState() {
        super.initState();
        PeerManager.notifier.addListener(this._updateListener);
    }

    @override
    void dispose() {
        PeerManager.notifier.removeListener(this._updateListener);
        this._controller.dispose();
        this._focusNode.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return switch(this._state) {
            PeerConnectionState.notConnected=> this._buildConnectView(context),
            PeerConnectionState.connected=> this._buildDisconnectView(context),
            PeerConnectionState.connecting=> this._buildConnectingView(context),
        };
    }
}
