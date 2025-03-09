import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/border_text.dart';
import 'package:stronzflix/dialogs/download_dialog.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'package:sutils/ui/widgets/resource_image.dart';
import 'package:sutils/utils.dart';

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

    Widget _buildActionIcon(BuildContext context, IconData icon, {void Function()? action}) {
        return IconButton(
            padding: const EdgeInsets.all(3.0),
            constraints: const BoxConstraints(),
            iconSize: 26,
            onPressed: action,
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
                    this._buildActionIcon(context, Icons.delete_outline,
                        action: () => DownloadManager.deleteDialog(context, this.episode)
                    )
                else if(this.episode.site.allowsDownload)
                    FutureBuilder(
                        future: DownloadManager.alreadyDownloaded(this.episode),
                        builder: (context, snapshot) => this._buildActionIcon(
                            context,
                            snapshot.hasData && snapshot.data!
                                ? Icons.download_done_rounded
                                : Icons.file_download_outlined,
                            action: snapshot.hasData && !snapshot.data!
                                ? () => DownloadDialog.open(context, this.episode)
                                : null
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
                    autofocus: EPlatform.isTV,
                    focusNode: FocusNode(
                        skipTraversal: false,
                        descendantsAreTraversable: false,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/player', arguments: PlayerPageArguments(this.episode)),
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
}
