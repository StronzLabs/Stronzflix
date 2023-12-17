import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

final class SPlatform {
    static bool get isWeb => kIsWeb;
    static bool get isDesktop => !SPlatform.isWeb && (Platform.isWindows || Platform.isLinux);
    static bool get isMobile => !SPlatform.isWeb && (Platform.isAndroid || Platform.isIOS);

    SPlatform._();
}
