import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stronzflix/components/border_text.dart';
import 'package:stronzflix/components/resource_image.dart';
import 'package:sutils/sutils.dart';
import 'package:uuid/uuid.dart';

class ResultCard extends StatefulWidget {

    final void Function(String uuid)? onTap;
    final void Function()? action;
    final IconData? actionIcon;
    final Uri? imageUrl;
    final String text;
    final double? width;
    final double? progress;
    final String? footer;

    const ResultCard({
        super.key,
        required this.imageUrl,
        required this.text,
        this.onTap,
        this.width,
        this.action,
        this.actionIcon,
        this.progress,
        this.footer
    });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {

    bool _hover = false;
    final String _uuid = const Uuid().v4();

    @override
    Widget build(BuildContext context) {
        Widget child = super.widget.imageUrl == null
            ? Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surface,
                highlightColor: Theme.of(context).scaffoldBackgroundColor,
                period: const Duration(milliseconds: 2500),
                child: const Card(
                    child: SizedBox.expand(),
                )
            )
            : Card(
                child: InkWell(
                    onTap: () => super.widget.onTap?.call(this._uuid),
                    onLongPress: EPlatform.isMobile ? super.widget.action : null,
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
                                                            child: Hero(
                                                                tag: this._uuid,
                                                                child: ResourceImage(
                                                                    uri: super.widget.imageUrl!,
                                                                    fit: BoxFit.cover,
                                                                ),
                                                            )
                                                        ),
                                                        if(super.widget.progress != null)
                                                            Align(
                                                                alignment: Alignment.bottomCenter,
                                                                child: LinearProgressIndicator(
                                                                    value: super.widget.progress,
                                                                ),
                                                            ),
                                                        if(super.widget.footer != null)
                                                            Align(
                                                                alignment: Alignment.bottomLeft,
                                                                child: Padding(
                                                                    padding: const EdgeInsets.only(
                                                                        bottom: 2.0,
                                                                        left: 10
                                                                    ),
                                                                    child: BorderText(
                                                                        builder: (style) => TextSpan(
                                                                            text: super.widget.footer!,
                                                                            style: style?.copyWith(
                                                                                fontSize: 32,
                                                                            ) ?? const TextStyle(
                                                                                fontSize: 32,
                                                                            ),
                                                                        ),
                                                                    ),
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
