import 'package:flutter/material.dart';
import 'package:stronz_video_player/stronz_video_player.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/cast/cast.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/cast_button.dart';
import 'package:stronzflix/components/player/cast_video_player_controller.dart';
import 'package:stronzflix/components/player/cast_video_view.dart';
import 'package:stronzflix/components/player/chat_button.dart';
import 'package:sutils/sutils.dart';

class PlayerPage extends StatefulWidget {
    const PlayerPage({super.key});

    @override
    State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with StreamListener {
    
    bool _exited = false;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        super.updateSubscriptions([
            PeerMessenger.messages.listen((message) {
                switch(message.type) {
                    case MessageType.stopWatching:
                        if(super.mounted && !this._exited)
                            Navigator.of(super.context).pop();
                        break;

                    default:
                        break;
                }
            })
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
        Watchable watchable = ModalRoute.of(super.context)!.settings.arguments as Watchable;

        return PopScope(
            onPopInvokedWithResult: (didPop, result) {
                PeerMessenger.stopWatching();
                this._exited = true;
            },
            child: Scaffold(
                backgroundColor: Colors.black,
                body: ListenableBuilder(
                    listenable: CastManager.state,
                    builder: (context, _) => StronzVideoPlayer(
                        playable: watchable,
                        controllerState: StronzControllerState.autoPlay(
                            position: Duration(
                                seconds: KeepWatching.getTimestamp(watchable) ?? 0
                            )
                        ),
                        onBeforeExit: (controller) {
                            if(controller.duration.inSeconds != 0)
                                KeepWatching.add(controller.playable as Watchable, controller.position.inSeconds, controller.duration.inSeconds);
                        },
                        additionalControlsBuilder: (context, onMenuOpened, onMenuClosed) => [
                            CastButton(
                                onOpened: onMenuOpened,
                                onClosed: onMenuClosed,
                            ),
                            const ChatButton(),
                        ],
                        videoBuilder: !CastManager.connected ? null : (context) => const SizedBox.expand(
                            child: CastVideoView()
                        ),
                        controller: CastManager.connected ? CastVideoPlayerController() : null
                    )
                )
            )
        );
    }
}
