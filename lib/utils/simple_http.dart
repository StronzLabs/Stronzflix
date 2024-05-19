import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<http.Response> _get(dynamic url, {Map<String, String>? headers}) async {
    assert(url is String || url is Uri);
    headers ??= {};
    if(!headers.containsKey("User-Agent"))
        headers["User-Agent"] = "Stronzflix";

    return (await http.get(url is Uri ? url : Uri.parse(url), headers: headers));
}

Future<String> get(dynamic url, {Map<String, String>? headers}) async {
    return (await _get(url, headers: headers)).body;
}

Future<Uint8List> getRaw(dynamic url, {Map<String, String>? headers}) async {
    assert(url is String || url is Uri);
    headers ??= {};
    if(!headers.containsKey("User-Agent"))
        headers["User-Agent"] = "Stronzflix";

    return (await _get(url, headers: headers)).bodyBytes;
}
