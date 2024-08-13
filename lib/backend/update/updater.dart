import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:process_run/process_run.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

abstract class Updater {

    static Future<Map<String, dynamic>> get latestRelease async =>
        jsonDecode(await http.get('https://api.github.com/repos/Bonfra04/Stronzflix/releases/latest'));

    static Future<String> get platformUrl async {
        String platform;
        if(Platform.isAndroid)
            platform = ".apk";
        else if(Platform.isWindows)
            platform = ".msi";
        else if(Platform.isLinux)
            platform = "Linux";
        else if(Platform.isMacOS)
            platform = "MacOS";
        else
            throw Exception("Unsupported platform");

        List<Map<String, dynamic>> assets = (await Updater.latestRelease)['assets']
            .map<Map<String, dynamic>>((dynamic asset) => asset as Map<String, dynamic>).toList();

        for (Map<String, dynamic> asset in assets) {
            if(asset['name'].toString().contains(platform)) {
                String url = asset['browser_download_url'];
                return url;
            }
        }

        throw Exception("No asset found for platform ${platform}");
    }

    Future<Stream<double>?> doUpdate();

    static Updater create() {
        if(Platform.isAndroid)
            return AndroidUpdater();
        else if(Platform.isWindows)
            return WindowsUpdater();
        else
            return GenericUpdater();
    } 
}

class AndroidUpdater extends Updater {

    @override
    Future<Stream<double>?> doUpdate() async {
        final task = DownloadTask(
            url: await Updater.platformUrl,
            baseDirectory: BaseDirectory.temporary,
            filename: 'Stronzflix.apk'
        );

        final StreamController<double> progressController = StreamController<double>.broadcast();

        FileDownloader().download(task,
            onProgress: (progress) => progressController.add(progress)
        ).then((result) async {
            await FileDownloader().openFile(task: result.task);
        });

        return progressController.stream;
    }
}

class WindowsUpdater extends Updater {

    @override
    Future<Stream<double>?> doUpdate() async {
        final task = DownloadTask(
            url: await Updater.platformUrl,
            baseDirectory: BaseDirectory.temporary
        );

        final StreamController<double> progressController = StreamController<double>.broadcast();

        FileDownloader().download(task,
            onProgress: (progress) => progressController.add(progress)
        ).then((result) async {
            String path = await result.task.filePath();
            String command = 'msiexec /i "${path}" /qb /norestart';
            try {
                await Shell().run(command);
            } catch (_) {}
            exit(0);
        });

        return progressController.stream;
    }
}

class GenericUpdater extends Updater {
    @override
    Future<Stream<double>?> doUpdate() async {
        Uri uri = Uri.parse(await Updater.platformUrl);
        if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
        } else {
            throw 'Could not launch ${uri}';
        }
        return null;
    }
}
