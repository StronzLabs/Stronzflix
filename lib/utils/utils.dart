import 'package:flutter_hls_parser/flutter_hls_parser.dart';

int deduceVariantResolution(Variant variant) {
    if(variant.format.height != null)
        return variant.format.height!;

    String resString = variant.url.queryParameters["rendition"]!;
    return int.parse(resString.substring(0, resString.length - 1));
}
