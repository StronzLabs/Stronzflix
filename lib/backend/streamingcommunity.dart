import 'dart:convert';

import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/player.dart';
import 'package:stronzflix/backend/result.dart';
import 'package:stronzflix/backend/site.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;

class StreamingCommunity extends Site {
    
    static Site instance = StreamingCommunity._("https://streamingcommunity.care");

    final String _cdn;
    final Map<String, String> _inhertia;

    StreamingCommunity._(String url)
        : _cdn = url.replaceFirst("//", "//cdn."), _inhertia = {}, super("StreamingCommunity", url);

    @override
    Future<void> prepare() async {
        await this.getInhertia();
    }

    Future<void> getInhertia() async {
        String body = await http.get(super.url);
        RegExpMatch match = RegExp(r'version&quot;:&quot;(?<inertia>[a-z0-9]+)&quot;').firstMatch(body)!;
        this._inhertia["X-Inertia"] = "true";
        this._inhertia["X-Inertia-Version"] = match.namedGroup("inertia")!;
    }

    @override
    Future<List<Result>> search(String query) async {
        String body = await http.get("${super.url}/search?q=${Uri.encodeQueryComponent(query)}", headers: this._inhertia);
        dynamic json = jsonDecode(body);
        dynamic titles = json["props"]["titles"];

        List<Result> results = [];
        for (dynamic title in titles) {
            String poster = title["images"].firstWhere((dynamic image) => image["type"] == "poster")["filename"];

            results.add(Result(
                site: this,
                name: title["name"],
                url: "/titles/${title["id"]}-${title["slug"]}",
                poster:  "${this._cdn}/images/${poster}" 
            ));
        }

        return results;
    }

    Future<List<Episode>> getEpisodes(String seasonUrl) async {
        String body = await http.get("${super.url}${seasonUrl}", headers: this._inhertia);
        dynamic json = jsonDecode(body);

        dynamic season = json["props"]["loadedSeason"];
        dynamic titleId = json["props"]["title"]["id"];

        List<Episode> episodes = [];
        for(dynamic episode in season["episodes"]) {
            String cover = episode["images"].firstWhere((dynamic image) => image["type"] == "cover")["filename"];

            episodes.add(Episode(
                url: "/watch/${titleId}?e=${episode["id"]}",
                name: episode["name"],
                cover: "${this._cdn}/images/${cover}",
                player: Player.get("VixxCloud")!
            ));
        }

        return episodes;
    }

    Future<Series> getSeries(String url, dynamic title) async {
        List<List<Episode>> seasons = [];

        for(dynamic season in title["seasons"]) {
            String seasonUrl = "${url}/stagione-${season["number"]}";
            seasons.add(await this.getEpisodes(seasonUrl));
        }

        return Series(
            name: title["name"],
            seasons: seasons
        );
    }

    Film getFilm(dynamic title) {
        return Film(
            name: title["name"],
            url: "/watch/${title["id"]}",
            player: Player.get("VixxCloud")!
        );
    }
    
    @override
    Future<Title> getTitle(Result result) async {
        String body = await http.get("${super.url}${result.url}", headers: this._inhertia);
        dynamic json = jsonDecode(body);

        dynamic title = json["props"]["title"];

        if(title["type"] == "tv")
            return await this.getSeries(result.url, title);
        else
            return this.getFilm(title);
    }

    Future<String> parseVixCloud(String url) async {
        String data = await http.get(url);

        String playlistUrl = RegExp(r"url: '(.+?)'").firstMatch(data)!.group(1)!;

        String jsonString = RegExp(r"params: ({(.|\n)+?}),").firstMatch(data)!.group(1)!;
        jsonString = jsonString.replaceAll("'", '"').replaceAll(" ", "").replaceAll("\n", "").replaceAll("\",}", "\"}");
        dynamic json = jsonDecode(jsonString);

        String param = json.keys.map((key) => "$key=${json[key]}").join("&");
        String playlist = "${playlistUrl}?${param}";

        return playlist;
    }
}