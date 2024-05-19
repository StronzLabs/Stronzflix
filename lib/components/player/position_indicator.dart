import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';

class PositionIndicator extends StatefulWidget {
    const PositionIndicator({
        super.key
    });

    @override
    State<PositionIndicator> createState() => _PositionIndicatorState();
}

class _PositionIndicatorState extends State<PositionIndicator> {
    late Duration _position = playerController(super.context).position;
    late Duration _duration = playerController(super.context).duration;

    final List<StreamSubscription> _subscriptions = [];

    @override
    void setState(VoidCallback fn) {
        if (this.mounted)
            super.setState(fn);
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        if (this._subscriptions.isEmpty)
            this._subscriptions.addAll([
                playerController(super.context).stream.position.listen(
                    (event) => this.setState(() => this._position = event)
                ),
                playerController(super.context).stream.duration.listen(
                    (event) => this.setState(() => this._duration = event)
                ),
            ]);
    }

    @override
    void dispose() {
        for (StreamSubscription subscription in this._subscriptions)
            subscription.cancel();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Text(
            '${this._position.label(reference: this._duration)} / ${this._duration.label(reference: this._duration)}',
            style: const TextStyle(
                fontSize: 17.0
            ),
        );
    }
}

extension _DurationExtension on Duration {
    String label({Duration? reference}) {
        reference ??= this;
        if (reference > const Duration(days: 1)) {
            final days = inDays.toString().padLeft(3, '0');
            final hours = (inHours - (inDays * 24)).toString().padLeft(2, '0');
            final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
            final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
            return '$days:$hours:$minutes:$seconds';
        } else if (reference > const Duration(hours: 1)) {
            final hours = inHours.toString().padLeft(2, '0');
            final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
            final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
            return '$hours:$minutes:$seconds';
        } else {
            final minutes = inMinutes.toString().padLeft(2, '0');
            final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
            return '$minutes:$seconds';
        }
    }
}
