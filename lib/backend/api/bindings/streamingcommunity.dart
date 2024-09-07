import 'dart:convert';

import 'package:stronzflix/backend/api/bindings/vixxcloud.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/sutils.dart';

class StreamingCommunity extends Site {

    String get _cdn => super.url.replaceFirst("//", "//cdn.");
    final Map<String, String> _inhertia = {};

    static Site instance = StreamingCommunity._();
    StreamingCommunity._() : super("StreamingCommunity", "streamingcommunity");

    @override
    Future<void> construct() async {
        await super.construct();
        await this._getInhertia();
    }

    @override
    bool tunerValidator(String homePage) {
        return homePage.contains("<meta name=\"author\" content=\"StreamingCommunity\">");
    }

    Future<void> _getInhertia() async {
        String body = await HTTP.get(super.url);
        RegExpMatch match = RegExp(r'version&quot;:&quot;(?<inertia>[a-z0-9]+)&quot;').firstMatch(body)!;
        this._inhertia["X-Inertia"] = "true";
        this._inhertia["X-Inertia-Version"] = match.namedGroup("inertia")!;
    }

    String _findImage(Map<String, dynamic> json, String type) {
        return json["images"].firstWhere(
            (dynamic image) => image["type"] == type,
            orElse: () => { "filename": "" }
        )["filename"];
    }

    Future<List<TitleMetadata>> _fetch(String url) async {
        String body = await HTTP.get("${super.url}${url}", headers: this._inhertia);
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
        String body = await HTTP.get("${super.url}${seasonUrl}", headers: this._inhertia);
        dynamic json = jsonDecode(body);

        dynamic seasonObject = json["props"]["loadedSeason"];
        dynamic titleId = json["props"]["title"]["id"];

        return [
            for(dynamic episode in seasonObject["episodes"])
                Episode(
                    uri: Uri.parse("/watch/${titleId}?e=${episode["id"]}"),
                    name: episode["name"],
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
        String body = await HTTP.get("${super.url}${metadata.uri}", headers: this._inhertia);
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
