import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';

class SearchPage extends SearchDelegate {

    String _lastQuery = "";
    AsyncMemoizer _memorizer = AsyncMemoizer();

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

    Widget _buildGrid(BuildContext context, List<TitleMetadata> results) {
        return GridView.extent(
            childAspectRatio: 2 / 3,
            maxCrossAxisExtent: 250,
            children: results.map((TitleMetadata result) =>
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ResultCard(
                        onTap: (uuid) => Navigator.pushNamed(context, '/title', arguments: [ uuid, result ]),
                        imageUrl: result.poster,
                        text: result.name,
                        action: Settings.site.isLocal
                            ? () => this._delete(context, result)
                            : null,
                        actionIcon: Icons.delete,
                    )
                )
            ).toList()
        );
    }

    @override
    Widget buildResults(BuildContext context) {
        if(super.query != this._lastQuery) {
            this._lastQuery = super.query;
            this._memorizer = AsyncMemoizer();
        }

        return FutureBuilder(
            future: this._memorizer.runOnce(() => Settings.site.search(super.query)),
            builder: (context, snapshot) {
                if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                if(snapshot.data!.isEmpty)
                    return this._buildNoResults(context);

                return this._buildGrid(context, snapshot.data!);
            }
        );
    }

    @override
    Widget buildSuggestions(BuildContext context) => this.buildResults(context);

    void _delete(BuildContext context, TitleMetadata metadata) async {
        bool delete = await ConfirmationDialog.ask(context,
            "Elimina ${metadata.name}",
            "Sei sicuro di voler eliminare ${metadata.name}?",
            action: "Elimina"
        );
        if (delete) {
            await DownloadManager.delete(await Settings.site.getTitle(metadata));
            if(context.mounted)
                super.showResults(context);
        }
    }
}
