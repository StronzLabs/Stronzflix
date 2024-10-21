import 'package:flutter/material.dart';
import 'package:stronzflix/backend/sink/peer.dart';
import 'package:stronzflix/backend/sink/sink_manager.dart';

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
                                    text: PeerInterface.currentId,
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
                            SinkManager.connect(PeerDevice(value.trim()));
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
                        SinkManager.connect(PeerDevice(this._controller.text.trim()));
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
                        SinkManager.disconnect();
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
                        SinkManager.disconnect();
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

        if(SinkManager.connected && this._state != SinkManager.connected)
            Navigator.of(context).pop();
        else if (SinkManager.connecting && this._state != SinkManager.connecting)
            super.setState(() => this._state = SinkManager.notifier.value);
        else if (!SinkManager.connected && !SinkManager.connecting && this._state != SinkConnectionState.notConnected)
            super.setState(() => this._state = SinkManager.notifier.value);
    }

    SinkConnectionState _state = SinkManager.notifier.value;

    @override
    void initState() {
        super.initState();
        SinkManager.notifier.addListener(this._updateListener);
    }

    @override
    void dispose() {
        SinkManager.notifier.removeListener(this._updateListener);
        this._controller.dispose();
        this._focusNode.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return switch(this._state) {
            SinkConnectionState.notConnected=> this._buildConnectView(context),
            SinkConnectionState.connected=> this._buildDisconnectView(context),
            SinkConnectionState.connecting=> this._buildConnectingView(context),
        };
    }
}
