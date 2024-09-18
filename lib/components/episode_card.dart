import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/border_text.dart';
import 'package:stronzflix/components/resource_image.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';
import 'package:stronzflix/dialogs/download_dialog.dart';

class EpisodeCard extends StatelessWidget {
    final Episode episode;

    const EpisodeCard({
        super.key,
        required this.episode    
    });

    Widget _buildCover(BuildContext context) {
        int? duration = KeepWatching.getDuration(this.episode);
        int? timestamp = KeepWatching.getTimestamp(this.episode);
        double? progress = duration != null && timestamp != null
            ? timestamp / duration
            : null;

        return Expanded(
            child: Stack(
                fit: StackFit.expand,
                children: [
                    ResourceImage(
                        uri: this.episode.cover,
                        fit: BoxFit.fitWidth, 
                    ),
                    if(progress != null)
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: LinearProgressIndicator(
                                value: progress
                            )
                        ),
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                bottom: 2.0,
                                left: 2.0
                            ),
                            child: BorderText(
                                builder: (style) => TextSpan(
                                    text: this.episode.episodeNo.toString(),
                                    style: style?.copyWith(
                                        fontSize: 32,
                                    ) ?? const TextStyle(
                                        fontSize: 32,
                                    ),
                                ),
                            ),
                        ),
                    )
                ]
            ),
        );
    }

    Widget _buildActionIcon(BuildContext context, IconData icon, {bool enabled = true}) {
        return IconButton(
            padding: const EdgeInsets.all(3.0),
            constraints: const BoxConstraints(),
            iconSize: 26,
            onPressed: enabled ? () => this._action(context) : null,
            icon: Icon(icon)
        );
    }

    Widget _buildTitle(BuildContext context) {
        return Row(
            children: [
                Expanded(
                    child: Text(this.episode.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.left
                    )
                ),
                if(this.episode.site.isLocal)
                    this._buildActionIcon(context, Icons.delete_outline)
                else
                    FutureBuilder(
                        future: DownloadManager.alreadyDownloaded(this.episode),
                        builder: (context, snapshot) =>  this._buildActionIcon(
                            context,
                            snapshot.hasData && snapshot.data!
                                ? Icons.download_done_rounded
                                : Icons.file_download_outlined,
                            enabled: snapshot.hasData && !snapshot.data!
                        )
                    )
            ],
        );
    }

    @override
    Widget build(BuildContext context) {
        return AspectRatio(
            aspectRatio: 3 / 2,
            child: Card(
                child: InkWell(
                    focusNode: FocusNode(
                        skipTraversal: false,
                        descendantsAreTraversable: false,
                    ),
                    onTap: () => this._play(context),
                    child: Padding(
                        padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                this._buildCover(context),
                                const SizedBox(height: 4.0),
                                this._buildTitle(context)
                            ],
                        )
                    )
                )
            )
        );
    }

    void _play(BuildContext context) {
        Navigator.pushNamed(context, '/player', arguments: this.episode);
    }

    void _action(BuildContext context) {
        if(this.episode.site.isLocal)
            this._delete(context, this.episode);
        else    
            this._download(context, this.episode);
    }

    Future<void> _download(BuildContext context, Watchable watchable) async {
        await DownloadDialog.open(context, watchable);
    }

    Future<void> _delete(BuildContext context, Watchable watchable) async {
        bool delete = await ConfirmationDialog.ask(context,
            "Elimina ${watchable.title}",
            "Sei sicuro di voler eliminare ${watchable.title}?",
            action: "Elimina"
        );
        if (delete)
            await DownloadManager.deleteSingle(watchable);
    }
}
