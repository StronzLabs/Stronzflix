import 'dart:io';

final class SPlatform {
    static bool get isDesktop => Platform.isWindows || Platform.isLinux;
    static bool get isMobile => Platform.isAndroid || Platform.isIOS;

    SPlatform._();
}
