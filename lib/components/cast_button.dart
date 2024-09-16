import 'package:cast/device.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/cast.dart';
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

    List<CastDevice> _devices = CastManager.devices;
    bool _discovering = CastManager.discovering;
    bool _connected = CastManager.connected;
    bool _connecting = CastManager.connecting;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        super.updateSubscriptions([
            CastManager.devicesStream.listen(
                (event) => this.setState(() => this._devices = event)
            ),
            CastManager.discoveringStream.listen(
                (event) => this.setState(() => this._discovering = event)
            ),
            CastManager.connectedStream.listen(
                (event) => this.setState(() => this._connected = event)
            ),
            CastManager.connectingStream.listen(
                (event) => this.setState(() => this._connecting = event)
            )
        ]);
    }

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

        List<PopupMenuItem> options = this._connected
            ? [
                const PopupMenuItem(
                    value: 0,
                    child: Text("Disconnetti"),
                )
            ] : [
                for(CastDevice device in this._devices)
                    PopupMenuItem(
                        value: device,
                        enabled: !this._discovering,
                        child: Text(device.name),
                    ),
                PopupMenuItem(
                    value: 0,
                    child: this._discovering
                        ? const Text("Ricerca in corso...")
                        : const Text("Esegui ricerca"),
                )
            ];

        return PopupMenuButton(
            onOpened: this.widget.onOpened,
            onCanceled: this.widget.onClosed,
            tooltip: '',
            iconSize: 28,
            enabled: !this._connecting && !this._discovering,
            icon: AnimatedGradientIcon(
                icon: this._connected ? Icons.cast_connected : Icons.cast,
                begin: Alignment.bottomLeft,
                tint: Colors.grey,
                radius: 0.6,
                reverse: true,
                animated: this._discovering || this._connecting,
            ),
            position: PopupMenuPosition.under,
            itemBuilder: (context) => options,
            onSelected: (value) async {
                if(value == 0) {
                    if(this._connected) {
                        await CastManager.disconnect();
                        return;
                    }

                    if(this._discovering)
                        return;

                    this.setState(() => this._discovering = true);
                    await CastManager.startDiscovery();
                    return;
                }

                if(await FullScreen.check())
                    await FullScreen.set(false);

                CastManager.connect(value as CastDevice);
            },
        );
    }
}
