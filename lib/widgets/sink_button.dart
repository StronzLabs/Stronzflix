import 'package:flutter/material.dart';
import 'package:stronzflix/backend/sink/sink_manager.dart';
import 'package:stronzflix/dialogs/sink_dialog.dart';

class SinkButton extends StatelessWidget {

    const SinkButton({
        super.key
    });

    @override
    Widget build(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: SinkManager.notifier,
            builder: (context, peerState, _) => FloatingActionButton(
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const SinkDialog()
                ),
                backgroundColor: peerState == SinkConnectionState.connected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
                child: Icon(peerState == SinkConnectionState.connecting
                    ? Icons.sync
                    : Icons.people
                )
            )
        );
    }
}
