import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;
import 'package:html/parser.dart' as html;

class Streampeaker extends Player {
    static Player instance = Streampeaker._();
    Streampeaker._()
        : super("Streampeaker");

    @override
    Future<Uri> getSource(Watchable media) async {
        String passBody = await http.get(media.url);
        Document passDocument = html.parse(passBody);

        String episodeUrl = passDocument.querySelector(".card-body")!.querySelector("a")!.attributes["href"]!;
        String body = await http.get(episodeUrl);
        Document document = html.parse(body);

        String source = document.querySelector("#video-player")!.querySelector("source")!.attributes["src"]!;
        return Uri.parse(source);
    }
}