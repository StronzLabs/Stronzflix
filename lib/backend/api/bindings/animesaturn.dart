import 'package:stronzflix/backend/api/bindings/streampeaker.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

class AnimeSaturn extends Site {

    static Site instance = AnimeSaturn._();
    AnimeSaturn._():  super("AnimeSaturn", "www.animesaturn");

    @override
    bool get allowsDownload => true;

    @override
    bool tunerValidator(String homePage) {
        return homePage.contains("<meta content=\"AnimeSaturn - Streaming di Anime in Sub ITA e ITA\">");
    }

    List<Episode> getEpisodes(Season season, Element episodesGrid, String cover) {
        List<Episode> episodes = [];

        for(Element element in episodesGrid.querySelectorAll(".btn")) {
            String name = element.text.trim();
            String url = element.attributes["href"]!;
            int episodeNo = int.parse(element.text.trim().split("Episodio ")[1]);

            episodes.add(Episode(
                season: season,
                name: name,
                url: url,
                cover: cover,
                player: Streampeaker.instance,
                episodeNo: episodeNo
            ));
        }

        return episodes;
    }

    @override
    Future<Title> getTitle(TitleMetadata metadata) async {
        String body = await http.get(metadata.url);
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
            banner: banner,
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
                name: name,
                episodes: []
            );

            season.episodes.addAll(this.getEpisodes(season, episodes, cover));
            series.seasons.add(season);
        }
        else
            for(Element element in segments) {
                String name = element.text.trim();
                String episodesTag = element.attributes["href"]!;
                Element episodes = document.querySelector(episodesTag)!;

                Season season = Season(
                    series: series,
                    name: name,
                    episodes: []
                );

                season.episodes.addAll(this.getEpisodes(season, episodes, cover));
                series.seasons.add(season);
            }

        return series;
    }

    @override
    Future<List<TitleMetadata>> latests() async {
        String body = await http.get("${super.url}/newest");
        Document document = html.parse(body);

        List<TitleMetadata> results = [];

        for(Element element in document.querySelectorAll(".card.mb-4")) {
            String url = element.querySelector(".image-animation")!.attributes["href"]!;
            String name = element.querySelector(".new-anime")!.attributes["alt"]!;
            String poster = element.querySelector(".new-anime")!.attributes["src"]!;

            results.add(TitleMetadata(
                name: name,
                url: url,
                site: this,
                poster: poster
            ));
        }

        return results;
    }

    @override
    Future<List<TitleMetadata>> search(String query) async {
        String body = await http.get("${super.url}/animelist?search=${Uri.encodeQueryComponent(query)}");
        Document document = html.parse(body);

        List<TitleMetadata> results = [];

        List<Element> elements = document.querySelectorAll(".list-group");
        for(Element element in elements) {
            String name = element.querySelector(".badge-archivio")!.text;
            String url = element.querySelector(".badge-archivio")!.attributes["href"]!;
            String poster = element.querySelector(".locandina-archivio")!.attributes["src"]!;

            results.add(TitleMetadata(
                name: name,
                url: url,
                site: this,
                poster: poster
            ));
        }

        return results;
    }
}