import 'package:stronzflix/backend/api/initializable.dart';
import 'package:stronzflix/backend/api/media.dart';

abstract class Site extends Initializable {

    final String name;
    final String url;

    Site(this.name, this.url) : super((self) => Site._registry[name] = self as Site);

    Future<List<SearchResult>> search(String query);
    Future<List<SearchResult>> latests();
    Future<Title> getTitle(SearchResult result);

    static final Map<String, Site> _registry = {};
    static Site? get(String name) => _registry[name];
}
