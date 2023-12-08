import 'package:flutter/material.dart';
import 'package:stronzflix/backend/result.dart';
import 'package:stronzflix/backend/site.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/views/title.dart';

class SearchPage extends SearchDelegate {

    @override
    ThemeData appBarTheme(BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
                background: theme.colorScheme.surface
            )
        );
    }

    @override
    String get searchFieldLabel => "Cerca su Stronzflix";

    @override
    List<Widget> buildActions(BuildContext context) {
        return [
            IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => super.query = ""
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

    @override
    Widget buildSuggestions(BuildContext context) => this.buildResults(context);

    Widget buildGrid(BuildContext context, List<Result> results) {
        return GridView.extent(
            childAspectRatio: 2 / 3,
            maxCrossAxisExtent: 250,
            children: results.map((Result result) =>
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ResultCard(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) =>
                                TitlePage(result: result)
                            )
                        ),
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
                    return this.buildGrid(context, snapshot.data!);
                else
                    return const Center(
                        child: CircularProgressIndicator()
                    );
            }
        );
    }
}
