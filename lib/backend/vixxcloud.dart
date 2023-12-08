import 'dart:convert';

import 'package:html_unescape/html_unescape_small.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/player.dart';
import 'package:stronzflix/backend/result.dart';
import 'package:stronzflix/backend/streamingcommunity.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;

class VixxCloud extends Player {

    static Player instance = VixxCloud._();

    final String _streamingCommunityUrl;

    VixxCloud._()
        : _streamingCommunityUrl = StreamingCommunity.instance.url, super(name: "VixxCloud");

    @override
    Future<Uri> getSource(IWatchable media) async {
        String titleId = RegExp(r"watch/(\d+)").firstMatch(media.url)!.group(1)!;
        String episodeId = RegExp(r"\?e=(\d+)").firstMatch(media.url)?.group(1) ?? "";
        String iframeSrc = "/iframe/${titleId}?episode_id=${episodeId}";

        var html = HtmlUnescape();
        String iframe = await http.get("${this._streamingCommunityUrl}${iframeSrc}", headers: { "User-Agent": "Stronzflix" });
        String src = html.convert(RegExp(r'src="(.+?)"').firstMatch(iframe)!.group(1)!);
    
        String data = await http.get(src);

        String playlistUrl = RegExp(r"url: '(.+?)'").firstMatch(data)!.group(1)!;

        String jsonString = RegExp(r"params: ({(.|\n)+?}),").firstMatch(data)!.group(1)!;
        jsonString = jsonString.replaceAll("'", '"').replaceAll(" ", "").replaceAll("\n", "").replaceAll("\",}", "\"}");
        dynamic json = jsonDecode(jsonString);

        String param = json.keys.map((key) => "$key=${json[key]}").join("&");
        String playlist = "${playlistUrl}?${param}";

        return Uri.parse(playlist);
    }
    
      @override
      Future<Title> recoverLate(LateTitle title) {
        String id = RegExp(r"watch/(\d+)").firstMatch(title.url)!.group(1)!;
        String titleUrl = "/titles/${id}--";
        return StreamingCommunity.instance.getTitle(Result(
            url: titleUrl,
            name: title.name,
            poster: "",
            site: StreamingCommunity.instance
        ));
    }
}
