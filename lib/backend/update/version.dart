
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stronzflix/backend/update/updater.dart';

class VersionChecker
{
    static Future<String> _getLastVersion() async
    {
        Map<String, dynamic> release = await Updater.latestRelease;
        String version = release['name'].toString().split("Stronzflix ")[1];
        return version;
    }

    static Future<String> getCurrentVersion() async
    {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        return packageInfo.version;
    }

    static Future<bool> shouldUpdate() async
    {
        try {
            String currentVersion = await getCurrentVersion();
            String lastVersion = await _getLastVersion();
            return currentVersion != lastVersion;
        } catch (_) {
            return false;
        }
    }

    static Future<Stream<double>?> update() async {
        return Updater.create().doUpdate();
    }
}
