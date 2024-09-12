import 'package:flutter/material.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';

import '../backend/downloads/download_state.dart';

class DownloadsDrawer extends StatefulWidget {
    const DownloadsDrawer({super.key});

    @override
    State<DownloadsDrawer> createState() => _DownloadsDrawerState();
}

class _DownloadsDrawerState extends State<DownloadsDrawer> {
    
    Widget _buildDownloadTile(BuildContext context, DownloadState download) {
        return Card(
            child: Padding(
                padding: const EdgeInsets.only(top: 13, bottom: 10, left: 15, right: 15),
                child: ValueListenableBuilder(
                    valueListenable: download,
                    builder: (context, progress, _) => Column(
                        children: [
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(download.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge
                                )
                            ),
                            const SizedBox(height: 9),
                            LinearProgressIndicator(
                                value: progress,
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                            ),
                            const SizedBox(height: 3),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    Text(download.hasError ? "Errore" : "${(progress * 100).toStringAsFixed(0)}%",
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: download.hasError ? Theme.of(context).colorScheme.error : null
                                        ) ?? TextStyle(
                                            color: download.hasError ? Theme.of(context).colorScheme.error : null
                                        )
                                    ),
                                    const Spacer(),
                                    if(!download.hasError)
                                        InkWell(
                                            onTap: () {
                                                if(download.isPaused)
                                                    download.resume();
                                                else
                                                    download.pause();
                                            },
                                            borderRadius: const BorderRadius.all(Radius.circular(20)),
                                            child: Icon(download.isPaused ? Icons.play_arrow : Icons.pause,
                                                size: 30
                                            )
                                        ),
                                    InkWell(
                                        onTap: () => download.cancel(),
                                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                                        child: const Icon(Icons.delete_forever,
                                            size: 25
                                        )
                                    ),
                                ]
                            )
                        ]
                    ),
                )
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return SafeArea(
            child: Drawer(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero
                ),
                child: ValueListenableBuilder(
                    valueListenable: DownloadManager.downloads,
                    builder: (context, value, _) {
                        return Column(
                            children: [
                                Container(
                                    color: Theme.of(context).colorScheme.primary,
                                    height: 56,
                                    child: const Center(
                                        child: Text(
                                        'Download in corso',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 20
                                        ),
                                    ),
                                    ),
                                ),
                                const SizedBox(height: 10),
                                Flexible(
                                    child: ListView(
                                        padding: EdgeInsets.zero,
                                        children: [
                                            if (value.isNotEmpty)
                                                ...[ for(DownloadState download in value) _buildDownloadTile(context, download) ]
                                            else
                                                Center(
                                                    child: Text(
                                                        'Nessun download in corso',
                                                        style: TextStyle(
                                                            color: Theme.of(context).colorScheme.secondary,
                                                            fontSize: 20
                                                        ),
                                                    ),
                                                )
                                        ],
                                    )
                                )
                            ],
                        );
                    }
                ),
            )
        );
    }
}
