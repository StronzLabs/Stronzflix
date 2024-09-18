import 'package:flutter/material.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/components/animated_gradient_icon.dart';

class DownloadsIcon extends StatelessWidget {
    const DownloadsIcon({super.key});

    @override
    Widget build(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: DownloadManager.downloads,
            builder: (context, downloads, child) => AnimatedGradientIcon(
                icon: Icons.file_download_outlined,
                animated: downloads.isNotEmpty
            )
        );
    }
}
