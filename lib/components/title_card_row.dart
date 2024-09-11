import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/title_card.dart';

class TitleCardRow extends StatefulWidget {

    final String title;
    final Future<Iterable<TitleMetadata>> values;
    final Widget Function(TitleMetadata)? buildAction;

    const TitleCardRow({
        super.key,
        required this.title,
        required this.values,
        this.buildAction
    });

    @override
    State<TitleCardRow> createState() => _TitleCardRowState();
}

class _TitleCardRowState extends State<TitleCardRow> {

    bool _arrowVisibility = false;
    final ScrollController _scrollController = ScrollController();

    Widget _buildArrowIcon(bool left) {
        return Align(
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            child: IconButton(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                icon: Icon(left ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                    shadows: const [
                        Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 2
                        )
                    ],
                ),
                onPressed: () => this._scrollController.animateTo(
                    this._scrollController.offset + (left ? -1 : 1) * MediaQuery.of(context).size.width / 5.5 * 2,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                ).then((value) => super.setState(() {}))
            ),
        );
    }

    Widget _buildScrollView(BuildContext context, Iterable<TitleMetadata?> data) {
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: this._scrollController,
            child: Row(
                children: [
                    for (TitleMetadata? metadata in [for (TitleMetadata? metadata in data) metadata])
                        SizedBox(
                            width: 350,
                            child: TitleCard(
                                title: metadata,
                                buildAction: super.widget.buildAction,
                            )
                        )
                ]
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return FutureBuilder(
            future: widget.values,
            builder: (context, snapshot) {
                if(snapshot.hasData && snapshot.data!.isEmpty)
                    return const SizedBox.shrink();

                return MouseRegion(
                    onHover: (event) => super.setState(() => this._arrowVisibility = true),
                    onExit: (event) => super.setState(() => this._arrowVisibility = false),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                widget.title,
                                style: const TextStyle(
                                    fontSize: 30,
                                    overflow: TextOverflow.ellipsis,
                                ),
                            ),
                            Stack(
                                alignment: AlignmentDirectional.centerStart,
                                children: [
                                    this._buildScrollView(context, snapshot.data as Iterable<TitleMetadata?>? ?? List.filled(50, null)),
                                    if (this._arrowVisibility && this._scrollController.hasClients && this._scrollController.offset > 0)
                                        this._buildArrowIcon(true),
                                    if (this._arrowVisibility && this._scrollController.hasClients && this._scrollController.offset < this._scrollController.position.maxScrollExtent)
                                        this._buildArrowIcon(false)
                                ],
                            ),
                        ],
                    ),
                );
            }
        );
    }
}
