import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';
import 'package:sutils/ui/dialogs/confirmation_dialog.dart';

class DeleteTitleButton extends StatelessWidget {
    final TitleMetadata title;

    const DeleteTitleButton({
        super.key,
        required this.title
    });

    @override
    Widget build(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: SavedTitles.listener,
            builder: (context, _, __) => IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 28,
                ),
                onPressed: () async {
                    bool delete = await ConfirmationDialog.ask(
                        context: context,
                        title: "Elimina ${this.title.name}",
                        text: "Sei sicuro di voler eliminare ${this.title.name}?",
                        confirm: "Elimina"
                    );
                    if (delete)
                        await DownloadManager.deleteTitle(this.title);
                }
            )
        );
    }
}
