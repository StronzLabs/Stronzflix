import 'package:flutter/material.dart';

class AnimatedGradientIcon extends StatefulWidget {
    final IconData icon;
    final bool animated;
    final AlignmentGeometry begin;
    final AlignmentGeometry end;
    final Color? tint;
    final double? radius;
    final bool reverse;

    const AnimatedGradientIcon({
        super.key,
        required this.icon,
        this.animated = true,
        this.begin = Alignment.topCenter,
        this.end = Alignment.bottomCenter,
        this.tint,
        this.radius,
        this.reverse = false,
    });

    @override
    State<AnimatedGradientIcon> createState() => _AnimatedGradientIconState();
}

class _AnimatedGradientIconState extends State<AnimatedGradientIcon> with SingleTickerProviderStateMixin {
    late final AnimationController _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 750),
        reverseDuration: const Duration(milliseconds: 750),
    );
    late final Animation _animation = Tween(
        begin: 0.0,
        end: 1.0,
    ).animate(this._animationController);

    @override
    void initState() {
        super.initState();
        this._animationController.repeat(reverse: super.widget.reverse);
    }

    @override
    void dispose() {
        this._animationController.dispose();
        super.dispose();
    }


    @override
    Widget build(BuildContext context) {
        Widget icon = Icon(super.widget.icon);
        if(!super.widget.animated)
            return icon;

        List<Color> colors = [
            super.widget.tint ?? Theme.of(context).colorScheme.primary,
            Theme.of(context).iconTheme.color!
        ];

        return AnimatedBuilder(
            animation: this._animationController,
            builder: (context, child) {
                return ShaderMask(
                    shaderCallback: (bounds) => (super.widget.radius != null
                        ? RadialGradient(
                            center: super.widget.begin,
                            colors: colors,
                            stops: [ this._animation.value, this._animation.value ],
                            radius: super.widget.radius!,
                        )
                        : LinearGradient(
                            begin: super.widget.begin,
                            end: super.widget.end,
                            colors: colors,
                            stops: [ this._animation.value, this._animation.value ],
                        )
                    ).createShader(bounds),
                    child: icon,
                );
            },
        );
    }
}
