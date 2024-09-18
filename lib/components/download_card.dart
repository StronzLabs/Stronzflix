import 'package:flutter/material.dart';
import 'package:stronzflix/backend/downloads/download_state.dart';

class DownloadCard extends StatelessWidget {

    final DownloadState download;

    const DownloadCard({
        super.key,
        required this.download
    });

    @override
    Widget build(BuildContext context) {
        return AspectRatio(
            aspectRatio: 16 / 5,
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.only(top: 13, bottom: 10, left: 15, right: 15),
                    child: ValueListenableBuilder(
                        valueListenable: this.download,
                        builder: (context, progress, _) => Column(
                            children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(this.download.name,
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
                                        Text(this.download.hasError ? "Errore" : "${(progress * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: this.download.hasError ? Theme.of(context).colorScheme.error : null
                                            ) ?? TextStyle(
                                                color: this.download.hasError ? Theme.of(context).colorScheme.error : null
                                            )
                                        ),
                                        const Spacer(),
                                        if(!this.download.hasError)
                                            InkWell(
                                                onTap: () {
                                                    if(this.download.isPaused)
                                                        this.download.resume();
                                                    else
                                                        this.download.pause();
                                                },
                                                borderRadius: const BorderRadius.all(Radius.circular(20)),
                                                child: Icon(this.download.isPaused ? Icons.play_arrow : Icons.pause,
                                                    size: 30
                                                )
                                            ),
                                        InkWell(
                                            onTap: () => this.download.cancel(),
                                            borderRadius: const BorderRadius.all(Radius.circular(20)),
                                            child: const Icon(Icons.delete_forever,
                                                size: 25
                                            )
                                        ),
                                    ]
                                )
                            ]
                        )
                    )
                )
            )
        );
    }
}
