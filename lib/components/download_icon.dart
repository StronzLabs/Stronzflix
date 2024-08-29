import 'package:flutter/material.dart';

class DownloadIcon extends StatefulWidget {
    final bool isDownloading;
    
    const DownloadIcon({
        super.key,
        this.isDownloading = false,
    });

    @override
    State<DownloadIcon> createState() => _DownloadIconState();
}

class _DownloadIconState extends State<DownloadIcon> with SingleTickerProviderStateMixin {
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
        Widget icon = const Icon(Icons.download);
        if(!this.widget.isDownloading)
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
                            Colors.white,
                        ],
                        stops: [this._animation.value, this._animation.value],
                    ).createShader(bounds),
                    child: icon,
                );
            },
        );
    }
}
