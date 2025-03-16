import 'package:flutter/material.dart';
import 'package:sutils/ui/widgets/bordered_text.dart';

sealed class NotificationOverlay {

    static void show(BuildContext context, String text, {Duration duration = const Duration(seconds: 2)}) {
        OverlayEntry overlay = NotificationOverlay._buildNotificationOverlay(context, text);
        Overlay.of(context).insert(overlay);
        Future.delayed(duration, () => overlay.remove());
    }

    static OverlayEntry _buildNotificationOverlay(BuildContext context, String message) {
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
                            child: BorderedText(
                                text: message,
                                textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16
                                )
                            )
                        )
                    )
                )
            )
        );
    }
}