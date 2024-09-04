import 'package:flutter/material.dart';
import 'package:stronz_video_player/stronz_video_player.dart';
import 'package:stronzflix/components/resource_image.dart';
import 'package:sutils/sutils.dart';

class CastVideoView extends StatefulWidget {
    const CastVideoView({super.key});

    @override
    State<CastVideoView> createState() => _CastVideoViewState();
}

class _CastVideoViewState extends State<CastVideoView> with StronzPlayerControl, StreamListener {

    late Playable _playable = super.controller(super.context).playable;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        super.updateSubscriptions([
            super.controller(super.context).stream.title.listen(
                (event) => this.setState(() => this._playable = super.controller(super.context, listen: false).playable)
            )
        ]);
    }

    @override
    void dispose() {
        super.disposeSubscriptions();
        super.dispose();
    }

    @override
    void setState(VoidCallback fn) {
        if(super.mounted)
            super.setState(fn);
    }

    @override
    Widget build(BuildContext context) {
        Uri uri = this._playable.thumbnail;
        return ResourceImage(uri: uri, fit: BoxFit.contain);
    }
}
