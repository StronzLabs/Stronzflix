import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {

    final void Function() onTap;
    final void Function()? onLongPress;
    final String imageUrl;
    final String text;
    final double? width;

    const ResultCard({
        super.key,
        required this.onTap,
        required this.imageUrl,
        required this.text,
        this.onLongPress,
        this.width
    });

    @override
    Widget build(BuildContext context) {
        return SizedBox(
            width: this.width,
            child: Card(
                child: InkWell(
                    onTap: this.onTap,
                    onLongPress: this.onLongPress,
                    child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                            children: [
                                Image.network(this.imageUrl),
                                Text(this.text,
                                    overflow: TextOverflow.ellipsis
                                )
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
