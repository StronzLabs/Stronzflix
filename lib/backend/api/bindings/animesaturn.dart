import 'package:encrypt/encrypt.dart';
import 'package:stronzflix/backend/api/bindings/jwplayer.dart';
import 'package:stronzflix/backend/api/bindings/streampeaker.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'package:sutils/utils.dart';

final class CookieCaptchaHTTPMiddleware extends HTTPProcessor {
    Map<String, String>? _cookie;

    CookieCaptchaHTTPMiddleware([super._parent]);

    @override
    Future<Request> beforeRequest(Request request) async {
        if(this._cookie == null)
            return request;

        return request.copyWith(headers: this._cookie);
    }

    @override
    Future<Response> process(Request request, Duration? timeout) async {
        Response response = await super.parent.process(request, timeout);

        if(!response.body.contains("document.cookie=\""))
            return response;

        Document document = html.parse(response.body);
        String script = document.getElementsByTagName("script").last.text;
        
        String a = script.split("a=toNumbers(\"")[1].split("\")")[0];
        String b = script.split("b=toNumbers(\"")[1].split("\")")[0];
        String c = script.split("c=toNumbers(\"")[1].split("\")")[0];

        String cookieName = script.split("document.cookie=\"")[1].split("=\"")[0];

        Encrypter encrypter = Encrypter(AES(Key.fromBase16(a), mode: AESMode.cbc, padding: null));
        List<int> decrypted = encrypter.decryptBytes(Encrypted.fromBase16(c), iv: IV.fromBase16(b));
        String cookieValue = decrypted.map((int byte) => byte.toRadixString(16).padLeft(2, "0")).join();

        this._cookie = { "Cookie": "${cookieName}=${cookieValue}" };

        request = await this.beforeRequest(request);
        return super.parent.process(request, timeout);
    }
}

class AnimeSaturn extends Site {
    static Site instance = AnimeSaturn._();
    AnimeSaturn._() : super("AnimeSaturn", "www.animesaturn", 1, CookieCaptchaHTTPMiddleware());

    @override
    Future<Uri> getFavicon() async {
        String body = await super.chain.get(this.url);
        RegExpMatch match = RegExp(r'<link rel="icon".*href="(?<favicon>[^"]+)"').firstMatch(body)!;
        String url = match.namedGroup("favicon")!;
        if(url.startsWith("//"))
            url = "https:$url";
        else if(url.startsWith("/"))
            url = "${this.url}$url";
        return Uri.parse(url);
    }

    @override
    Future<bool> tunerValidator(String homePage) async {
        return homePage.contains("<meta content=\"AnimeSaturn - Streaming di Anime in Sub ITA e ITA\">");
    }

    List<Episode> getEpisodes(Season season, Element episodesGrid, String cover) {
        List<Episode> episodes = [];

        for(Element element in episodesGrid.querySelectorAll(".btn")) {
            String name = element.text.trim();
            String url = element.attributes["href"]!;
            // TODO: improve this
            int? episodeNo = int.tryParse(element.attributes["href"]!.split("-").last);
            episodeNo ??= -episodes.length;

            episodes.add(Episode(
                season: season,
                name: name,
                uri: Uri.parse(url),
                cover: Uri.parse(cover),
                episodeNo: episodeNo
            ));
        }

        return episodes;
    }

    @override
    Future<Title> getTitle(TitleMetadata metadata) async {
        String body = await super.chain.get(metadata.uri);
        Document document = html.parse(body);

        String banner = document.querySelector(".banner")!.attributes["style"]!.split("'")[1];
        String description = (document.querySelector("#full-trama") ?? document.querySelector("#shown-trama"))!.text;
        
        Element coverDialog = document.querySelector("#modal-cover-anime")!;
        String cover = coverDialog.querySelector(".img-fluid")!.attributes["src"]!;

        Element? alert = document.querySelector(".alert-primary");
        String? releaseDate = alert?.querySelector("b")?.text;
        Map<String, String> months = {
            "Gennaio": "01",
            "Febbraio": "02",
            "Marzo": "03",
            "Aprile": "04",
            "Maggio": "05",
            "Giugno": "06",
            "Luglio": "07",
            "Agosto": "08",
            "Settembre": "09",
            "Ottobre": "10",
            "Novembre": "11",
            "Dicembre": "12"
        };
        for(String month in months.keys)
            releaseDate = releaseDate?.replaceAll(month, months[month]!);
        releaseDate = releaseDate?.split(" ").reversed.join("-");
        DateTime? coomingSoon = releaseDate != null ? DateTime.parse(releaseDate) : null;

        Series series = Series(
            banner: Uri.parse(banner),
            description: description,
            seasons: [],
            metadata: metadata,
            comingSoon: coomingSoon
        );

        if (alert != null)
            return series;

        List<Element> segments = document.querySelectorAll(".episode-range");
        if(segments.isEmpty) {
            Element episodes = document.querySelector("#range-anime-0")!;

            Season season = Season(
                series: series,
                name: "Lista Episodi",
                episodes: [],
                seasonNo: 1
            );

            season.episodes.addAll(this.getEpisodes(season, episodes, cover));
            series.seasons.add(season);
        }
        else
            for(final (index, element) in segments.indexed) {
                String name = element.text.trim();
                String episodesTag = element.attributes["href"]!;
                Element episodes = document.querySelector(episodesTag)!;

                Season season = Season(
                    series: series,
                    name: name,
                    episodes: [],
                    seasonNo: index + 1
                );

                season.episodes.addAll(this.getEpisodes(season, episodes, cover));
                series.seasons.add(season);
            }

        return series;
    }

    @override
    Future<List<TitleMetadata>> latests() async {
        String body = await super.chain.get("${super.url}/newest");
        Document document = html.parse(body);

        List<TitleMetadata> results = [];

        for(Element element in document.querySelectorAll(".card.mb-4")) {
            String url = element.querySelector(".image-animation")!.attributes["href"]!;
            String name = element.querySelector(".new-anime")!.attributes["alt"]!;
            String poster = element.querySelector(".new-anime")!.attributes["src"]!;

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
        String body = await super.chain.get("${super.url}/animelist?search=${Uri.encodeQueryComponent(query)}");
        Document document = html.parse(body);

        List<TitleMetadata> results = [];

        List<Element> elements = document.querySelectorAll(".list-group");
        for(Element element in elements) {
            String name = element.querySelector(".badge-archivio")!.text;
            String url = element.querySelector(".badge-archivio")!.attributes["href"]!;
            String poster = element.querySelector(".locandina-archivio")!.attributes["src"]!;

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
    Future<List<WatchOption>> getOptions(Watchable watchable) async {
        String passBody = await super.chain.get(watchable.uri);
        Document passDocument = html.parse(passBody);

        String episodeUrl = passDocument.querySelector(".card-body")!.querySelector("a")!.attributes["href"]!;
        String body = await super.chain.get(episodeUrl);
        Document document = html.parse(body);

        List<String> urls = [
            episodeUrl,
            for(Element element in document.querySelectorAll(".dropdown-item"))
                element.attributes["href"]!
        ];
        
        List<WatchOption> options = [];
        for(String url in urls) {
            String body = await super.chain.get(url);

            if(body.contains("jwplayer"))
                options.add(WatchOption(
                    player: JWPlayer.instance,
                    uri: Uri.parse(url)
                ));
            else if(body.contains("streampeaker"))
                options.add(WatchOption(
                    player: Streampeaker.instance,
                    uri: Uri.parse(url)
                ));
        }

        return options;
    }
}
