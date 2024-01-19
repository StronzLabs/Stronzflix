import 'package:stronzflix/backend/media.dart';

abstract class Site {

    final String name;
    final String url;

    Site(this.name, this.url) {
        this.prepare().then((_) => Site._registry[name] = this);
    }

    Future<void> prepare() async {}
    Future<List<SearchResult>> search(String query);
    Future<Title> getTitle(SearchResult result);

    static final Map<String, Site> _registry = {};
    static Site? get(String name) => _registry[name];
}
