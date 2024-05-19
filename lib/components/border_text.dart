import 'package:flutter/material.dart';

class BorderText extends StatelessWidget {

    final InlineSpan Function(TextStyle? style) builder;
    final Color borderColor;

    const BorderText({
        super.key,
        required this.builder,
        this.borderColor = Colors.black
    });

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
                RichText(
                    text: builder(
                        TextStyle(
                            foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 1
                                ..color = this.borderColor
                        )
                    )
                ),
                RichText(text: this.builder(null))
            ],
        );
    }
}
