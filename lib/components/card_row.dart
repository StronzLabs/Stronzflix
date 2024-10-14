import 'package:flutter/material.dart';
import 'package:stronzflix/components/row_list_traversal_policy.dart';

class CardRow<T> extends StatefulWidget {

    final String title;
    final Iterable<T> values;
    final Widget Function(BuildContext, T) buildCard;
    final double cardAspectRatio;

    const CardRow({
        super.key,
        required this.title,
        required this.values,
        required this.buildCard,
        this.cardAspectRatio = 16 / 9,
    });

    @override
    State<CardRow> createState() => _CardRowState<T>();
}

class _CardRowState<T> extends State<CardRow<T>> {

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

    Widget _buildScrollView(BuildContext context, Iterable<T> data) {
        double width = 350;
        double height = width / super.widget.cardAspectRatio;
        return SizedBox(
            height: height,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                controller: this._scrollController,
                itemCount: data.length,
                itemBuilder: (context, index) => super.widget.buildCard(context, data.elementAt(index))
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        if (super.widget.values.isEmpty)
            return const SizedBox.shrink();

        return FocusTraversalGroup(
            policy: RowListTraversalPolicy(),
            child: MouseRegion(
                onHover: (event) => super.setState(() => this._arrowVisibility = true),
                onExit: (event) => super.setState(() => this._arrowVisibility = false),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            super.widget.title,
                            style: const TextStyle(
                                fontSize: 30,
                                overflow: TextOverflow.ellipsis,
                            ),
                        ),
                        Stack(
                            alignment: AlignmentDirectional.centerStart,
                            children: [
                                this._buildScrollView(context, super.widget.values),
                                if (this._arrowVisibility && this._scrollController.hasClients && this._scrollController.offset > 0)
                                    this._buildArrowIcon(true),
                                if (this._arrowVisibility && this._scrollController.hasClients && this._scrollController.offset < this._scrollController.position.maxScrollExtent)
                                    this._buildArrowIcon(false)
                            ],
                        ),
                    ],
                ),
            )
        );
    }
}
