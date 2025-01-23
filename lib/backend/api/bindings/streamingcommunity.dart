import 'dart:convert';

import 'package:stronzflix/backend/api/bindings/vixxcloud.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/utils.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

final class CloudflarePhishingHTTPMiddleware extends HTTPProcessor {
    Map<String, String>? _cookie;

    CloudflarePhishingHTTPMiddleware([super._parent]);

    @override
    Future<Request> beforeRequest(Request request) async {
        if(this._cookie == null)
            return request;

        return request.copyWith(headers: this._cookie);
    }

    @override
    Future<Response> process(Request request, Duration? timeout) async {
        Response response = await super.parent.process(request, timeout);

        if((!response.headers.containsKey("server") && response.headers["server"] == "cloudflare"))
            return response;

        Document document = html.parse(response.body);
        String title = document.head?.getElementsByTagName("title").firstOrNull?.text ?? "";
        if(title != "Suspected phishing site | Cloudflare")
            return response;

        Element? input = document.body?.querySelector("input[name='atok']");
        String? atok = input?.attributes["value"];

        if(atok != null)
            this._cookie = { "Cookie": "__cf_mw_byp=${atok}" };

        request = await this.beforeRequest(request);
        return super.parent.process(request, timeout);
    }
}

final class InhertiaHTTPMiddleware extends HTTPProcessor {
    Map<String, String>? _inhertia;
    bool processInhertia = false;

    InhertiaHTTPMiddleware([super._parent]);

    @override
    Future<Request> beforeRequest(Request request) async {
        if(this._inhertia == null)
            return request;

        return request.copyWith(headers: this._inhertia);
    }

    @override
    Future<Response> process(Request request, Duration? timeout) async {
        Response response = await super.parent.process(request, timeout);
        
        if(!this.processInhertia)
            return response;

        RegExpMatch? match = RegExp(r'version&quot;:&quot;(?<inertia>[a-z0-9]+)&quot;').firstMatch(response.body);
        if(match == null)
            return response;

        this._inhertia = { "X-Inertia": "true", "X-Inertia-Version": match.namedGroup("inertia")! };

        request = await this.beforeRequest(request);
        return super.parent.process(request, timeout);
    }
}

class StreamingCommunity extends Site {
    static Site instance = StreamingCommunity._();
    StreamingCommunity._() : super("StreamingCommunity", "streamingcommunity", 0, InhertiaHTTPMiddleware(CloudflarePhishingHTTPMiddleware()));

    String get _cdn => super.url.replaceFirst("//", "//cdn.");

    @override
    Future<void> construct() async {
        await super.construct();
        (super.chain.middleware as InhertiaHTTPMiddleware).processInhertia = true;
    }

    @override
    Future<bool> tunerValidator(String homePage) async {
        return homePage.contains("<meta name=\"author\" content=\"StreamingCommunity\">");
    }

    String _findImage(Map<String, dynamic> json, String type) {
        return json["images"].firstWhere(
            (dynamic image) => image["type"] == type,
            orElse: () => { "filename": "" }
        )["filename"];
    }

    Future<List<TitleMetadata>> _fetch(String url) async {
        String body = await super.chain.get("${super.url}${url}");
        dynamic json = jsonDecode(body);
        dynamic titles = json["props"]["titles"];

        List<TitleMetadata> results = [];
        for (dynamic title in titles) {
            String poster = this._findImage(title, "poster");

            results.add(TitleMetadata(
                site: this,
                name: title["name"],
                uri: Uri.parse("/titles/${title["id"]}-${title["slug"]}"),
                poster:  Uri.parse("${this._cdn}/images/${poster}") 
            ));
        }

        return results;
    }

    @override
    Future<List<TitleMetadata>> search(String query) {
        return this._fetch("/search?q=${Uri.encodeQueryComponent(query)}");
    }

    @override
    Future<List<TitleMetadata>> latests() {
        return this._fetch("/browse/latest");
    }

    Future<Film> getFilm(TitleMetadata metadata, dynamic title) async {
        String banner = this._findImage(title, "cover_mobile");
        
        String releaseDate = title["release_date"];
        DateTime? coomingDate = releaseDate.isNotEmpty ? DateTime.parse(releaseDate) : null;

        return Film(
            uri: Uri.parse("/watch/${title["id"]}"),
            banner: Uri.parse("${this._cdn}/images/${banner}"),
            description: title["plot"],
            metadata: metadata,
            comingSoon: coomingDate?.isAfter(DateTime.now()) ?? false ? coomingDate : null
        );
    }

    Future<List<Episode>> getEpisodes(Season season, String seasonUrl) async {
        String body = await super.chain.get("${super.url}${seasonUrl}");
        dynamic json = jsonDecode(body);

        dynamic seasonObject = json["props"]["loadedSeason"];
        dynamic titleId = json["props"]["title"]["id"];

        return [
            for(dynamic episode in seasonObject["episodes"])
                Episode(
                    uri: Uri.parse("/watch/${titleId}?e=${episode["id"]}"),
                    name: episode["name"] ?? "Episodio ${episode["number"]}",
                    cover: Uri.parse("${this._cdn}/images/${this._findImage(episode, "cover")}"),
                    season: season,
                    episodeNo: episode["number"]
                )
        ];
    }

    Future<Series> getSeries(TitleMetadata metadata, dynamic title) async {
        String banner = this._findImage(title, "cover_mobile");
        
        String releaseDate = title["release_date"];
        DateTime? coomingDate = releaseDate.isNotEmpty ? DateTime.parse(releaseDate) : null;

        Series series = Series(
            metadata: metadata,
            banner: Uri.parse("${this._cdn}/images/${banner}"),
            description: title["plot"],
            seasons: [],
            comingSoon: coomingDate?.isAfter(DateTime.now()) ?? false ? coomingDate : null
        );

        List<Season> seasons = [];
        for(var seasonObject in title["seasons"]) {
            Season season = Season(
                series: series,
                name: seasonObject["name"],
                seasonNo: seasonObject["number"],
                episodes: []
            );

            season.episodes.addAll(
                await this.getEpisodes(season, "/titles/${title["id"]}-${title["slug"]}/stagione-${seasonObject["number"]}")
            );

            seasons.add(season);
        }
        series.seasons.addAll(seasons);

        return series;
    }

    @override
    Future<Title> getTitle(TitleMetadata metadata) async {
        String body = await super.chain.get("${super.url}${metadata.uri}");
        dynamic json = jsonDecode(body);
        dynamic title = json["props"]["title"];

        if(title["type"] == "tv")
            return this.getSeries(metadata, title);
        else
            return this.getFilm(metadata, title);
    }

    @override
    Future<List<WatchOption>> getOptions(Watchable watchable) async {
        return [
            WatchOption(
                player: VixxCloud.instance,
                uri: watchable.uri
            )
        ];
    }
}
