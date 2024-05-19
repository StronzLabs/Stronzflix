import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/player/desktop_video_controls.dart';
import 'package:stronzflix/components/player/stronzflix_player_controller.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';

class CastView extends StatefulWidget {
    final Uri uri;
    
    const CastView({
        super.key,
        required this.uri
    });

    @override
    State<CastView> createState() => _CastViewState();
}

class _CastViewState extends State<CastView> {

    final CastPlayerController _controller = CastPlayerController();
    final AsyncMemoizer _controllerMemorizer = AsyncMemoizer();
    
    Widget _buildBackground(BuildContext context, Watchable watchable) {
        late String url = watchable is Film
            ? watchable.banner
            : watchable is Episode
                ? watchable.season.series.banner
                : throw Exception('Unknown watchable type');

        if(url.startsWith("http"))
            return Image.network(url, fit: BoxFit.contain);
        else
            return Image.file(File(url), fit: BoxFit.contain);
    }

    @override
    Widget build(BuildContext context) {
        PlayerInfo playerInfo = Provider.of<PlayerInfo>(context);
        return Center(
            child: Provider<StronzflixPlayerController>(
                create: (_) => this._controller,
                child: FutureBuilder(
                    future: this._controllerMemorizer.runOnce(
                        () => this._controller.initialize(super.widget.uri, playerInfo.startAt, playerInfo.device!)
                    ),
                    builder: (context, snapshot) {
                        if(snapshot.connectionState != ConnectionState.done)
                            return const CircularProgressIndicator();

                        return Stack(
                            children: [
                                SizedBox.expand(
                                    child: this._buildBackground(context, playerInfo.watchable)
                                ),
                                const DesktopVideoControls(),
                            ],
                        );
                    }
                )
            ),
        );
    }

    @override
    void dispose() {
        this._controller.dispose();
        super.dispose();
    }
}