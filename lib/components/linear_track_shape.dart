import 'package:flutter/material.dart';

class LinearTrackShape extends RoundedRectSliderTrackShape {
    const LinearTrackShape();

    @override
    Rect getPreferredRect({
        required RenderBox parentBox,
        Offset offset = Offset.zero,
        required SliderThemeData sliderTheme,
        bool isEnabled = false,
        bool isDiscrete = false,
    }) {
        double height = sliderTheme.trackHeight!;
        double left = offset.dx;
        double top = offset.dy + (parentBox.size.height - height) / 2;
        double width = parentBox.size.width;
        return Rect.fromLTWH(
            left,
            top,
            width,
            height,
        );
    }
}
