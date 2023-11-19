import 'package:stronzflix/backend/player.dart';

abstract class Title {
    final String name;
    const Title({required this.name});
}

abstract class Playable {
    String get name;
    String get url;
    Player get player;
}

class Film extends Title implements Playable {
    @override
    final String url;
    @override
    final Player player;
    const Film({required super.name, required this.url, required this.player});
}

class Episode implements Playable {
    @override
    final String url;
    @override
    final String name;
    @override
    final Player player;
    final String cover;
    const Episode({required this.name, required this.cover, required this.url, required this.player});
}

class Series extends Title {
    final List<List<Episode>> seasons;
    const Series({required super.name, required this.seasons});
}
