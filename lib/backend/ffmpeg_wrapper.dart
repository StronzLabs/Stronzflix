import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:process_run/process_run.dart';
import 'package:sutils/utils/expanded_platform.dart';

class FFmpegWrapper {

    /*
    https://github.com/BtbN/FFmpeg-Builds/releases
    ffmpeg-master-latest-win64-gpl.zip
    */
    static Shell? shell = EPlatform.isDesktop ? Shell() : null;

    static Future<void> run(String command) async {
        if(Platform.isLinux || Platform.isWindows) {
            String pefix = Platform.isWindows ? ".\\ffmpeg.exe" : "./ffmpeg";
            await shell!.run("$pefix $command");
        }
        else
            await FFmpegKit.execute(command);
    }
}
