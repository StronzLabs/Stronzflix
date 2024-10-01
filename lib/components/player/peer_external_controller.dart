import 'dart:async';

import 'package:stronz_video_player/stronz_video_player.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';

class PeerExternalController extends StronzExternalController {

    StronzControllerState _remoteState = StronzControllerState();
    set _playing(bool value) => this._remoteState = this._remoteState.copyWith(playing: value);
    set _buffering(bool value) => this._remoteState = this._remoteState.copyWith(buffering: value);
    bool _justSeeked = false;

    late StreamSubscription<Message>? _subscription;

    @override
    Future<void> informState(StronzControllerState state) async {
        if(state.playing != null && this._remoteState.playing != state.playing) {
            this._playing = state.playing ?? false;
            if(state.playing == true)
                await PeerMessenger.play();
            else if(state.playing == false)
                    await PeerMessenger.pause();
            print("Sending: ${state.playing ?? false ? "Play" : "Pause"}");
        }

        if(state.buffering != null && this._remoteState.buffering != state.buffering) {
            this._buffering = state.buffering ?? false;
            if(state.buffering == true)
                await PeerMessenger.buffering();
            else if(state.buffering == false)
                await PeerMessenger.ready();
            print("Sending: ${state.buffering ?? false ? "Buffering" : "Ready"}");
        }
    }

    @override
    Future<void> onEvent(StronzExternalControllerEvent event, {dynamic arg}) async {
        switch(event) {
            case StronzExternalControllerEvent.seekTo:
                if (!this._justSeeked) {
                    this._justSeeked = true;
                    await PeerMessenger.seek(arg.inSeconds);
                }
                this._justSeeked = false;
                break;
            default:
                break;
        }
    }

    @override
    Future<void> initialize(Playable playable, Future<void> Function(StronzExternalControllerEvent event, {dynamic arg}) handler) async {
        this._subscription = PeerMessenger.messages.listen((message) {
            print("Received message: ${message.type}");
            switch(message.type) {
                case MessageType.play:
                    this._playing = true;
                    handler(StronzExternalControllerEvent.play);
                    break;
                case MessageType.pause:
                    this._playing = false;
                    handler(StronzExternalControllerEvent.pause);
                    break;
                case MessageType.seek:
                    handler(StronzExternalControllerEvent.seekTo, arg: Duration(seconds: int.parse(message.data!)));
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
