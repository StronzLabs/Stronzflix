import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/result.dart';

abstract class Site {

    final String name;
    final String url;

    Site(this.name, this.url) {
        this.prepare().then((_) => Site._registry[name] = this);
    }

    Future<void> prepare() async {}
    Future<List<Result>> search(String query);
    Future<Title> getTitle(Result result);

    static final Map<String, Site> _registry = {};
    static Site? get(String name) => _registry[name];
}
