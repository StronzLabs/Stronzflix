import 'package:flutter/material.dart' show AlignmentGeometry, Alignment;
import 'package:html/dom.dart';
import 'package:stronzflix/backend/api/bindings/mixdrop.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/middleware.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/sutils.dart';
import 'package:html/parser.dart' as html;

class CB01 extends Site {
    static Site instance = CB01._();
    CB01._():  super("CB01", "cb01");

    @override
    AlignmentGeometry get cropPolicy => Alignment.centerRight;

    @override
    bool tunerValidator(String homePage) {
        return homePage.contains('<meta property="og:description" content="Vedi GRATIS +29.000 Film e Serie-TV in Streaming HD in Italiano senza limiti o registrazione. CB01 UFFICIALE (ORIGINALE) by CB01.UNO" />');
    }

    Future<List<TitleMetadata>> _parsePage(String endpoint) async {
        String body = await HTTP.get("${super.url}${endpoint}");
        Document document = html.parse(body);

        List<TitleMetadata> results = [];

        List<Element> elements = document.querySelectorAll(".post");
        for(Element element in elements) {
            String name = element.querySelector(".card-title")!.text;
            String url = element.querySelector('a[href]:not([href="/"])')!.attributes["href"]!;
            String poster = element.querySelector("img")!.attributes["src"]!;

            results.add(TitleMetadata(
                name: name,
                uri: Uri.parse(url),
                site: this,
                poster: Uri.parse(poster)
            ));
        }
    
        return results;
    }

    @override
    Future<List<TitleMetadata>> search(String query) async {
        return this._parsePage("/?s=${query}");
    }

    @override
    Future<List<TitleMetadata>> latests() async {
        return this._parsePage("/");
    }

    @override
    Future<Title> getTitle(TitleMetadata metadata) async {
        String body = await HTTP.get(metadata.uri);
        Document document = html.parse(body);

        String banner = document.getElementById("sequex-page-title-img")!.attributes["data-img"]!;
        String description = document.querySelector(".ignore-css")!.children[1].innerHtml.split("<br>")[0].trim();

        return Film(
            banner: Uri.parse(banner),
            description: description,
            metadata: metadata,
            uri: metadata.uri
        );
    }

    @override
    Future<List<WatchOption>> getOptions(Watchable watchable) async {
        String body = await HTTP.get(watchable.uri);
        Document document = html.parse(body);

        List<Element> tables = document.querySelector(".tableinside")!.parent!.children;

        List<WatchOption> options = [];
        late String scope;
        for(Element element in tables) {
            if(element.querySelector("a") == null) {
                scope = element.text.trim();
                continue;
            }
            if(scope != "Streaming:" && scope != "Streaming HD:")
                continue;
            
            Uri sourceUri = Uri.parse(element.querySelector("a")!.attributes["href"]!);
            sourceUri = await Middleware.resolve(sourceUri);
            
            if(sourceUri.toString().contains("mixdrop"))
                options.add(WatchOption(
                    player: MixDrop.instance,
                    uri: sourceUri
                ));
            else if(sourceUri.toString().contains("maxlinks"))
                print("HEHEHE");
        }

        return options.reversed.toList();
    }
}