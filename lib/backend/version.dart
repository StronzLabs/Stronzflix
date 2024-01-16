
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;
import 'dart:convert';

class VersionChecker
{
    static Map<String, dynamic>? __latestRelease;

    static Future<Map<String, dynamic>> get _latestRelease async
    {
        if(VersionChecker.__latestRelease == null) {
            String jsonString = await http.get('https://api.github.com/repos/Bonfra04/Stronzflix/releases/latest');
            VersionChecker.__latestRelease = jsonDecode(jsonString);
        }

        return VersionChecker.__latestRelease!;
    }

    static Future<String> _getLastVersion() async
    {
        Map<String, dynamic> release = await VersionChecker._latestRelease;
        String version = release['name'].toString().split("Stronzflix ")[1];
        return version;
    }

    static Future<String> _getCurrentVersion() async
    {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        return packageInfo.version;
    }

    static Future<bool> shouldUpdate() async
    {
        try {
            String currentVersion = await _getCurrentVersion();
            String lastVersion = await _getLastVersion();
            return currentVersion != lastVersion;
        } catch (_) {
            return false;
        }
    }

    static Future<String> _getPlatformUrl() async {
        String platform;
        if(Platform.isAndroid)
            platform = ".apk";
        else if(Platform.isWindows)
            platform = "Windows";
        else if(Platform.isLinux)
            platform = "Linux";
        else
            throw Exception("Unsupported platform");

        List<Map<String, dynamic>> assets = (await VersionChecker._latestRelease)['assets']
            .map<Map<String, dynamic>>((dynamic asset) => asset as Map<String, dynamic>).toList();

        for (Map<String, dynamic> asset in assets) {
            if(asset['name'].toString().contains(platform)) {
                String url = asset['browser_download_url'];
                return url;
            }
        }

        throw Exception("No asset found for platform $platform");
    }

    static Future<void> _updateDesktop(String downloadUrl) async {
        await SPlatform.launchURL(downloadUrl);
    }

    static Future<void> cleanCache() async {
        try {
            String directory = (await getExternalStorageDirectory())!.absolute.path;
            File file = File("${directory}/Stronzflix.apk");
            if(await file.exists())
                await file.delete();
        } catch (_) {}
    }

    @pragma('vm:entry-point')
    static void downloadCallback(String id, int status, int progress) {
        final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
        send!.send([id, status, progress]);
    }

    static final ReceivePort _port = ReceivePort();

    static void _updateMobile(String downloadUrl) async {
        String directory = (await getExternalStorageDirectory())!.absolute.path;
        String? taskId;

        IsolateNameServer.registerPortWithName(VersionChecker._port.sendPort, 'downloader_send_port');
        VersionChecker._port.listen((dynamic data) {
            DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1]);
            
            if(status == DownloadTaskStatus.complete) {
                IsolateNameServer.removePortNameMapping('downloader_send_port');
                FlutterDownloader.open(taskId: taskId!);
            }
        });

        FlutterDownloader.registerCallback(downloadCallback);
        taskId = await FlutterDownloader.enqueue(
            url: downloadUrl,
            savedDir: directory,
            showNotification: true,
            openFileFromNotification: true,
        );
    }

    static Future<bool> update() async {
        try {
            String downloadUrl = await VersionChecker._getPlatformUrl();
            if(SPlatform.isDesktop)
                VersionChecker._updateDesktop(downloadUrl);
            else if(SPlatform.isMobile)
                VersionChecker._updateMobile(downloadUrl);
            else
                throw Exception("Unsupported platform");
            return true;
        } finally {
            return false;
        }
    }
}