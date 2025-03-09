import 'package:flutter/material.dart';
import 'package:stronzflix/components/animated_gradient_icon.dart';
import 'package:sutils/utils.dart';
import 'package:stronz_cast/stronz_cast.dart';

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

        List<PopupMenuItem<Object>> buildOptions(context) => StronzCastManager.connected
            ? [
                const PopupMenuItem(
                    value: 0,
                    child: Text("Disconnetti"),
                )
            ] : [
                for(StronzCasterDevice device in StronzCastManager.devices)
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
            listenable: StronzCastManager.state,
            builder: (context, _) => PopupMenuButton(
                onOpened: this.widget.onOpened,
                onCanceled: this.widget.onClosed,
                tooltip: '',
                iconSize: 28,
                enabled: !StronzCastManager.connecting && !StronzCastManager.discovering,
                icon: AnimatedGradientIcon(
                    icon: StronzCastManager.connected ? Icons.cast_connected : Icons.cast,
                    begin: Alignment.bottomLeft,
                    tint: Colors.grey,
                    radius: 0.6,
                    reverse: true,
                    animated: StronzCastManager.discovering || StronzCastManager.connecting,
                ),
                position: PopupMenuPosition.under,
                itemBuilder: buildOptions,
                onSelected: (value) async {
                    if(value is! StronzCasterDevice) {
                        if(StronzCastManager.connected) {
                            await StronzCastManager.disconnect();
                            return;
                        }

                        await StronzCastManager.discovery();
                        return;
                    }

                    if(await FullScreen.check())
                        await FullScreen.set(false);

                    StronzCastManager.connect(value);
                },
            )
        );
    }
}
