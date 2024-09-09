import 'package:flutter/material.dart' show Alignment, AlignmentGeometry, mustCallSuper;
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/utils/initializable.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/tune.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:sutils/utils/simple_http.dart';

abstract class Site extends Initializable {

    final String name;
    final String domain;
    String get url => Settings.domains[this.name]!;

    late final Tuner tuner;

    late Uri _favicon;
    Uri get favicon => this._favicon;

    Site(this.name, this.domain) : super((self) => Site._registry[name] = self as Site) {
        this.tuner = Tuner(this.tunerValidator);
    }

    @override
    @mustCallSuper
    Future<void> construct() async{
        await super.construct();

        this._favicon = await this.getFavicon();

        if(this.isLocal) {
            super.reportProgress(1.0);
            return;
        }

        if(Settings.domains.containsKey(this.name))
            if(!await this.tuner.validateDomain(Settings.domains[this.name]!))
                Settings.domains.remove(this.name);

        if (!Settings.domains.containsKey(this.name)) {
            await for (dynamic value in this.tune()) {
                if (value is double)
                    super.reportProgress(value);
                else if (value == null)
                    throw Exception("Failed to find domain for ${this.name}");
            }
        }
    }

    Stream<double?> tune() async* {
        await for(dynamic res in this.tuner.findDomain(this.domain)) {
            if(res is String) {
                // TODO: find a better solution for this
                Map<String, dynamic> domains = Settings.domains;
                domains[this.name] = "https://${this.domain}.${res}";
                Settings.domains = domains;
                Settings.instance.serialize();
                return;
            }
            else
                yield res;
        }
    }

    Future<Uri> getFavicon() async {
        String body = await HTTP.get(this.url);
        RegExpMatch match = RegExp(r'<link rel="icon".*href="(?<favicon>[^"]+)"').firstMatch(body)!;
        String url = match.namedGroup("favicon")!;
        if(url.startsWith("//"))
            url = "https:$url";
        else if(url.startsWith("/"))
            url = "${this.url}$url";
        return Uri.parse(url);
    }

    bool get isLocal => this is LocalSite;
    bool get allowsDownload => !this.isLocal;
    AlignmentGeometry get cropPolicy => Alignment.center;
    Future<List<TitleMetadata>> search(String query);
    Future<List<TitleMetadata>> latests();
    Future<Title> getTitle(TitleMetadata metadata);
    Future<List<WatchOption>> getOptions(Watchable watchable);

    bool tunerValidator(String homePage);

    @override
    String toString() => this.name;

    static final Map<String, Site> _registry = {};
    static List<Site> get sites => _registry.values.toList();
    static Site? get(String name) => _registry[name];
}
