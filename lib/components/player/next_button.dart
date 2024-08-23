import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';

class NextButton extends StatefulWidget {
    final double iconSize;
    final void Function()? onFocus;
    final void Function()? onFocusLost;

    const NextButton({
        super.key,
        this.iconSize = 28,
        this.onFocus,
        this.onFocusLost,
    });

    @override
    State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton> {

    final FocusNode _focusNode = FocusNode();
    late Watchable? _next;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        this._next = playerController(context).next;
    }

    @override
    void initState() {
        super.initState();
        this._focusNode.addListener(() {
            if (this._focusNode.hasFocus)
                widget.onFocus?.call();
            else
                widget.onFocusLost?.call();
        });
    }

    @override
    Widget build(BuildContext context) {
        if (this._next == null)
            return const SizedBox.shrink();

        return IconButton(
            focusNode: this._focusNode,
            onPressed: () => Provider.of<PlayerInfo>(context, listen: false).switchTo(this._next!),
            iconSize: widget.iconSize,
            icon: const Icon(Icons.skip_next),
        );
    }
}
