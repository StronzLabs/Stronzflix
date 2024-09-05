import 'package:flutter/material.dart';
import 'package:stronzflix/components/animated_expanding_container.dart';

class ExpandableText extends StatefulWidget {
    final String text;
    final int maxLines;
    final int minLines;
    final TextStyle? style;
    final TextAlign textAlign;

    const ExpandableText(this.text, {
        super.key,
        required this.maxLines,
        required this.minLines,
        this.style,
        this.textAlign = TextAlign.start
    });

    @override
    State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
    bool _expanded = false;

    Widget _expandableText(bool isExpanded) {
        return RichText(
            maxLines: isExpanded ? super.widget.maxLines : super.widget.minLines,
            overflow: TextOverflow.ellipsis,
            textAlign: super.widget.textAlign,
            text: TextSpan(
                text: super.widget.text,
                style: super.widget.style
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: () => super.setState(() => this._expanded = !this._expanded),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    AnimatedExpandingContainer(
                        isExpanded: this._expanded,
                        expandedWidget: this._expandableText(true),
                        unexpandedWidget: this._expandableText(false),
                    ),
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text(this._expanded
                            ? "Mostra meno"
                            : "Mostra altro",
                            style: (super.widget.style ?? DefaultTextStyle.of(context).style)
                                .copyWith(
                                    color: Theme.of(context).colorScheme.primary
                                ),
                        ),
                    )
                ],
            )
        );
    }
}
