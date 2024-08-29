import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/select_dropdown.dart';
import 'package:stronzflix/dialogs/loading_dialog.dart';
import 'package:stronzflix/utils/utils.dart';
import 'package:sutils/sutils.dart';

class DownloadDialog extends StatefulWidget {

    final DownloadOptions defaults;
    final List<Variant> variants;
    final List<Rendition> audios;
    final String name;

    const DownloadDialog({
        super.key,
        this.variants = const [],
        this.audios = const [],
        required this.name,
        required this.defaults,
    });

    @override
    State<DownloadDialog> createState() => _DownloadDialogState();

    static Future<DownloadOptions?> _openHls(BuildContext context, Watchable watchable, Uri url) async {
        HlsPlaylist playlist = await LoadingDialog.load(context, () async {
            return await HlsPlaylistParser.create().parseString(url, await HTTP.get(url));
        });        
    
        if(playlist is! HlsMasterPlaylist)
            throw Exception("Not a master playlist");

        List<Variant> variants = playlist.variants;
        List<Rendition> audios = playlist.audios;

        Variant defaultVariant = variants.reduce(
            (a, b) => deduceVariantResolution(a) > deduceVariantResolution(b) ? a : b
        );
        Rendition? defaultAudio = audios.firstOrNull;

        if(!context.mounted)
            return null;

        DownloadOptions? options = await showDialog(
            context: context,
            builder: (context) => DownloadDialog(
                variants: variants,
                audios: audios,
                name: watchable.title,
                defaults:  DownloadOptions(watchable, variant: defaultVariant, audio: defaultAudio)
            )
        );

        return options;
    }

    static Future<DownloadOptions?> _openMp4(BuildContext context, Watchable watchable, Uri url) async {
        DownloadOptions? options = await showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) => DownloadDialog(
                name: watchable.title,
                defaults: DownloadOptions(watchable, url: url)
            )
        );

        return options;
    }

    static Future<void> open(BuildContext context, Watchable watchable) async {

        Uri url = await LoadingDialog.load(context, () async => await watchable.player.getSource(watchable));
        String mime = await HTTP.mime(url);

        if(!context.mounted)
            return;

        DownloadOptions? options = switch(mime) {
            // ignore: use_build_context_synchronously
            "application/vnd.apple.mpegurl" => await _openHls(context, watchable, url),
            // ignore: use_build_context_synchronously
            "video/mp4" => await _openMp4(context, watchable, url),
            _ => throw Exception("Unsupported mime type: ${mime}")
        };

        if (options == null)
            return;

        await DownloadManager.download(options);
    }
}

class _DownloadDialogState extends State<DownloadDialog> {

    late Variant? _selectedVariant = super.widget.defaults.variant;
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
                        DownloadOptions(
                            super.widget.defaults.watchable,
                            variant: this._selectedVariant,
                            audio: this._selectedAudio,
                            url: super.widget.defaults.url
                        )
                    )
                )
            ],
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    if (super.widget.variants.isNotEmpty)
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
