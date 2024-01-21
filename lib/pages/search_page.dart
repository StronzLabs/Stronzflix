import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/pages/title_page.dart';

class SearchPage extends SearchDelegate {

    // fluterr doesn't propagate the theme to the search bar automatically
    @override
    ThemeData appBarTheme(BuildContext context) {
        return Theme.of(context);
    }

    @override
    String get searchFieldLabel => "Cerca su Stronzflix";

    @override
    List<Widget> buildActions(BuildContext context) {
        return [
            Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => super.query = ""
                )
            )
        ];
    }

    @override
    Widget buildLeading(BuildContext context) {
        return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => super.close(context, null)
        );
    }

    void _openResult(BuildContext context, SearchResult result) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TitlePage(result: result)
            )
        );
    }

    Widget _buildGrid(BuildContext context, List<SearchResult> results) {
        return GridView.extent(
            childAspectRatio: 2 / 3,
            maxCrossAxisExtent: 250,
            children: results.map((SearchResult result) =>
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ResultCard(
                        onTap: () => this._openResult(context, result),
                        imageUrl: result.poster,
                        text: result.name
                    )
                )
            ).toList()
        );
    }

    @override
    Widget buildResults(BuildContext context) {
        return FutureBuilder(
            future: Site.get("StreamingCommunity")?.search(super.query),
            builder: (context, snapshot) {
                if (snapshot.hasData)
                    return this._buildGrid(context, snapshot.data!);
                else
                    return const Center(
                        child: CircularProgressIndicator()
                    );
            }
        );
    }

    @override
    Widget buildSuggestions(BuildContext context) => this.buildResults(context);
}
