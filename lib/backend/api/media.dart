import 'package:stronzflix/backend/api/player.dart';
import 'package:stronzflix/backend/api/site.dart';

import 'package:stronz_video_player/stronz_video_player.dart' show Playable;

class TitleMetadata {
    final String name;
    final String url;
    final Site site;
    final String poster;

    const TitleMetadata({
        required this.name,
        required this.url,
        required this.site,
        required this.poster
    });
}

mixin Watchable implements Playable {
    String get url;
    Player get player;

    TitleMetadata get metadata;

    @override
    Future<Uri> get source => this.player.getSource(this);
    @override
    Playable? get next => null;

    static String genInfo(Watchable watchable) {
        if (watchable is Film)
            return "";
        else if (watchable is Episode)
            return "${watchable.season.series.seasons.indexOf(watchable.season)}x${watchable.season.episodes.indexOf(watchable)}";
        
        throw Exception("Invalid watchable type");
    }

    static Map<String, dynamic> serialize(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        return {
            "metadata":  {
                "name": data.name,
                "url": data.url,
                "site": data.site.name,
                "poster": data.poster
            },
            "info": Watchable.genInfo(watchable)
        };
    }

    static Future<Watchable> unserialize(TitleMetadata metadata, String info) async {
        Title title = await metadata.site.getTitle(metadata);
        if (title is Film)
            return title;
        else if (title is Series) {
            int seriesNo = int.parse(info.split("x")[0]);
            int episodeNo = int.parse(info.split("x")[1]);

            return title.seasons[seriesNo].episodes[episodeNo];
        }
        
        throw Exception("Invalid title type");
    }
}

abstract class Title {
    final String banner;
    final String description;
    final TitleMetadata metadata;
    final DateTime? comingSoon;

    String get name => metadata.name;
    Site get site => metadata.site;

    const Title({
        required this.banner,
        required this.description,
        required this.metadata,
        this.comingSoon
    });
}

class Film extends Title with Watchable {
    @override
    final Player player;
    @override
    final String url;

    @override
    String get title => this.name;

    @override
    Uri get thumbnail => Uri.parse(this.banner);

    const Film({
        required super.banner,
        required super.description,
        required super.metadata,
        super.comingSoon,
        required this.url,
        required this.player
    });
}

class Episode with Watchable {
    final String name;
    final String cover;
    final Season season;
    final int episodeNo;

    @override
    final String url;
    @override
    final Player player;

    @override
    String get title => "${this.season.series.name} - ${this.name}";

    @override
    TitleMetadata get metadata => season.series.metadata;

    @override
    Uri get thumbnail => Uri.parse(this.cover);

    @override
    Watchable? get next {
        Season season = this.season;
        Series series = season.series;
        int episodeNo = season.episodes.indexOf(this);
        int seasonNo = series.seasons.indexOf(season);

        if (episodeNo < season.episodes.length - 1)
            return season.episodes[episodeNo + 1];
        else if (seasonNo < series.seasons.length - 1)
            return series.seasons[seasonNo + 1].episodes[0];
        return null;
    }

    const Episode({
        required this.name,
        required this.cover,
        required this.url,
        required this.season,
        required this.player,
        required this.episodeNo
    });
}

class Season {
    final String name;
    final Series series;
    final List<Episode> episodes;

    const Season({
        required this.name,
        required this.series,
        required this.episodes
    });
}

class Series extends Title {
    final List<Season> seasons;
    
    const Series({
        required super.banner,
        required super.description,
        super.comingSoon,
        required this.seasons,
        required super.metadata
    });
}
