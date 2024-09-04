import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/sutils.dart';

class JWPlayer extends Player {
    static Player instance = JWPlayer._();
    JWPlayer._()
        : super("Streampeaker");

    @override
    Future<Uri> getSource(Uri uri) async {
        String body = await HTTP.get(uri);
        Document document = html.parse(body);

        Element script = document.getElementsByTagName("script")
            .firstWhere((element) => element.text.contains("player_hls"));

        String url = script.text.split('file: "')[1].split('"')[0];
        return Uri.parse(url);
    }
}
