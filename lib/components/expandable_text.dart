import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stronzflix/components/animated_expanding_container.dart';

class ExpandableText extends StatefulWidget {
    final String text;
    final TextStyle? style;
    final String? expandedLabel;
    final String? collapsedLabel;
    final int maxLines;
    final TextAlign? textAlign;
    final TextDirection? textDirection;
    final bool initiallyExpanded;

    const ExpandableText(this.text, {
        super.key,
        required this.maxLines,
        this.expandedLabel,
        this.collapsedLabel,
        this.style,
        this.textAlign,
        this.textDirection,
        this.initiallyExpanded = false
    });

    @override
    State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {

    late bool _expanded = super.widget.initiallyExpanded;

    TextSpan _buildLink(BuildContext context, TextStyle effectiveTextStyle) {
        String linkText = (this._expanded ? super.widget.expandedLabel : super.widget.collapsedLabel ) ?? '';
        Color linkColor = Theme.of(context).colorScheme.primary;
        TextStyle linkTextStyle = effectiveTextStyle.merge(super.widget.style).copyWith(color: linkColor);

        return TextSpan(
            children: [
                if (!this._expanded)
                    TextSpan(
                        text: '\u2026 ',
                        style: linkTextStyle
                    ),
                if (linkText.isNotEmpty)
                    TextSpan(
                        style: effectiveTextStyle,
                        children: [
                            if (_expanded)
                                const TextSpan(text: ' '),
                            TextSpan(
                                text: linkText,
                                style: linkTextStyle
                            ),
                        ],
                    ),
            ],
        );
    }

    @override
    Widget build(BuildContext context) {
        DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
        TextStyle effectiveTextStyle = super.widget.style == null || super.widget.style!.inherit
            ? defaultTextStyle.style.merge(widget.style) : super.widget.style!;

        TextAlign textAlign = super.widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
        TextDirection textDirection = super.widget.textDirection ?? Directionality.of(context);
        TextScaler textScaler = MediaQuery.textScalerOf(context);
        Locale? locale = Localizations.maybeLocaleOf(context);

        return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
                assert(constraints.hasBoundedWidth);

                double maxWidth = constraints.maxWidth;
                TextSpan content = TextSpan(
                    text: super.widget.text,
                    style: effectiveTextStyle
                );
                TextPainter textPainter = TextPainter(
                    textAlign: textAlign,
                    textDirection: textDirection,
                    textScaler: textScaler,
                    locale: locale,
                    maxLines: super.widget.maxLines,
                );

                TextSpan link = this._buildLink(context, effectiveTextStyle);
                textPainter.text = link;
                textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
                Size linkSize = textPainter.size;

                textPainter.text = content;
                textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
                Size textSize = textPainter.size;

                TextPosition position = textPainter.getPositionForOffset(Offset(
                    textSize.width - linkSize.width,
                    textSize.height,
                ));
                int endOffset = textPainter.getOffsetBefore(position.offset) ?? 0;

                Widget buildText(BuildContext context, bool expanded) {
                    return RichText(
                        text: TextSpan(
                            children: [
                                TextSpan(
                                    text: expanded
                                        ? super.widget.text
                                        : super.widget.text.substring(0, max(endOffset, 0)),
                                    style: effectiveTextStyle
                                ),
                                if(textPainter.didExceedMaxLines)
                                    link
                            ]
                        ),
                        softWrap: true,
                        textDirection: textDirection,
                        textAlign: textAlign,
                        textScaler : textScaler,
                        overflow: TextOverflow.clip,
                    );
                }

                if (!textPainter.didExceedMaxLines)
                    return buildText(context, false);

                return GestureDetector(
                    onTap: () => super.setState(() => this._expanded = !this._expanded),
                    child: AnimatedExpandingContainer(
                        expanded: this._expanded,
                        expandedWidget: buildText(context, true),
                        unexpandedWidget: buildText(context, false),
                    ),
                );
            }
        );
    }
}

class EllipsisTextPainter extends CustomPainter {
    final TextSpan text;
    final int maxLines;
    final String? ellipsis;

    EllipsisTextPainter({
        required this.text,
        required this.ellipsis,
        required this.maxLines,
    });

    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;

    @override
    void paint(Canvas canvas, Size size) {
        TextPainter painter = TextPainter(
            text: this.text,
            maxLines: this.maxLines,
            textDirection: TextDirection.ltr,
            ellipsis: this.ellipsis
        );
        painter.layout(maxWidth: size.width);
        painter.paint(canvas, const Offset(0, 0));
    }
}
