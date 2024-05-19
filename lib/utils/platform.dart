import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

final class SPlatform {
    static bool get isWeb => kIsWeb;
    static bool get isDesktop => !SPlatform.isWeb && (Platform.isWindows || Platform.isLinux);
    static bool get isMobile => !SPlatform.isWeb && (Platform.isAndroid || Platform.isIOS);

    static bool get isMobileWeb => SPlatform.isMobile || SPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    static bool get isDesktopWeb => SPlatform.isDesktop || SPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

    SPlatform._();

    static Future<void> launchURL(String url) async {
        Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
            await launchUrl(Uri.parse(url));
        } else {
            throw 'Could not launch $url';
        }
    }
}
