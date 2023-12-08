import 'package:stronzflix/backend/player.dart';

abstract class Title {
    final String name;
    const Title({required this.name});
}

abstract class IWatchable {
    String get name;
    String get url;
    Player get player;
    String get cover;
}

class LateTitle implements IWatchable {
    @override final String name;
    @override final String url;
    @override final Player player;
    @override final String cover;
    Future<Title> get watchable async => await this.player.recoverLate(this);
    const LateTitle({required this.name, required this.url, required this.player, required this.cover});
}

class Film extends Title implements IWatchable {
    @override final String url;
    @override final Player player;
    @override final String cover;
    const Film({required super.name, required this.url, required this.player, required this.cover});
}

class Episode implements IWatchable {
    @override final String url;
    @override final String name;
    @override final Player player;
    @override final String cover;
    final Series series;
    const Episode({required this.name, required this.cover, required this.url, required this.player, required this.series});
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
