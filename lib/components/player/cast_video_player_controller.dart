import 'dart:async';

import 'package:stronz_cast/stronz_cast.dart';
import 'package:stronz_video_player/video_player.dart';

class CastVideoPlayerController extends StronzPlayerController {

    CastVideoPlayerController({
        super.externalControllers
    });

    @override
    Future<void> initialize(Playable playable, {StronzControllerState? initialState}) async {
        await super.initialize(playable, initialState: initialState);

        await StronzCastManager.loadMedia(super.tracks.masterSource);

        StronzCastManager.state.addListener(this._onStateChange);

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
        super.playing = StronzCastManager.state.mediaState.playing ?? super.playing;
        super.buffering = StronzCastManager.state.mediaState.buffering ?? super.buffering;
        super.completed = StronzCastManager.state.mediaState.completed ?? super.completed;
        super.position = StronzCastManager.state.mediaState.position ?? super.position;
        super.duration = StronzCastManager.state.mediaState.duration ?? super.duration;
    }

    @override
    Future<void> dispose() async {
        await StronzCastManager.stop();
        StronzCastManager.state.removeListener(this._onStateChange);
        super.dispose();
    }

    @override
    Future<bool> pause() async {
        if(!await super.pause())
            return false;
        await StronzCastManager.pause();
        return true;
    }

    @override
    Future<bool> play() async {
        if(!await super.play())
            return false;
        await StronzCastManager.play();
        return true;
    }

    @override
    Future<bool> seekTo(Duration position) async {
        if(!await super.seekTo(position))
            return false;
        await StronzCastManager.seekTo(position);
        return true;
    }

    @override
    Future<void> setVolume(double volume) async {
        await super.setVolume(volume);
        await StronzCastManager.setVolume(volume);
    }

    @override
    Future<void> switchTo(Playable playable) async {
        super.buffering = true;
        Uri uri = await playable.source;
        await StronzCastManager.loadMedia(uri);
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
