import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/initializable.dart';
import 'package:stronzflix/backend/api/media.dart';

abstract class Site extends Initializable {

    final String name;
    final String url;

    Site(this.name, this.url) : super((self) => Site._registry[name] = self as Site);

    bool get isLocal => this is LocalSite;
    bool get allowsDownload => this is LocalSite;
    Future<List<TitleMetadata>> search(String query);
    Future<List<TitleMetadata>> latests();
    Future<Title> getTitle(TitleMetadata metadata);

    @override
    String toString() => this.name;

    static final Map<String, Site> _registry = {};
    static List<Site> get sites => _registry.values.toList();
    static Site? get(String name) => _registry[name];
}
