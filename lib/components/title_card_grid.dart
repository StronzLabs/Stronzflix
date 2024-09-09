import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/title_card.dart';

class TitleCardGrid extends StatelessWidget {

    final Future<Iterable<TitleMetadata>> values;
    final Widget Function(TitleMetadata)? buildAction;
    final Widget? emptyWidget;

    const TitleCardGrid({
        super.key,
        required this.values,
        this.buildAction,
        this.emptyWidget
    });
    
    @override
    Widget build(BuildContext context) {
        double minCastWidth = 350;
        double screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = max((screenWidth / minCastWidth).floor(), 1);

        return FutureBuilder(
            future: this.values,
            builder: (context, snapshot) {
                if(snapshot.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());

                if(snapshot.hasData && snapshot.data!.isEmpty)
                    return this.emptyWidget ?? const SizedBox.shrink();

                return GridView.count(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 16 / 9,
                    children: [
                        for (TitleMetadata result in snapshot.data as Iterable<TitleMetadata>)
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TitleCard(
                                    title: result,
                                    buildAction: this.buildAction
                                )
                            )
                    ]
                );
            }
        );
    }
}
