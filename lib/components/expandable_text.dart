import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef StringCallback = void Function(String value);

class ExpandableText extends StatefulWidget {

    final String text;
    final String expandText;
    final String? collapseText;
    final bool expanded;
    final Color? linkColor;
    final bool linkEllipsis;
    final TextStyle? linkStyle;
    final bool expandOnTextTap;
    final bool collapseOnTextTap;
    final TextStyle? style;
    final TextDirection? textDirection;
    final TextAlign? textAlign;
    final TextScaler? textScaleFactor;
    final int maxLines;
    final bool animation;
    final Duration? animationDuration;
    final Curve? animationCurve;

    const ExpandableText(
        this.text, {
        super.key,
        required this.expandText,
        this.collapseText,
        this.expanded = false,
        this.linkColor,
        this.linkEllipsis = true,
        this.linkStyle,
        this.expandOnTextTap = false,
        this.collapseOnTextTap = false,
        this.style,
        this.textDirection,
        this.textAlign,
        this.textScaleFactor,
        this.maxLines = 2,
        this.animation = false,
        this.animationDuration,
        this.animationCurve,
    })  : assert(maxLines > 0);

    @override
    State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> with TickerProviderStateMixin {
    
    late bool _expanded = super.widget.expanded;
    late final TapGestureRecognizer _linkTapGestureRecognizer = TapGestureRecognizer()..onTap =
            () => super.setState(() => this._expanded = !this._expanded);

    @override
    void dispose() {
        this._linkTapGestureRecognizer.dispose();
        super.dispose();
    }

    TextSpan _buildLink(BuildContext context, TextStyle effectiveTextStyle) {
        String linkText = (this._expanded ? super.widget.collapseText : super.widget.expandText) ?? '';
        Color linkColor = super.widget.linkColor ?? super.widget.linkStyle?.color ?? Theme.of(context).colorScheme.secondary;
        TextStyle linkTextStyle = effectiveTextStyle.merge(super.widget.linkStyle).copyWith(color: linkColor);

        return TextSpan(
            children: [
                if (!this._expanded)
                    TextSpan(
                        text: '\u2026 ',
                        style: super.widget.linkEllipsis ? linkTextStyle : effectiveTextStyle,
                        recognizer: super.widget.linkEllipsis ? this._linkTapGestureRecognizer : null,
                    ),
                if (linkText.isNotEmpty)
                    TextSpan(
                        style: effectiveTextStyle,
                        children: [
                            if (_expanded)
                                const TextSpan(text: ' '),
                            TextSpan(
                                text: linkText,
                                style: linkTextStyle,
                                recognizer: this._linkTapGestureRecognizer,
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

        TextSpan link = this._buildLink(context, effectiveTextStyle);

        Widget result = LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
                assert(constraints.hasBoundedWidth);
                
                TextAlign  textAlign = super.widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
                TextDirection  textDirection = super.widget.textDirection ?? Directionality.of(context);
                Locale? locale = Localizations.maybeLocaleOf(context);
                TextScaler textScaler = super.widget.textScaleFactor ?? MediaQuery.textScalerOf(context);

                double maxWidth = constraints.maxWidth;
                TextSpan content = TextSpan(text: widget.text, style: effectiveTextStyle);
                TextPainter textPainter = TextPainter(
                    textAlign: textAlign,
                    textDirection: textDirection,
                    textScaler: textScaler,
                    maxLines: widget.maxLines,
                    locale: locale,
                );

                textPainter.text = link;
                textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
                Size linkSize = textPainter.size;

                textPainter.text = content;
                textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
                Size textSize = textPainter.size;

                TextSpan textSpan;
                if (!textPainter.didExceedMaxLines)
                    textSpan = content;
                else {
                    TextPosition  position = textPainter.getPositionForOffset(Offset(
                        textSize.width - linkSize.width,
                        textSize.height,
                    ));
                    int endOffset = textPainter.getOffsetBefore(position.offset) ?? 0;

                    TapGestureRecognizer? recognizer =
                        (this._expanded ? super.widget.collapseOnTextTap : super.widget.expandOnTextTap)
                        ? this._linkTapGestureRecognizer
                        : null;

                    TextSpan text = TextSpan(
                        text: this._expanded ? super.widget.text : super.widget.text.substring(0, max(endOffset, 0)),
                        recognizer: recognizer
                    );

                    textSpan = TextSpan(
                        style: effectiveTextStyle,
                        children: [
                            text,
                            link,
                        ],
                    );
                }

                RichText richText = RichText(
                    text: textSpan,
                    softWrap: true,
                    textDirection: textDirection,
                    textAlign: textAlign,
                    textScaler : textScaler,
                    overflow: TextOverflow.clip,
                );

                if (super.widget.animation)
                    return AnimatedSize(
                        duration: super.widget.animationDuration ?? const Duration(milliseconds: 200),
                        curve: super.widget.animationCurve ?? Curves.fastLinearToSlowEaseIn,
                        alignment: this._expanded ? Alignment.topLeft : Alignment.bottomLeft,
                        child: richText,
                    );

                return richText;
            },
        );

        return result;
    }
}
