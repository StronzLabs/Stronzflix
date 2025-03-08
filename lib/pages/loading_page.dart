import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stronzflix/backend/api/bindings/animesaturn.dart';
import 'package:stronzflix/backend/api/bindings/cb01.dart';
import 'package:stronzflix/backend/api/bindings/jwplayer.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/bindings/maxstream.dart';
import 'package:stronzflix/backend/api/bindings/mixdrop.dart';
import 'package:stronzflix/backend/api/bindings/stayonline.dart';
import 'package:stronzflix/backend/api/bindings/streamingcommunity.dart';
import 'package:stronzflix/backend/api/bindings/streampeaker.dart';
import 'package:stronzflix/backend/api/bindings/uprot.dart';
import 'package:stronzflix/backend/api/bindings/vixxcloud.dart';
import 'package:stronzflix/backend/api/bindings/vjsplayer.dart';
import 'package:stronzflix/backend/api/tune.dart';
import 'package:stronzflix/backend/sink/sink_manager.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:sutils/logic/loading/stronz_dynamic_loading_phase.dart';
import 'package:sutils/logic/loading/stronz_static_loading_phase.dart';
import 'package:sutils/ui/pages/stronz_loading_page.dart';

class LoadingPage extends StatelessWidget {
    const LoadingPage({super.key});

    @override
    Widget build(BuildContext context) {
        return StronzLoadingPage(
            splash: SvgPicture.asset("assets/logo.svg",
                width: 200,
                height: 200,
            ),
            onOffline: () async {
                await Settings.instance.unserialize();
                Settings.online = false;
                Settings.site = LocalSite.instance;
                await Settings.instance.serialize();
            },
            phases: [
                StronzStaticLoadingPhase(
                    weight: 0.01,
                    steps: () => [
                        Settings.instance.unserialize(),
                        Tuner.prepareCache(),
                    ]
                ),
                StronzDynamicLoadingPhase(
                    weight: 0.97,
                    allowedFails: 2,
                    steps: () => [
                        StreamingCommunity.instance.progress,
                        AnimeSaturn.instance.progress,
                        CB01.instance.progress,
                    ]
                ),
                StronzStaticLoadingPhase(
                    weight: 0.01,
                    steps: () => [
                        LocalSite.instance.initialized,
                        LocalPlayer.instance.initialized,
                        JWPlayer.instance.initialized,
                        VJSPlayer.instance.initialized,
                        Streampeaker.instance.initialized,
                        VixxCloud.instance.initialized,
                        MixDrop.instance.initialized,
                        Maxstream.instance.initialized,
                        StayOnline.instance.initialized,
                        UProt.instance.initialized,
                    ]
                ),
                StronzStaticLoadingPhase(
                    weight: 0.01,
                    steps: () => [
                        KeepWatching.instance.unserialize(),
                        SavedTitles.instance.unserialize(),
                        SinkManager.init(),
                    ]
                )
            ],
        );
    }
}
