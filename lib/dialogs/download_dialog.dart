import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/select_dropdown.dart';
import 'package:stronzflix/dialogs/loading_dialog.dart';
import 'package:stronzflix/utils/simple_http.dart' as http;
import 'package:stronzflix/utils/utils.dart';

class DownloadDialog extends StatefulWidget {

    final DownloadOptions defaults;
    final List<Variant> variants;
    final List<Rendition> audios;
    final String name;

    const DownloadDialog({
        super.key,
        required this.variants,
        required this.name,
        required this.defaults,
        required this.audios
    });

    @override
    State<DownloadDialog> createState() => _DownloadDialogState();

    static Future<void> open(BuildContext context, Watchable watchable) async {
        HlsPlaylist playlist = await LoadingDialog.load(context, () async {
            Uri url = await watchable.player.getSource(watchable);
            return await HlsPlaylistParser.create().parseString(url, await http.get(url));
        });        
    
        if(playlist is! HlsMasterPlaylist)
            throw Exception("Not a master playlist");

        List<Variant> variants = playlist.variants;
        List<Rendition> audios = playlist.audios;

        Variant defaultVariant = variants.reduce(
            (a, b) => deduceVariantResolution(a) > deduceVariantResolution(b) ? a : b
        );
        Rendition? defaultAudio = audios.firstOrNull;

        DownloadOptions defaultOptions = DownloadOptions(defaultVariant, defaultAudio, watchable);

        DownloadOptions? options = await showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) => DownloadDialog(
                variants: variants,
                audios: audios,
                name: watchable.name,
                defaults: defaultOptions
            )
        );

        if (options == null)
            return;

        await DownloadManager.download(options);
    }
}

class _DownloadDialogState extends State<DownloadDialog> {

    late Variant _selectedVariant = super.widget.defaults.variant;
    late Rendition? _selectedAudio = super.widget.defaults.audio;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text('Scarica ${widget.name}'),
            actions: [
                TextButton(
                    child: const Text('Annulla'),
                    onPressed: () => Navigator.of(context).pop()
                ),
                TextButton(
                    child: const Text("Scarica"),
                    onPressed: () => Navigator.of(context).pop(
                        DownloadOptions(this._selectedVariant, this._selectedAudio, super.widget.defaults.watchable)
                    )
                )
            ],
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    SelectDropDown(
                        label: "Qualità",
                        options: super.widget.variants,
                        selectedValue: this._selectedVariant,
                        onSelected: (e) => this._selectedVariant = e,
                        stringify: (e) => "${deduceVariantResolution(e)}p",
                    ),
                    if (super.widget.audios.isNotEmpty)
                        SelectDropDown(
                            label: "Audio",
                            options: super.widget.audios,
                            selectedValue: this._selectedAudio,
                            onSelected: (e) => this._selectedAudio = e,
                            stringify: (e) => e.name!,
                        )
                ],
            ),
        );
    }
}
