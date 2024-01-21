import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:stronzflix/backend/api/site.dart';

abstract class Title {
    final String name;
    const Title({
        required this.name
    });
}

class SearchResult {
    final String name;
    final String siteUrl;
    final Site site;
    final String poster;

    const SearchResult({
        required this.name,
        required this.siteUrl,
        required this.site,
        required this.poster
    });
}

abstract class Playable {
    Future<Watchable> resolve();
}

class LatePlayable implements Playable {
    final SerialInfo serialInfo;

    LatePlayable({
        required this.serialInfo
    });

    @override
    Future<Watchable> resolve() async {
        Site site = Site.get(this.serialInfo.site)!;
        SearchResult searchResult = SearchResult(
            name: this.serialInfo.name,
            siteUrl: this.serialInfo.siteUrl,
            site: site,
            poster: ""
        );
        Title title = await site.getTitle(searchResult);

        if(title is Film)
            return title.startsAt(this.serialInfo.startAt);
        else if (title is Series) {
            List<String> seasonXepisode = this.serialInfo.episode.split("x");
            int season = int.parse(seasonXepisode[0]) - 1;
            int episode = int.parse(seasonXepisode[1]) - 1;
            return title.seasons[season][episode].startsAt(this.serialInfo.startAt);
        }
        else
            throw Exception("Unknown title type");
    }
}

abstract class Watchable implements Playable {
    final String name;
    final String playerUrl;
    final Player player;
    final String cover;
    final int startAt;

    const Watchable({
        required this.name,
        required this.playerUrl,
        required this.player,
        required this.cover,
        this.startAt = 0
    });

    Watchable startsAt(int time);

    @override
    Future<Watchable> resolve() async => this;
}

class Film extends Watchable implements Title {
    const Film({
        required super.name,
        required super.playerUrl,
        required super.player,
        required super.cover,
        super.startAt = 0
    });

    @override
    Film startsAt(int time) => Film(
        name: this.name,
        playerUrl: this.playerUrl,
        player: this.player,
        cover: this.cover,
        startAt: time
    );
}

class Episode extends Watchable {
    final Series series;

    const Episode({
        required super.name,
        required super.cover,
        required super.playerUrl,
        required super.player,
        required this.series,
        super.startAt = 0
    });

    @override
    Episode startsAt(int time) => Episode(
        name: this.name,
        playerUrl: this.playerUrl,
        player: this.player,
        cover: this.cover,
        series: this.series,
        startAt: time
    );
}

class Series extends Title {
    late final List<List<Episode>> seasons;
    Series({required super.name, required this.seasons});

    Series._({required super.name, required Future<List<List<Episode>>> Function(Series) generator}) {
        this._ensureInitialized = generator(this).then((value) => this.seasons = value);
    }

    late final Future<void> _ensureInitialized;

    static Future<Series> fromEpisodes({required String name, required Future<List<List<Episode>>> Function(Series) generator}) async {
        Series series = Series._(name: name, generator: generator);
        await series._ensureInitialized;
        return series;
    }
}
