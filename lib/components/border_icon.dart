import 'package:flutter/material.dart';

class BorderIcon extends StatelessWidget {

    final IconData icon;
    final Color borderColor;
    final double? size;

    const BorderIcon(this.icon, {
        super.key,
        this.borderColor = Colors.black,
        this.size
    });

    @override
    Widget build(BuildContext context) {
        double size = this.size ?? const IconThemeData.fallback()
            .merge(IconTheme.of(context)).size!;
        return Stack(
            alignment: Alignment.center,
            children: [
                Icon(this.icon,
                    color: this.borderColor,
                    size: size + 1,
                ),
                Icon(this.icon,
                    size: size,
                )
            ],
        );
    }
}
