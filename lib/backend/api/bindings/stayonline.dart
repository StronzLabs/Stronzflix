import 'dart:convert';

import 'package:stronzflix/backend/api/middleware.dart';
import 'package:sutils/sutils.dart';

class StayOnline extends Middleware {
    static Middleware instance = StayOnline._();
    StayOnline._() : super("StayOnline");

    @override
    Future<Uri> pass(Uri uri, String body) async {
        String id = uri.pathSegments[1];
        String jsonString = await HTTP.post("https://${uri.host}/ajax/linkEmbedView.php", body: {
            "id": id
        });
        Map<String, dynamic> json = jsonDecode(jsonString);
        String url = json["data"]["value"];
        return Uri.parse(url);
    }

    @override
    bool detect(Uri uri, String body) {
        return uri.host.contains("stayonline");
    }
}