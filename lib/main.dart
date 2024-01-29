import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/stronzflix.dart';
import 'package:fvp/fvp.dart';
import 'package:window_manager/window_manager.dart';
import 'package:stronzflix/utils/platform.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Backend.init();

    registerWith(options: {'platforms': [ 'linux', 'windows' ], 'video.decoders': [ 'DXVA' ]});
    if(SPlatform.isMobile)
        await FlutterDownloader.initialize();
    if(SPlatform.isDesktop)
        await windowManager.ensureInitialized();

    runApp(const Stronzflix());
}
