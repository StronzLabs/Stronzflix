import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';

class VolumeButton extends StatefulWidget {
    const VolumeButton({
        super.key,
    });

    @override
    State<VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<VolumeButton> with SingleTickerProviderStateMixin {

    late double _volume = playerController(super.context).volume;
    StreamSubscription<double>? _subscription;

    bool _hover = false;
    bool _mute = false;
    bool _dragging = false;
    double _savedVolume = 0.0;

    @override
    void setState(VoidCallback fn) {
        if (super.mounted)
            super.setState(fn);
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        this._subscription ??= playerController(super.context).stream.volume.listen(
            (event) => this.setState(() => this._volume = event)
        );
    }

    @override
    void dispose() {
        this._subscription?.cancel();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return MouseRegion(
            onEnter: (_) => this.setState(() => this._hover = true),
            onExit: (_) => this.setState(() => this._hover = false),
            child: Listener(
                onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                        if (event.scrollDelta.dy < 0)
                            playerController(context).setVolume((this._volume + 5.0).clamp(0.0, 100.0));
                        if (event.scrollDelta.dy > 0)
                            playerController(context).setVolume((this._volume - 5.0).clamp(0.0, 100.0));
                    }
                },
                child: Row(
                    children: [
                        const SizedBox(width: 4.0),
                        IconButton(
                            onPressed: () async {
                                if (this._mute) {
                                    this._mute = false;
                                    await playerController(context).setVolume(this._savedVolume);
                                }
                                else if (this._volume == 0.0) {
                                    // this._volume = 100.0;
                                    this._mute = false;
                                    await playerController(context).setVolume(100.0);
                                } else {
                                    this._savedVolume = this._volume;
                                    this._mute = true;
                                    await playerController(context).setVolume(0.0);
                                }

                                this.setState(() {});
                            },
                            iconSize: 28,
                            icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: this._volume == 0.0
                                    ? const Icon(
                                        Icons.volume_off,
                                        key: ValueKey(Icons.volume_off),
                                    )
                                    : this._volume < 50.0
                                        ? const Icon(
                                            Icons.volume_down,
                                            key: ValueKey(Icons.volume_down),
                                        )
                                        : const Icon(
                                            Icons.volume_up,
                                            key: ValueKey(Icons.volume_up),
                                        )
                            )
                        ),
                        AnimatedOpacity(
                            opacity: this._hover || this._dragging ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: AnimatedContainer(
                                width: this._hover || this._dragging ? (12.0 + (52.0) + 18.0) : 12.0,
                                duration: const Duration(milliseconds: 150),
                                child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                        children: [
                                            const SizedBox(width: 12.0),
                                            SizedBox(
                                                width: 52.0,
                                                child:  Slider(
                                                    onChangeStart: (_) => super.setState(() => this._dragging = true),
                                                    onChangeEnd: (_) => super.setState(() => this._dragging = false),
                                                    value: this._volume.clamp(0.0, 100.0),
                                                    min: 0.0,
                                                    max: 100.0,
                                                    onChanged: (value) async {
                                                        await playerController(context).setVolume(value);
                                                        this.setState(() => this._mute = false);
                                                    }
                                                ),
                                            ),
                                            const SizedBox(width: 18.0),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
