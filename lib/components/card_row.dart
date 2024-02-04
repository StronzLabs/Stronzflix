import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/components/result_card.dart';

class CardRow<T> extends StatelessWidget {

    final String title;
    final Future<Iterable<T>> values;
    final void Function(T) onTap;
    final void Function(T)? onLongPress;

    const CardRow({
        super.key,
        required this.values,
        required this.onTap,
        required this.title,
        this.onLongPress
    });

    Widget _buildResultCard(BuildContext context, SearchResult result) {
        return ResultCard(
            width: MediaQuery.of(context).size.width / 5.5,
            imageUrl: result.poster,
            text: result.name,
            onTap: () => this.onTap(result as T)
        );
    }

    Widget _buildSerialCard(BuildContext context, SerialInfo serialInfo) {
        return ResultCard(
            width: MediaQuery.of(context).size.width / 5.5,
            imageUrl: serialInfo.cover,
            text: serialInfo.name,
            onLongPress: () => this.onLongPress?.call(serialInfo as T),
            onTap: () => this.onTap(serialInfo as T)
        );
    }

    @override
    Widget build(BuildContext context) {
        return FutureBuilder(
            future: values,
            builder: (context, snapshot) {
                if(!snapshot.hasData || snapshot.data!.isEmpty)
                    return Container();

                Iterable<T> values = snapshot.data as Iterable<T>;

                Widget scrollView = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: 
                    Row(
                        children: values.map((T data) {
                            Widget card = T == SerialInfo ? this._buildSerialCard(context, data as SerialInfo) :
                                T == SearchResult ? this._buildResultCard(context, data as SearchResult) :
                                throw Exception("Unknown type");

                            return SizedBox(
                                height: MediaQuery.of(context).size.height / 3,
                                child: AspectRatio(
                                    aspectRatio: 9 / 14,
                                    child: card,
                                ),
                            );
                        }).toList(),
                    ),
                );

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 30,
                                overflow: TextOverflow.ellipsis
                            )
                        ),
                        scrollView
                    ]
                );
            }
        );
    }

}