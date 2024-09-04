import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/sutils.dart';

class Streampeaker extends Player {
    static Player instance = Streampeaker._();
    Streampeaker._()
        : super("Streampeaker");

    @override
    Future<Uri> getSource(Watchable media) async {
        String passBody = await HTTP.get(media.uri);
        Document passDocument = html.parse(passBody);

        String episodeUrl = passDocument.querySelector(".card-body")!.querySelector("a")!.attributes["href"]!;
        String body = await HTTP.get(episodeUrl);
        Document document = html.parse(body);

        String source = document.querySelector("#video-player")!.querySelector("source")!.attributes["src"]!;
        return Uri.parse(source);
    }
}