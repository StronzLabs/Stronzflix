import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/resource_image.dart';
import 'package:stronzflix/dialogs/loading_dialog.dart';
import 'package:uuid/uuid.dart';

class TitleCard extends StatefulWidget {
    final TitleMetadata? title;
    final Widget? action;

    const TitleCard({
        super.key,
        this.title,
        this.action
    });

    @override
    State<TitleCard> createState() => _TitleCardState();
}

class _TitleCardState extends State<TitleCard> {
    final String _uuid = const Uuid().v4();

    TitleMetadata get _title => super.widget.title!;

    Widget _buildButton(BuildContext context, {
        required IconData icon,
        required void Function() action
    }) {
        return IconButton(
            onPressed: action,
            icon: Icon(icon,
                size: 50
            )
        );
    }

    Widget _buildFavicon(BuildContext context) {
        if(this._title.site.isLocal)
            return const SizedBox.shrink();
        return IconButton(
            onPressed: null,
            icon: ResourceImage(
                uri: this._title.site.favicon,
                width: 30,
                height: 30,
            )
        );
    }

    Widget _buildActions(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: KeepWatching.listener,
            builder: (context, _, __) {
                return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        if(KeepWatching.isWatched(this._title))  
                            this._buildButton(context, 
                                icon: Icons.fast_forward,
                                action: () => this._keepWatching(context)
                            )
                        else
                            this._buildButton(context,
                                icon: Icons.play_arrow,
                                action: () => this._play(context)
                            ),
                        this._buildFavicon(context)
                    ],
                );
            }
        );
    }

    Widget _buildSection(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Flexible(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Flexible(
                                child: AutoSizeText(this._title.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold
                                    )
                                )
                            ),
                            if(super.widget.action != null)
                                super.widget.action!
                        ]
                    )
                ),
                this._buildActions(context)
            ]
        );
    }

    @override
    Widget build(BuildContext context) {
        if(super.widget.title == null)
            return AspectRatio(
                aspectRatio: 16 / 9,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surface,
                    highlightColor: Theme.of(context).scaffoldBackgroundColor,
                    period: const Duration(milliseconds: 2500),
                    child: const Card(
                        child: SizedBox.expand(),
                    )
                )
            );
        return AspectRatio(
            aspectRatio: 16 / 9, 
            child: Card(
                child: InkWell(
                    focusNode: FocusNode(
                        skipTraversal: false,
                        descendantsAreTraversable: false,
                    ),
                    onTap: () => this._open(context),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IntrinsicHeight(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Hero(
                                        tag: this._uuid,
                                        child: ResourceImage(
                                            uri: this._title.poster
                                        )
                                    ),
                                    const SizedBox(width: 16),
                                    Flexible(
                                        child: this._buildSection(context)
                                    )
                                ]
                            )
                        )
                    )
                )
            )
        );
    }

    void _open(BuildContext context) {
        Navigator.pushNamed(context, '/title', arguments: [ this._uuid, super.widget.title ]);
    }

    void _play(BuildContext context) {
        LoadingDialog.load(context, () async => await this._title.site.getTitle(this._title))
        .then((title) {
            if(!context.mounted)
                return;
            if(title.comingSoon != null) {
                String date = title.comingSoon!.toIso8601String().substring(0, 10).split("-").reversed.join("/");
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                        title: const Text("Prossimamente"),
                        content: Text("Data prevista di rilascio: ${date}"),
                        actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Chiudi")
                            )
                        ]
                    )
                );
                return;
            }
                
            Watchable watchable =
                title is Series ? title.seasons.first.episodes.first
                : title is Film ? title
                : throw Exception("Unknown title type");
            Navigator.pushNamed(context, '/player', arguments: watchable);
        });
    }

    void _keepWatching(BuildContext context) {
        LoadingDialog.load(context, () async => await KeepWatching.getWatchable(this._title))
        .then((watchable) {
            if(!context.mounted)
                return;
            Navigator.pushNamed(context, '/player', arguments: watchable);
        });
    }
}
