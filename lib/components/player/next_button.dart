import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';
import 'package:stronzflix/utils/utils.dart';

class NextButton extends StatefulWidget {

    const NextButton({
        super.key,
    });

    @override
    State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton> {

    late Watchable? _next;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        this._next = playerController(context).next;
    }

    @override
    Widget build(BuildContext context) {
        if (this._next == null)
            return const SizedBox.shrink();

        return IconButton(
            onPressed: () => FullScreenProvider.of<PlayerInfo>(context, listen: false).switchTo(this._next!),
            iconSize: 28.0,
            icon: const Icon(Icons.skip_next),
        );
    }
}
