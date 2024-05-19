import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/settings.dart';
import 'package:stronzflix/components/result_card.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';

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
                        onTap: () => Navigator.pushNamed(context, '/title', arguments: result),
                        imageUrl: result.poster,
                        text: result.name,
                        action: Site.get(Settings.site)!.isLocal
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
        return FutureBuilder(
            future: Site.get(Settings.site)?.search(super.query),
            builder: (context, snapshot) {
                if (snapshot.hasData)
                    if(snapshot.data!.isEmpty)
                        return this._buildNoResults(context);
                    else
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

    void _delete(BuildContext context, TitleMetadata metadata) async {
        bool delete = await ConfirmationDialog.ask(context,
            "Elimina ${metadata.name}",
            "Sei sicuro di voler eliminare ${metadata.name}?",
            action: "Elimina"
        );
        if (delete) {
            await DownloadManager.delete(await Site.get(Settings.site)!.getTitle(metadata));
            // ignore: use_build_context_synchronously
            super.showResults(context);
        }
    }
}
