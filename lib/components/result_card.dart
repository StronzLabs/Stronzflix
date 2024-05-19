import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stronzflix/utils/platform.dart';

class ResultCard extends StatefulWidget {

    final void Function()? onTap;
    final void Function()? action;
    final IconData? actionIcon;
    final String? imageUrl;
    final String text;
    final double? width;
    final double? progress;

    const ResultCard({
        super.key,
        required this.imageUrl,
        required this.text,
        this.onTap,
        this.width,
        this.action,
        this.actionIcon,
        this.progress,
    });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {

    bool _hover = false;

    @override
    Widget build(BuildContext context) {
        Widget child = super.widget.imageUrl == null
            ? Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surface,
                highlightColor: Theme.of(context).colorScheme.background,
                period: const Duration(milliseconds: 2500),
                child: const Card(
                    child: SizedBox.expand(),
                )
            )
            : Card(
                child: InkWell(
                    onTap: super.widget.onTap,
                    onLongPress: SPlatform.isMobile ? super.widget.action : null,
                    onHover: (value) => super.setState(() => this._hover = value),
                    child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SizedBox.expand(
                            child: Stack(
                                children: [
                                    Column(
                                        children: [
                                            Expanded(
                                                child: Stack(
                                                    children: [
                                                        Align(
                                                            alignment: Alignment.center,
                                                            child: super.widget.imageUrl!.startsWith("http")
                                                            ? Image.network(
                                                                super.widget.imageUrl!,
                                                                fit: BoxFit.cover,
                                                            )
                                                            : Image.file(
                                                                File(super.widget.imageUrl!),
                                                                fit: BoxFit.cover,
                                                            ),
                                                        ),
                                                        if(super.widget.progress != null)
                                                            Align(
                                                                alignment: Alignment.bottomCenter,
                                                                child: LinearProgressIndicator(
                                                                    value: super.widget.progress,
                                                                ),
                                                            ),
                                                    ],
                                                )
                                            ),
                                            Text(
                                                super.widget.text,
                                                overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                    ),
                                    if(super.widget.action != null)
                                        Align(
                                            alignment: Alignment.topRight,
                                            child: Visibility(
                                                visible: this._hover,
                                                child: ElevatedButton(
                                                    onPressed: super.widget.action,
                                                    child: Icon(super.widget.actionIcon ?? Icons.more_vert),
                                                ),
                                            )
                                        ),
                                ],
                            )
                        )
                    )
                )
            );

        return SizedBox(
            width: super.widget.width,
            child: child,
        );
    }
}
