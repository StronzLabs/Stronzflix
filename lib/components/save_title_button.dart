import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';

class SaveTitleButton extends StatefulWidget {
    final TitleMetadata title;
    final void Function(bool saved)? onChanged;

    const SaveTitleButton({
        super.key,
        required this.title,
        this.onChanged,
    });

    @override
    State<SaveTitleButton> createState() => _SaveTitleButtonState();
}

class _SaveTitleButtonState extends State<SaveTitleButton> {
    @override
    Widget build(BuildContext context) {
        return IconButton(
            icon: Icon(SavedTitles.isSaved(super.widget.title)
                ? Icons.bookmark_remove
                : Icons.bookmark_add_outlined,
                size: 28,
            ),
            onPressed: () => super.setState(() {
                if(SavedTitles.isSaved(super.widget.title))
                    SavedTitles.remove(super.widget.title);
                else
                    SavedTitles.add(super.widget.title);
                super.widget.onChanged?.call(SavedTitles.isSaved(super.widget.title));
            })
        );
    }
}
