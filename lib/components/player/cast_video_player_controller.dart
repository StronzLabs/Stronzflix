import 'dart:async';

import 'package:stronz_video_player/stronz_video_player.dart';
import 'package:stronzflix/backend/cast/cast.dart';

class CastVideoPlayerController extends StronzPlayerController {

    CastVideoPlayerController(super.externalControllers);

    @override
    Future<void> initialize(Playable playable, {StronzControllerState? initialState}) async {
        await super.initialize(playable, initialState: initialState);

        await CastManager.loadMedia(super.tracks.masterSource);

        CastManager.state.addListener(this._onStateChange);

        if(initialState == null)
            return;
        if(initialState.playing ?? false)
            await this.play();
        if(initialState.position != null)
            await this.seekTo(initialState.position!);
        if(initialState.volume != null)
            await this.setVolume(initialState.volume!);
    }

    void _onStateChange() {
        super.playing = CastManager.state.mediaState.playing ?? super.playing;
        super.buffering = CastManager.state.mediaState.buffering ?? super.buffering;
        super.completed = CastManager.state.mediaState.completed ?? super.completed;
        super.position = CastManager.state.mediaState.position ?? super.position;
        super.duration = CastManager.state.mediaState.duration ?? super.duration;
    }

    @override
    Future<void> dispose() async {
        await CastManager.stop();
        CastManager.state.removeListener(this._onStateChange);
        super.dispose();
    }

    @override
    Future<bool> pause() async {
        if(!await super.pause())
            return false;
        await CastManager.pause();
        return true;
    }

    @override
    Future<bool> play() async {
        if(!await super.play())
            return false;
        await CastManager.play();
        return true;
    }

    @override
    Future<bool> seekTo(Duration position) async {
        if(!await super.seekTo(position))
            return false;
        await CastManager.seekTo(position);
        return true;
    }

    @override
    Future<void> setVolume(double volume) async {
        await super.setVolume(volume);
        await CastManager.setVolume(volume);
    }

    @override
    Future<void> switchTo(Playable playable) async {
        super.buffering = true;
        Uri uri = await playable.source;
        await CastManager.loadMedia(uri);
        await super.switchTo(playable);
        super.buffering = false;
    }

    @override
    Future<void> setAudioTrack(AudioTrack? track) => throw UnimplementedError();
    @override
    Future<void> setCaptionTrack(CaptionTrack? track) => throw UnimplementedError();
    @override
    Future<void> setVideoTrack(VideoTrack? track) => throw UnimplementedError();
}
