import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stronzflix/backend/streamingcommunity.dart';
import 'package:stronzflix/backend/vixxcloud.dart';
import 'package:stronzflix/views/stronzflix.dart';
import 'package:fvp/fvp.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
    StreamingCommunity.instance;
    VixxCloud.instance;

    WidgetsFlutterBinding.ensureInitialized();
    registerWith(options: {'platforms': ['android', 'linux', 'windows']});
    if(Platform.isWindows || Platform.isLinux)
        await windowManager.ensureInitialized();

    runApp(const Stronzflix());
}
