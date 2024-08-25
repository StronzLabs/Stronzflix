import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

final class SPlatform {
    static bool get isWeb => kIsWeb;
    static bool get isDesktop => !SPlatform.isWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    static bool get isMobile => !SPlatform.isTV && !SPlatform.isWeb && (Platform.isAndroid || Platform.isIOS);

    static bool get isMobileWeb => SPlatform.isMobile || SPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    static bool get isDesktopWeb => SPlatform.isDesktop || SPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);

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

    static final ValueNotifier<bool> _isFullScreen = ValueNotifier(false);

    static Future<void> setFullScreen(bool fullscreen) async {
        await windowManager.setFullScreen(fullscreen);
        SPlatform._isFullScreen.value = fullscreen;
    }

    static Future<bool> isFullScreen() async {
        SPlatform._isFullScreen.value = await windowManager.isFullScreen();
        return SPlatform._isFullScreen.value;
    }

    static ValueNotifier<bool> isFullScreenSync() => SPlatform._isFullScreen;

    static Future<void> toggleFullScreen() async {
        return SPlatform.setFullScreen(!await SPlatform.isFullScreen());
    }
}
