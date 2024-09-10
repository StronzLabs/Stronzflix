import 'package:html/dom.dart';
import 'package:js_unpack/js_unpack.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:html/parser.dart' as html;
import 'package:sutils/sutils.dart';

class MixDrop extends Player {
    static Player instance = MixDrop._();
    MixDrop._()
        : super("MixDrop");

    @override
    Future<Uri> getSource(Uri uri) async {
        String body = await HTTP.get(uri);
        Document document = html.parse(body);

        Element iframe = document.getElementsByTagName("iframe").first;
        String iframeUrl = iframe.attributes["src"]!;
        if (!iframeUrl.startsWith(uri.scheme)) {
            if(!iframeUrl.contains("mixdrop"))
                iframeUrl = "${uri.scheme}://${uri.host}${iframeUrl}";
            else
                iframeUrl = "https:${iframeUrl}";
        }
        Document iframeDocument = html.parse(await HTTP.get(Uri.parse(iframeUrl)));
        Element script = iframeDocument.getElementsByTagName("script")
            .firstWhere((element) => element.text.contains("MDCore"));
        
        String packed = script.text.substring(script.text.indexOf("eval("));
        String unpacked = JsUnpack(packed).unpack();
        String url = unpacked.split(";")
            .firstWhere((element) => element.contains("wurl"))
            .split('="')[1];
        url = url.substring(0, url.length - 1);
        if (!url.startsWith("https://"))
            url = "https:${url}";
        
        return Uri.parse(url);
    }
}
