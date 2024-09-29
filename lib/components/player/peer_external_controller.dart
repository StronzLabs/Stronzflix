import 'dart:async';

import 'package:stronz_video_player/stronz_video_player.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';

class PeerExternalController extends StronzExternalController {

    StronzControllerState _remoteState = StronzControllerState();
    set _playing(bool value) => this._remoteState = this._remoteState.copyWith(playing: value);

    late StreamSubscription<Message>? _subscription;

    @override
    Future<void> informState(StronzControllerState state) async {
        if(state.playing != null && this._remoteState.playing != state.playing) {
            this._playing = state.playing ?? false;
            if(state.playing == true)
                await PeerMessenger.play();
            else if(state.playing == false)
                    await PeerMessenger.pause();
        }
    }

    @override
    Future<void> initialize(Playable playable, void Function(StronzExternalControllerEvent) handler) async {
        this._subscription = PeerMessenger.messages.listen((message) {
            switch(message.type) {
                case MessageType.play:
                    this._playing = true;
                    handler(StronzExternalControllerEvent.play);
                    break;
                case MessageType.pause:
                    this._playing = false;
                    handler(StronzExternalControllerEvent.pause);
                    break;
                default:
                    break;
            }
        });
    }

    @override
    Future<void> dispose() async {
        await this._subscription?.cancel();
    }

    @override
    Future<void> switchTo(Playable playable) async {
    }
}