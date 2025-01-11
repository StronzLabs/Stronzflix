import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stronz_video_player/components/video_player_view.dart';
import 'package:stronz_video_player/stronz_video_player.dart';
import 'package:stronzflix/components/floating_player_context.dart';
import 'package:sutils/utils.dart';

class FloatingPlayerButton extends StatelessWidget with StronzPlayerControl {
    final double iconSize;
    final void Function()? onClose;
    final void Function()? onOpen;
    final void Function()? onExpand;
    
    const FloatingPlayerButton({
        super.key,
        this.onClose,
        this.onOpen,
        this.onExpand,
        this.iconSize = 28
    });

    void _showFloatingPlayer(BuildContext context) {
        if(FullScreen.checkSync())
            FullScreen.set(false);

        StronzPlayerController controller = super.controller(context, listen: false);
        FloatingPlayerContext.of(context).show(
            (_) => Provider<StronzPlayerController>.value(
                value: controller,
                child: const Center(
                    child: VideoPlayerView()
                )
            ),
            onClose: this.onClose,
            onExpand: this.onExpand
        );
        this.onOpen?.call();
    }

    @override
    Widget build(BuildContext context) {
        if(EPlatform.isTV)
            return const SizedBox.shrink();

        return IconButton(
            icon: const Icon(Icons.picture_in_picture_alt_rounded),
            iconSize: this.iconSize,
            onPressed: () => this._showFloatingPlayer(context),
        );
    }
}
