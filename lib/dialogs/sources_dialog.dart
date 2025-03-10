import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:sutils/ui/widgets/select_dropdown.dart';

class SourcesDialog extends StatelessWidget {

    final List<WatchOption> options;

    const SourcesDialog({
        super.key,
        required this.options
    });

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Più sorgenti sono disonibili'),
            content: SelectDropDown<WatchOption>(
                options: this.options,
                selectedValue: null,
                onSelected: (selection) => Navigator.of(context).pop(selection),
                stringify: (option) => option.displayName,
                initiallyExpanded: true,
            )
        );
    }
}
