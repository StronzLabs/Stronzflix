import 'package:flutter/material.dart';
import 'package:stronzflix/dialogs/settings_dialog.dart';

class SettingsButton extends StatelessWidget {

    final void Function()? onClosed;

    const SettingsButton({
        super.key,
        this.onClosed
    });

    @override
    Widget build(BuildContext context) {
        return IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showDialog(
                context: context,
                builder: (context) => const SettingsDialog()
            ).then((_) => this.onClosed?.call())
        );
    }
}