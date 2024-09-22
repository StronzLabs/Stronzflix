import 'dart:math';

import 'package:flutter/material.dart';

class CardGrid<T> extends StatelessWidget {
    final Iterable<T> values;
    final Widget Function(BuildContext, T) buildCard;
    final ScrollPhysics? physics;
    final double aspectRatio;
    final Widget? emptyWidget;
    final bool shrinkWrap;
    final double minCardHeight;

    const CardGrid({
        super.key,
        required this.values,
        required this.buildCard,
        this.emptyWidget,
        this.aspectRatio = 16 / 9,
        this.physics,
        this.shrinkWrap = false,
        this.minCardHeight = 0
    });
    
    @override
    Widget build(BuildContext context) {
        if(this.values.isEmpty)
            return this.emptyWidget ?? const SizedBox.shrink();

        double minCardWidth = 350;
        double screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = max((screenWidth / minCardWidth).floor(), 1);

        double aspectRatio = this.aspectRatio;
        if(this.minCardHeight > 0) {
            double cardHeight = screenWidth / crossAxisCount / aspectRatio;
            if(cardHeight < this.minCardHeight) {
                aspectRatio = screenWidth / crossAxisCount / this.minCardHeight;
            }
        }

        return GridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            physics: this.physics,
            shrinkWrap: this.shrinkWrap,
            children: [
                for (T result in this.values)
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: this.buildCard(context, result)
                    )
            ]
        );
    }
}
