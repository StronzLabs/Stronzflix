import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

final class SPlatform {
    static bool get isWeb => kIsWeb;
    static bool get isDesktop => !SPlatform.isWeb && (Platform.isWindows || Platform.isLinux);
    static bool get isMobile => !SPlatform.isTV && !SPlatform.isWeb && (Platform.isAndroid || Platform.isIOS);

    static bool get isMobileWeb => SPlatform.isMobile || SPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    static bool get isDesktopWeb => SPlatform.isDesktop || SPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

    static late final bool _isTV;
    static bool get isTV => _isTV;

    SPlatform._();

    static Future<void> launchURL(String url) async {
        Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
        } else {
            throw 'Could not launch ${url}';
        }
    }

    static Future<void> checkTV() async {
        const MethodChannel channel = MethodChannel('stronzflix.app/is_tv');
        SPlatform._isTV = Platform.isAndroid ? await channel.invokeMethod<bool>('isTV') ?? false : false;
    }
}
