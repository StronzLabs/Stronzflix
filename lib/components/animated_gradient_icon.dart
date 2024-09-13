import 'package:flutter/material.dart';

class AnimatedGradientIcon extends StatefulWidget {
    final IconData icon;
    final bool animated;
    
    const AnimatedGradientIcon({
        super.key,
        required this.icon,
        this.animated = true,
    });

    @override
    State<AnimatedGradientIcon> createState() => _AnimatedGradientIconState();
}

class _AnimatedGradientIconState extends State<AnimatedGradientIcon> with SingleTickerProviderStateMixin {
    late final AnimationController _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 750),
    );
    late final Animation _animation = Tween(
        begin: 0.0,
        end: 1.0,
    ).animate(this._animationController);

    @override
    void initState() {
        super.initState();
        this._animationController.repeat();
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

        return AnimatedBuilder(
            animation: this._animationController,
            builder: (context, child) {
                return ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).iconTheme.color!
                        ],
                        stops: [this._animation.value, this._animation.value],
                    ).createShader(bounds),
                    child: icon,
                );
            },
        );
    }
}
