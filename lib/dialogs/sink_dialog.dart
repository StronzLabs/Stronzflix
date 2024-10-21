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

    void _confirmConnection() {
        SinkManager.connect(PeerDevice(this._controller.text.trim()));
        Navigator.pop(context);
    }

    Widget _buildConnectView(BuildContext context) {
        return AlertDialog(
            title: const Text("Sinkplay"),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    OverflowBar(
                        children: [
                            const Text("Questo è il tuo ID: "),
                            SelectableText(
                                PeerInterface.currentId,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis
                                )
                            ),
                        ],
                    ),
                    TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                            labelText: "ID a cui connettersi"
                        ),
                        onSubmitted: (_) => this._confirmConnection(),
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
                    onPressed: this._confirmConnection,
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
                    onPressed: () async {
                        SinkManager.disconnect();
                        Navigator.of(context).pop();
                    },
                    child: const Text("Annulla")
                )
            ],
        );
    }

    void _connectionListener() {
        if (SinkManager.notifier.value == SinkConnectionState.connected)
            Navigator.of(context).pop();
    }

    @override
    void initState() {
        super.initState();
        SinkManager.notifier.addListener(this._connectionListener);
    }

    @override
    void dispose() {
        SinkManager.notifier.removeListener(this._connectionListener);
        this._controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return ListenableBuilder(
            listenable: SinkManager.notifier,
            builder: (context, _,) => switch(SinkManager.notifier.value) {
                SinkConnectionState.notConnected => this._buildConnectView(context),
                SinkConnectionState.connected => this._buildDisconnectView(context),
                SinkConnectionState.connecting => this._buildConnectingView(context),
            }
        );
    }
}
