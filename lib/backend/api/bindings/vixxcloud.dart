import 'dart:convert';

import 'package:html_unescape/html_unescape.dart';
import 'package:stronzflix/backend/api/bindings/streamingcommunity.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:sutils/sutils.dart';

class VixxCloud extends Player {

    static Player instance = VixxCloud._();

    final HtmlUnescape _html = HtmlUnescape();
    String get _streamingCommunityUrl => StreamingCommunity.instance.url;

    VixxCloud._() : super("VixxCloud");

    @override
    Future<Uri> getSource(Uri uri) async {
        String titleId = RegExp(r"watch/(\d+)").firstMatch(uri.toString())!.group(1)!;
        String episodeId = RegExp(r"\?e=(\d+)").firstMatch(uri.toString())?.group(1) ?? "";
        String iframeSrc = "/iframe/${titleId}?episode_id=${episodeId}";

        String iframe = await HTTP.get("${this._streamingCommunityUrl}${iframeSrc}");
        String src = this._html.convert(RegExp(r'src="(.+?)"').firstMatch(iframe)!.group(1)!);
    
        String data = await HTTP.get(src);

        String playlistUrl = RegExp(r"url: '(.+?)'").firstMatch(data)!.group(1)!;

        String jsonString = RegExp(r"params: ({(.|\n)+?}),").firstMatch(data)!.group(1)!;
        jsonString = jsonString.replaceAll("'", '"').replaceAll(" ", "").replaceAll("\n", "").replaceAll("\",}", "\"}");
        dynamic json = jsonDecode(jsonString);

        String param = json.keys.map((key) => "${key}=${json[key]}").join("&");
        String playlist = "${playlistUrl}?${param}";

        if (await HTTP.status(playlist) != 200)
            playlist = playlist.replaceFirst(RegExp(r"expires=\d+"), "");

        return Uri.parse(playlist);
    }
}
