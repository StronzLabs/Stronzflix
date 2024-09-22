import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/middleware.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/utils/simple_http.dart';

class UProt extends Middleware {
    static Middleware instance = UProt._();
    UProt._() : super("UProt");

    @override
    Future<Uri> pass(Uri uri, String body) async {
        String id = uri.pathSegments[1];
        uri = Uri.parse("${uri.scheme}://${uri.host}/mse/${id}");
        String body = await HTTP.get(uri);
        Document document = html.parse(body);
        String url = document.querySelector(".button")!.parent!.attributes["href"]!;
        return Uri.parse(url);
    }

    @override
    bool detect(Uri uri, String body) {
        return uri.host.contains("uprot");
    }
}