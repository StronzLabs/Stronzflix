import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {

    final void Function() onTap;
    final String imageUrl;
    final String text;

    const ResultCard({super.key, required this.onTap, required this.imageUrl, required this.text});

    @override
    Widget build(BuildContext context) {
        return Card(
            child: InkWell(
                onTap: this.onTap,
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                        children: [
                            Expanded(
                                child: Container(
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: NetworkImage(this.imageUrl),
                                            fit: BoxFit.contain
                                        ),
                                    ),
                                )
                            ),
                            Text(this.text,
                                overflow: TextOverflow.ellipsis
                            )
                        ],
                    ),
                ),
            ),
        );
    }
}
