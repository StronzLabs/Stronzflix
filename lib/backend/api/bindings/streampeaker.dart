import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/bindings/animesaturn.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/utils.dart';

class Streampeaker extends Player {
    static Player instance = Streampeaker._();
    Streampeaker._() : super("Streampeaker");

    final HTTPChain _chain = HTTPChain(CookieCaptchaHTTPMiddleware());

    @override
    Future<Uri> getSource(Uri uri) async {
        String body = await this._chain.get(uri);
        Document document = html.parse(body);

        String source = document.querySelector("#video-player")!.querySelector("source")!.attributes["src"]!;
        return Uri.parse(source);
    }
}