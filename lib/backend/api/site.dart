import 'package:flutter/material.dart' show mustCallSuper;
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/utils/initializable.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/tune.dart';
import 'package:stronzflix/backend/storage/settings.dart';

abstract class Site extends Initializable {

    final String name;
    final String domain;
    String get url => Settings.domains[this.name]!;

    late final Tuner tuner;

    Site(this.name, this.domain) : super((self) => Site._registry[name] = self as Site) {
        this.tuner = Tuner(this.tunerValidator);
    }

    @override
    @mustCallSuper
    Future<void> construct() async{
        await super.construct();

        if(this.isLocal)
            return;

        if(Settings.domains.containsKey(this.name))
            if(!await this.tuner.validateDomain(Settings.domains[this.name]!))
                Settings.domains.remove(this.name);

        if (!Settings.domains.containsKey(this.name)) {
            await for (dynamic value in this.tune()) {
                if (value == null)
                    throw Exception("Failed to find domain for ${this.name}");
            }
        }
    }

    Stream<double?> tune() async* {
        await for(dynamic res in this.tuner.findDomain(this.domain)) {
            if(res is String) {
                // TODO: find a better solution for this
                Map<String, String> domains = Settings.domains;
                domains[this.name] = "https://${this.domain}.${res}";
                Settings.domains = domains;
                Settings.update();
                return;
            }
            else
                yield res;
        }
    }

    bool get isLocal => this is LocalSite;
    bool get allowsDownload => this is LocalSite;
    Future<List<TitleMetadata>> search(String query);
    Future<List<TitleMetadata>> latests();
    Future<Title> getTitle(TitleMetadata metadata);

    bool tunerValidator(String homePage);

    @override
    String toString() => this.name;

    static final Map<String, Site> _registry = {};
    static List<Site> get sites => _registry.values.toList();
    static Site? get(String name) => _registry[name];
}
