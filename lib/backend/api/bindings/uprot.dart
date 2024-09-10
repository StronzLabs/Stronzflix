import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/middleware.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/utils/simple_http.dart';

class UProt extends Middleware {
    static Middleware instance = UProt._();
    UProt._() : super("UProt");

    @override
    Future<Uri> pass(Uri uri, String body) async {
        if(!uri.path.contains("mse")) {
            String id = uri.pathSegments.last;
            uri = Uri.parse("${uri.scheme}://${uri.host}/mse/${id}");
            body = await HTTP.get(uri);
        }
        Document document = html.parse(body);
        String url = document.querySelector(".button")!.parent!.attributes["href"]!;
        return Uri.parse(url);
    }

    @override
    bool detect(Uri uri, String body) {
        return uri.host.contains("uprot");
    }
}