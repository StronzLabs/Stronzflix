import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/sutils.dart';

class Streampeaker extends Player {
    static Player instance = Streampeaker._();
    Streampeaker._() : super("Streampeaker");

    late final Map<String, String> _cookie;
    static set cookie(Map<String, String> cookie) => (Streampeaker.instance as Streampeaker)._cookie = cookie;

    @override
    Future<Uri> getSource(Uri uri) async {
        String body = await HTTP.get(uri, headers: this._cookie);
        Document document = html.parse(body);

        String source = document.querySelector("#video-player")!.querySelector("source")!.attributes["src"]!;
        return Uri.parse(source);
    }
}