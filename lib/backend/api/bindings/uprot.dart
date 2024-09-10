import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/middleware.dart';
import 'package:html/parser.dart' as html;

class UProt extends Middleware {
    static Middleware instance = UProt._();
    UProt._() : super("UProt");

    @override
    Future<Uri> pass(Uri uri, String body) async {
        Document document = html.parse(body);
        // if there is a captcha it will crash
        String url = document.querySelector("#buttok")!.parent!.attributes["href"]!;
        return Uri.parse(url);
    }

    @override
    bool detect(Uri uri, String body) {
        return uri.host.contains("uprot");
    }
}