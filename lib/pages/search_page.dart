import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/components/save_title_button.dart';
import 'package:stronzflix/components/title_card.dart';
import 'package:stronzflix/components/card_grid.dart';

class SearchPage extends SearchDelegate {

    String _lastQuery = "";
    AsyncMemoizer<List<TitleMetadata>> _memorizer = AsyncMemoizer<List<TitleMetadata>>();

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

    Widget _buildNoResults(BuildContext context) {
        return const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.search_off, size: 100),
                    SizedBox(height: 10),
                    Text("Nessun risultato")
                ]
            )
        );
    }

    @override
    Widget buildResults(BuildContext context) {
        if(super.query != this._lastQuery) {
            this._lastQuery = super.query;
            this._memorizer = AsyncMemoizer<List<TitleMetadata>>();
        }

        return FutureBuilder(
            future: this._memorizer.runOnce(() => Settings.site.search(super.query)),
            builder: (context, snapshot) {
                if(snapshot.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());

                return CardGrid(
                    values: snapshot.data!,
                    buildCard: (metadata) => TitleCard(
                        title: metadata,
                        buildAction: Settings.site.isLocal
                            ? null
                            : (metadata) => SaveTitleButton(title: metadata)
                    ),
                    emptyWidget: this._buildNoResults(context),
                );
            }
        );
    }

    @override
    Widget buildSuggestions(BuildContext context) => this.buildResults(context);
}
