import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/widgets/fullscreen_inherited_widget.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:provider/provider.dart';

Uint8List hexToUint8List(String hex) {
    if (hex.length % 2 != 0) {
        throw 'Odd number of hex digits';
    }
    var l = hex.length ~/ 2;
    var result = Uint8List(l);
    for (var i = 0; i < l; ++i) {
        var x = int.parse(hex.substring(2 * i, 2 * (i + 1)), radix: 16);
        if (x.isNaN) {
        throw 'Expected hex string';
        }
        result[i] = x;
    }
    return result;
}

Uint8List decryptAES128(Uint8List encryptedData, Uint8List key, Uint8List iv) {
    final aes = BlockCipher('AES');
    final cbc = CBCBlockCipher(aes);
    final params = ParametersWithIV(KeyParameter(key), iv);

    cbc.init(false, params);

    Uint8List decryptedBytes = Uint8List(encryptedData.length);
    for (int offset = 0; offset < encryptedData.length; offset += aes.blockSize) {
        int endOffset = offset + aes.blockSize;
        if (endOffset > encryptedData.length)
            endOffset = encryptedData.length;
        decryptedBytes.setRange(offset, endOffset, cbc.process(encryptedData.sublist(offset, endOffset)));
    }

    return decryptedBytes;
}

int deduceVariantResolution(Variant variant) {
    if(variant.format.height != null)
        return variant.format.height!;

    String resString = variant.url.queryParameters["rendition"]!;
    return int.parse(resString.substring(0, resString.length - 1));
}

extension StringExtension on String {
    String capitalize() => "${this[0].toUpperCase()}${this.substring(1)}";
}

sealed class FullScreenProvider {
    const FullScreenProvider._();

    static T of<T>(BuildContext context, {bool listen = true}) {
        FullscreenInheritedWidget? fullscreen = FullscreenInheritedWidget.maybeOf(context);
        return Provider.of<T>(fullscreen == null ? context : fullscreen.parent.context, listen: listen);
    }
}
