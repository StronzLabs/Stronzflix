import 'package:flutter/material.dart';
import 'package:stronzflix/backend/media.dart';
import 'package:stronzflix/backend/media.dart' as SF;
import 'package:stronzflix/backend/result.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/views/media.dart';

class TitlePage extends StatefulWidget {
    final Result result;

    const TitlePage({super.key, required this.result});

    @override
    State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> {

    late int _selectedSeason;
    late Future<SF.Title> _title;

    @override
    void initState() {
        super.initState();
        this._title = super.widget.result.site.getTitle(super.widget.result);
        this._selectedSeason = 1;
    }

    void _playMedia(BuildContext context, IWatchable media) {
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => MediaPage(media: media)
        ));
    }

    Widget _buildFilm(BuildContext context, Film film) {
        return Center(
            child: TextButton(
                onPressed: () => this._playMedia(context, film),
                child: const Text("Guarda ora")
            )
        );
    }

    Widget _buildSeries(BuildContext context, Series series) {
        List<Episode> episodes = series.seasons[this._selectedSeason - 1];
        
        return GridView.extent(
            childAspectRatio: 3 / 2,
            maxCrossAxisExtent: 400,
            children: episodes.map((Episode episode) =>
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ResultCard(
                        onTap: () => this._playMedia(context, episode),
                        imageUrl: episode.cover,
                        text: episode.name
                    )
                )
            ).toList()
        );
    }

    Widget _buildTitle(BuildContext context, SF.Title title) {
        if (title is Film)
            return this._buildFilm(context, title);
        else if (title is Series)
            return this._buildSeries(context, title);
        else
            throw Exception("Unknown title type");
    }

    Widget _buldDropdownSeasons(BuildContext context, Series title) {
        return DropdownButton(
            value: this._selectedSeason,
            items: List.generate(title.seasons.length, (index) =>
                DropdownMenuItem(
                    value: index + 1,
                    child: Text("Stagione ${index + 1}")
                )
            ),
            onChanged: (value) => setState(() =>
                this._selectedSeason = value!
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Center(
                    child: Text(super.widget.result.name)
                ),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop()
                ),
                actions: [
                    FutureBuilder(
                        future: this._title,
                        builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data is Series)
                                return this._buldDropdownSeasons(context, snapshot.data as Series);
                            return Container();
                        }
                    )
                ]
            ),
            body: FutureBuilder(
                future: this._title,
                builder: (context, snapshot) {
                    if(snapshot.hasData)
                        return this._buildTitle(context, snapshot.data as SF.Title);
                    else
                        return const Center(
                            child: CircularProgressIndicator()
                        );
                }
            )
        );
    }
}
