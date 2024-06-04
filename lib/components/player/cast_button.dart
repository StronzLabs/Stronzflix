import 'package:cast/device.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';
import 'package:stronzflix/utils/utils.dart';

class CastButton extends StatelessWidget {
    final void Function()? onOpened;
    final void Function()? onClosed;

    const CastButton({
        super.key,
        this.onOpened,
        this.onClosed,
    });

    Widget _buildEnableCastButton(BuildContext context, PlayerInfo playerInfo) {
        return FutureBuilder(
            future: playerInfo.devices,
            builder: (context, snapshot) {
                if(!snapshot.hasData || snapshot.data!.isEmpty)
                    return const SizedBox.shrink();

                List<CastDevice> devices = snapshot.data!;
                return PopupMenuButton(
                    onOpened: this.onOpened,
                    onCanceled: this.onClosed,
                    tooltip: '',
                    iconSize: 28,
                    icon: const Icon(Icons.cast),
                    position: PopupMenuPosition.under,
                    itemBuilder: (context) => [
                        for(CastDevice device in devices)
                            PopupMenuItem(
                                value: device,
                                child: Text(device.name),
                            )
                    ],
                    onSelected: (value) {
                        if(isFullscreen(context))
                            exitFullscreen(context);
                        KeepWatching.add(playerInfo.watchable, playerInfo.timestamp, playerInfo.duration);
                        playerInfo.startCasting(value);
                    }
                );
            }
        );
    }

    Widget _buildDisableCastButton(BuildContext context, PlayerInfo playerInfo) {
        return IconButton(
            icon: const Icon(Icons.cast_connected),
            onPressed: () {
                KeepWatching.add(playerInfo.watchable, playerInfo.timestamp, playerInfo.duration);
                playerInfo.stopCasting();
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        PlayerInfo playerInfo = FullScreenProvider.of<PlayerInfo>(context);
        return playerInfo.isCasting
            ? this._buildDisableCastButton(context, playerInfo)
            : this._buildEnableCastButton(context, playerInfo);
    }
}
