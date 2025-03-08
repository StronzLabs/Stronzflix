import 'package:flutter/material.dart';
import 'package:stronz_video_player/video_player.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/cast/cast.dart';
import 'package:stronzflix/backend/sink/sink_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/cast_button.dart';
import 'package:stronzflix/components/player/cast_video_player_controller.dart';
import 'package:stronzflix/components/player/cast_video_view.dart';
import 'package:stronzflix/components/player/chat_button.dart';
import 'package:stronzflix/components/player/floating_player_button.dart';
import 'package:stronzflix/components/player/peer_external_controller.dart';
import 'package:stronzflix/stronzflix.dart';
import 'package:sutils/utils.dart';

class PlayerPageArguments {
    final Watchable watchable;
    final StronzPlayerController? controller;

    const PlayerPageArguments(this.watchable, {
        this.controller,
    });
}

class PlayerPage extends StatefulWidget {
    final Watchable watchable;
    final StronzPlayerController? controller;

    const PlayerPage({
        required this.watchable,   
        this.controller, 
        super.key,
    });

    @override
    State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with StreamListener {
    
    bool _exited = false;
    bool _floatingPlayerVisible = false;

    late StronzPlayerController? _controller = super.widget.controller;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        super.updateSubscriptions([
            SinkMessenger.messages.listen((message) {
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
        if(!this._floatingPlayerVisible)
            this._controller?.dispose();
        super.disposeSubscriptions();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return PopScope(
            onPopInvokedWithResult: (didPop, result) {
                SinkMessenger.stopWatching();
                this._exited = true;
            },
            child: Scaffold(
                backgroundColor: Colors.black,
                body: ListenableBuilder(
                    listenable: CastManager.state,
                    builder: (context, _) {
                        if(CastManager.connected && this._controller is! CastVideoPlayerController)
                            this._controller = CastVideoPlayerController([MediaSessionExternalController(), PeerExternalController()]);
                        else if(!CastManager.connected && this._controller is! NativePlayerController)
                            this._controller = NativePlayerController([MediaSessionExternalController(), PeerExternalController()]);

                        return StronzVideoPlayer(
                            playable: super.widget.watchable,
                            controllerState: StronzControllerState.autoPlay(
                                position: Duration(
                                    seconds: KeepWatching.getTimestamp(super.widget.watchable) ?? 0
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
                                FloatingPlayerButton(
                                    onClose: () {
                                        this._floatingPlayerVisible = false;
                                        if(this._exited && this._controller != null) {
                                            KeepWatching.add(this._controller!.playable as Watchable, this._controller!.position.inSeconds, this._controller!.duration.inSeconds);
                                            this._controller?.dispose();
                                        }
                                    },
                                    onOpen: () {
                                        this._floatingPlayerVisible = true;
                                        Navigator.of(context).pop();
                                    },
                                    onExpand: () {
                                        Stronzflix.navigatorKey.currentState!.pushNamed('/player',
                                            arguments: PlayerPageArguments(super.widget.watchable, controller: this._controller)
                                        );
                                    },
                                )
                            ],
                            videoBuilder:CastManager.connected
                                ? (context) => const CastVideoView()
                                : null,
                            controller: this._controller!,
                        );
                    }
                )
            )
        );
    }
}
