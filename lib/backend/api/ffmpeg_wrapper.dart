import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:process_run/process_run.dart';
import 'package:stronzflix/utils/platform.dart';

class FFmpegWrapper {

    /*
    https://github.com/BtbN/FFmpeg-Builds/releases
    ffmpeg-master-latest-win64-gpl.zip
    */
    static Shell? shell = SPlatform.isDesktop ? Shell() : null;

    static Future<void> run(String command) async {
        if(SPlatform.isMobile)
            await FFmpegKit.execute(command);
        else {
            String pefix = Platform.isWindows ? ".\\ffmpeg.exe" : "./ffmpeg";
            await shell!.run("$pefix $command");
        }
    }
}