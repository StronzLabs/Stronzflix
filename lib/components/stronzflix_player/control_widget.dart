import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ControlWidget extends StatelessWidget {
    final Widget child;
    final bool hidden;
    final bool ignorePointer;
    final void Function()? onTap;
    final void Function(PointerHoverEvent)? onHover;
    final void Function(PointerEnterEvent)? onEnter;
    final void Function(PointerExitEvent)? onExit;
    
    const ControlWidget({
        super.key,
        required this.hidden,
        required this.child,
        this.ignorePointer = true,
        this.onTap,
        this.onHover,
        this.onEnter,
        this.onExit
    });

    @override
    Widget build(BuildContext context) {
        return AnimatedOpacity(
            opacity: this.hidden ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
                ignoring : this.ignorePointer && this.hidden,
                child: GestureDetector(
                    onTap: this.onTap,
                    child: MouseRegion(
                        onHover: this.onHover,
                        onEnter: this.onEnter,
                        onExit: this.onExit,
                        child: this.child
                    )
                )
            )
        );
    }
}
