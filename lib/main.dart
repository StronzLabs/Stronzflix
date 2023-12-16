import 'package:flutter/material.dart';
import 'package:stronzflix/backend/streamingcommunity.dart';
import 'package:stronzflix/backend/vixxcloud.dart';
import 'package:stronzflix/utils/storage.dart';
import 'package:stronzflix/views/stronzflix.dart';
import 'package:fvp/fvp.dart';
import 'package:window_manager/window_manager.dart';
import 'package:stronzflix/utils/platform.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    await Storage.init();
    StreamingCommunity.instance;
    VixxCloud.instance;

    registerWith(options: {'platforms': ['android', 'linux', 'windows']});
    if(SPlatform.isDesktop)
        await windowManager.ensureInitialized();

    runApp(const Stronzflix());
}
