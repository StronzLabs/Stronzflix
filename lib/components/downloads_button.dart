import 'package:flutter/material.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/components/animated_gradient_icon.dart';

class DownloadsButton extends StatelessWidget {
    const DownloadsButton({super.key});

    @override
    Widget build(BuildContext context) {
        return IconButton(
            icon: ValueListenableBuilder(
                valueListenable: DownloadManager.downloads,
                builder: (context, downloads, child) => AnimatedGradientIcon(
                    icon: Icons.file_download_outlined,
                    animated: downloads.isNotEmpty
                )
            ),
            onPressed: () => Scaffold.of(context).openDrawer()
        );
    }
}
