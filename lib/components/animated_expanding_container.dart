import 'package:flutter/material.dart';

class AnimatedExpandingContainer extends StatelessWidget {
    final Widget unexpandedWidget;
    final Widget expandedWidget;
    final bool isExpanded;
    
    const AnimatedExpandingContainer({
        super.key,
        required this.unexpandedWidget,
        required this.expandedWidget,
        required this.isExpanded,
    });

    @override
    Widget build(BuildContext context) {
        return AnimatedCrossFade(
            firstCurve: Curves.fastLinearToSlowEaseIn,
            secondCurve: Curves.fastLinearToSlowEaseIn,
            firstChild: this.unexpandedWidget,
            secondChild: this.expandedWidget,
            crossFadeState: this.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 150)
        );
    }
}
