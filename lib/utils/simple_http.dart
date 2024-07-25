import 'dart:typed_data';

import 'package:http/http.dart';

Future<Response> _get(dynamic url, {Map<String, String>? headers, bool followRedirects = true}) async {
    assert(url is String || url is Uri);
    headers ??= {};
    if(!headers.containsKey("User-Agent"))
        headers["User-Agent"] = "Stronzflix";

    Request req = Request("Get", url is Uri ? url : Uri.parse(url));
    req.headers.addAll(headers);
    req.followRedirects = followRedirects;
    Client baseClient = Client();
    StreamedResponse response = await baseClient.send(req);
    return Response.fromStream(response);
}

Future<Uint8List> fetchResource(String url) async {
    Response response = await _get(Uri.parse(url));
    if (response.statusCode != 200)
        return Uint8List(0);

    return response.bodyBytes;
}

Future<String> get(dynamic url, {Map<String, String>? headers, bool followRedirects = true}) async {
    return (await _get(url, headers: headers, followRedirects: followRedirects)).body;
}

Future<Uint8List> getRaw(dynamic url, {Map<String, String>? headers, bool followRedirects = true}) async {
    assert(url is String || url is Uri);
    headers ??= {};
    if(!headers.containsKey("User-Agent"))
        headers["User-Agent"] = "Stronzflix";

    return (await _get(url, headers: headers, followRedirects: followRedirects)).bodyBytes;
}
