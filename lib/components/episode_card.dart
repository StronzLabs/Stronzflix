import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/border_text.dart';
import 'package:stronzflix/components/resource_image.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';
import 'package:stronzflix/dialogs/download_dialog.dart';

class EpisodeCard extends StatefulWidget {
    final Episode episode;

    const EpisodeCard({
        super.key,
        required this.episode    
    });

    @override
    State<StatefulWidget> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {

    Widget _buildCover(BuildContext context) {
        int? duration = KeepWatching.getDuration(super.widget.episode);
        int? timestamp = KeepWatching.getTimestamp(super.widget.episode);
        double? progress = duration != null && timestamp != null
            ? timestamp / duration
            : null;

        return Expanded(
            child: Stack(
                fit: StackFit.expand,
                children: [
                    ResourceImage(
                        uri: super.widget.episode.cover,
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
                                    text: super.widget.episode.episodeNo.toString(),
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

    Widget _buildTitle(BuildContext context) {
        return Row(
            children: [
                Expanded(
                    child: Text(super.widget.episode.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.left
                    )
                ),
                IconButton(
                    padding: const EdgeInsets.all(3.0),
                    constraints: const BoxConstraints(),
                    iconSize: 26,
                    onPressed: this._action,
                    icon: Icon(super.widget.episode.site.isLocal
                        ? Icons.delete_outline
                        : Icons.file_download_outlined
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
                    onLongPress: this._action,
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
        Navigator.pushNamed(context, '/player', arguments: super.widget.episode);
    }

    void _action() {
        if(super.widget.episode.site.isLocal)
            this._delete(super.widget.episode);
        else    
            this._download(super.widget.episode);
    }

    Future<void> _download(Watchable watchable) async {
        await DownloadDialog.open(context, watchable);
    }

    Future<void> _delete(Watchable watchable) async {
        bool delete = await ConfirmationDialog.ask(context,
            "Elimina ${watchable.title}",
            "Sei sicuro di voler eliminare ${watchable.title}?",
            action: "Elimina"
        );
        if (delete) {
            await DownloadManager.deleteSingle(watchable);
            if(!super.mounted)
                return;
            
            Season season = super.widget.episode.season;
            Series series = season.series;
            if(series.seasons.length == 1 && season.episodes.length == 1)
                Navigator.of(context).pop();
        }
    }
}
