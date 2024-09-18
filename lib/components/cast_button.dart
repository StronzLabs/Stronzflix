import 'package:flutter/material.dart';
import 'package:stronzflix/backend/cast/cast.dart';
import 'package:stronzflix/components/animated_gradient_icon.dart';
import 'package:sutils/sutils.dart';

class CastButton extends StatefulWidget {
    final double iconSize;
    final void Function()? onOpened;
    final void Function()? onClosed;

    const CastButton({
        super.key,
        this.iconSize = 28,
        this.onOpened,
        this.onClosed,
    });

    @override
    State<CastButton> createState() => _CastButtonState();
}

class _CastButtonState extends State<CastButton> with StreamListener {

    @override
    void setState(VoidCallback fn) {
        if(super.mounted)
            super.setState(fn);
    }

    @override
    void dispose() {
        super.disposeSubscriptions();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        if(EPlatform.isTV)
            return const SizedBox.shrink();

        List<PopupMenuItem<Object>> buildOptions(context) => CastManager.connected
            ? [
                const PopupMenuItem(
                    value: 0,
                    child: Text("Disconnetti"),
                )
            ] : [
                for(CasterDevice device in CastManager.devices)
                    PopupMenuItem(
                        value: device,
                        child: Text(device.name),
                    ),
                const PopupMenuItem(
                    value: 0,
                    child: Text("Esegui ricerca"),
                )
            ];

        return ListenableBuilder(
            listenable: CastManager.state,
            builder: (context, _) => PopupMenuButton(
                onOpened: this.widget.onOpened,
                onCanceled: this.widget.onClosed,
                tooltip: '',
                iconSize: 28,
                enabled: !CastManager.connecting && !CastManager.discovering,
                icon: AnimatedGradientIcon(
                    icon: CastManager.connected ? Icons.cast_connected : Icons.cast,
                    begin: Alignment.bottomLeft,
                    tint: Colors.grey,
                    radius: 0.6,
                    reverse: true,
                    animated: CastManager.discovering || CastManager.connecting,
                ),
                position: PopupMenuPosition.under,
                itemBuilder: buildOptions,
                onSelected: (value) async {
                    if(value is! CasterDevice) {
                        if(CastManager.connected) {
                            await CastManager.disconnect();
                            return;
                        }

                        await CastManager.discovery();
                        return;
                    }

                    if(await FullScreen.check())
                        await FullScreen.set(false);

                    CastManager.connect(value);
                },
            )
        );
    }
}
