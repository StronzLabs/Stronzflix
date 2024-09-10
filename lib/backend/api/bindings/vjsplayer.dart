import 'package:html/dom.dart';
import 'package:js_unpack/js_unpack.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/sutils.dart';

class VJSPlayer extends Player {
    static Player instance = VJSPlayer._();
    VJSPlayer._() : super("VJSPlayer");

    @override
    Future<Uri> getSource(Uri uri) async {
        String body = await HTTP.get(uri);
        Document document = html.parse(body);

        Element script = document.getElementsByTagName("script")
            .firstWhere((element) => element.text.contains("vjsplayer"));
        String unpacked = JsUnpack(script.text).unpack();

        String url = unpacked.split('src:"')[1].split('"')[0];
        return Uri.parse(url);
    }
}
