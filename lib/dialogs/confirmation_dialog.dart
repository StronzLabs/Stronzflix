import 'dart:async';

import 'package:flutter/material.dart';

class ConfirmationDialog {
    static Future<bool> ask(BuildContext context, String title, String content, {String action = "Conferma"}) async {
        return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Annulla")
                    ),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(action)
                    )
                ],
            )
        ) ?? false;
    }
}
