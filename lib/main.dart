import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/stronzflix.dart';
import 'package:fvp/fvp.dart';
import 'package:stronzflix/utils/platform.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    registerWith(options: {'platforms': [ 'linux', 'windows' ], 'video.decoders': [ 'DXVA', 'FFmpeg' ]});
    if(SPlatform.isMobile)
        await FlutterDownloader.initialize();

    runApp(const Stronzflix());
}
