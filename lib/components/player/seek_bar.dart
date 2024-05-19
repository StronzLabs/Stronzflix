import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';

class SeekBar extends StatefulWidget {
    final void Function()? onSeekStart;
    final void Function()? onSeekEnd;

    const SeekBar({
        super.key,
        this.onSeekStart,
        this.onSeekEnd,
    });

    @override
    State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
    bool _hover = false;
    bool _click = false;
    double _slider = 0.0;
    bool _seeking = false;

    late Duration _position = playerController(context).position;
    late Duration _duration = playerController(context).duration;
    late Duration _buffer = playerController(context).buffer;

    final List<StreamSubscription> _subscriptions = [];

    @override
    void setState(VoidCallback fn) {
        if (super.mounted)
            super.setState(fn);
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        if (this._subscriptions.isEmpty)
            this._subscriptions.addAll([
                playerController(context).stream.completed.listen(
                    (event) =>  this.setState(() => this._position = Duration.zero)
                ),
                playerController(context).stream.position.listen(
                    (event) => this.setState(() { if (!this._click && !this._seeking) this._position = event;})
                ),
                playerController(context).stream.duration.listen(
                    (event) => this.setState(() => this._duration = event)
                ),
                playerController(context).stream.buffer.listen(
                    (event) => this.setState(() => this._buffer = event)
                ),
            ]);
    }

    @override
    void dispose() {
        for (StreamSubscription subscription in this._subscriptions)
            subscription.cancel();
        super.dispose();
    }

    void _onPointerMove(PointerMoveEvent e, BoxConstraints constraints) {
        double percent = e.localPosition.dx / constraints.maxWidth;
        this.setState(() {
            this._hover = true;
            this._slider = percent.clamp(0.0, 1.0);
        });
    }

    void _onPointerDown() {
        super.widget.onSeekStart?.call();
        this.setState(() => this._click = true);
    }

    void _onPointerUp() {
        Duration target = this._duration * this._slider;
        this._seeking = true;
        playerController(context).seekTo(target).then((value) => this._seeking = false);
        this.setState(() {
            this._click = false;
            this._position = target;
        });
        super.widget.onSeekEnd?.call();
    }

    void _onHover(PointerHoverEvent e, BoxConstraints constraints) {
        double percent = e.localPosition.dx / constraints.maxWidth;
        this.setState(() {
            this._hover = true;
            this._slider = percent.clamp(0.0, 1.0);
        });
    }

    void _onEnter(PointerEnterEvent e, BoxConstraints constraints) {
        double percent = e.localPosition.dx / constraints.maxWidth;
        this.setState(() {
            this._hover = true;
            this._slider = percent.clamp(0.0, 1.0);
        });
    }

    void _onExit(PointerExitEvent e, BoxConstraints constraints) {
        this.setState(() {
            this._hover = false;
            this._slider = 0.0;
        });
    }

    double get positionPercent {
        if (this._position == Duration.zero || this._duration == Duration.zero)
            return 0.0;
        else
            return (this._position.inMilliseconds / this._duration.inMilliseconds).clamp(0.0, 1.0);
    }

    double get bufferPercent {
        if (this._buffer == Duration.zero || this._duration == Duration.zero)
            return 0.0;
        else
            return (this._buffer.inMilliseconds / this._duration.inMilliseconds).clamp(0.0, 1.0);
    }

    @override
    Widget build(BuildContext context) {
        return Container(
        clipBehavior: Clip.none,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LayoutBuilder(
                builder: (context, constraints) => MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onHover: (e) => this._onHover(e, constraints),
                    onEnter: (e) => this._onEnter(e, constraints),
                    onExit: (e) => this._onExit(e, constraints),
                    child: Listener(
                        onPointerMove: (e) => this._onPointerMove(e, constraints),
                        onPointerDown: (e) => this._onPointerDown(),
                        onPointerUp: (e) => this._onPointerUp(),
                        child: Container(
                            color: Colors.transparent,
                            width: constraints.maxWidth,
                            height: 36.0,
                            child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.centerLeft,
                                children: [
                                    AnimatedContainer(
                                        width: constraints.maxWidth,
                                        height: this._hover ? 5.6 : 3.2,
                                        alignment: Alignment.centerLeft,
                                        duration: const Duration(milliseconds: 150),
                                        color: const Color(0x3DFFFFFF),
                                        child: Stack(
                                            clipBehavior: Clip.none,
                                            alignment: Alignment.centerLeft,
                                            children: [
                                                Container(
                                                    width: constraints.maxWidth * this._slider,
                                                    color: const Color(0x3DFFFFFF),
                                                ),
                                                Container(
                                                    width: constraints.maxWidth * bufferPercent,
                                                    color:const Color(0x3DFFFFFF),
                                                ),
                                                Container(
                                                    width: this._click
                                                        ? constraints.maxWidth * this._slider
                                                        : constraints.maxWidth * positionPercent,
                                                    color: Theme.of(context).colorScheme.primary,
                                                ),
                                            ],
                                        ),
                                    ),
                                    Positioned(
                                        left: this._click
                                            ? (constraints.maxWidth - 12 / 2) * this._slider
                                            : (constraints.maxWidth - 12 / 2) * positionPercent,
                                        child: AnimatedContainer(
                                            width: this._hover || this._click ? 12 : 0.0,
                                            height: this._hover || this._click ? 12 : 0.0,
                                            duration: const Duration(milliseconds: 150),
                                            decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(12 / 2),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}
