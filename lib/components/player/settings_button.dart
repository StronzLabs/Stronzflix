import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/methods/video_state.dart';
import 'package:stronzflix/utils/utils.dart';

class SettingsButton extends StatefulWidget {
    final void Function()? onOpened;
    final void Function()? onClosed;

    const SettingsButton({
        super.key,
        this.onOpened,
        this.onClosed,
    });

    @override
    State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton> {

    late final VideoController _controller = controller(super.context);

    @override
    Widget build(BuildContext context) {
        return IconButton(
            onPressed: () {
                super.widget.onOpened?.call();
                showDialog(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        alignment: Alignment.bottomRight,
                        insetPadding: const EdgeInsets.only(
                            right: 65,
                            bottom: 65,
                        ),
                        child: _SettingsMenu(
                            controller: this._controller
                        ),
                    )
                ).then((value) => super.widget.onClosed?.call());
            },
            iconSize: 28,
            icon: const Icon(Icons.settings),
        );
    }
}

class _SettingsMenu extends StatefulWidget {
    final VideoController controller;

    const _SettingsMenu({
        required this.controller,
    });

    @override
    State<_SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<_SettingsMenu> {

    late final bool _hasVideoTacks = super.widget.controller.player.state.tracks.video.length > 1;
    late final bool _hasAudioTacks = super.widget.controller.player.state.tracks.audio.length > 1;
    late final bool _hasSubtitleTacks = super.widget.controller.player.state.tracks.subtitle.length > 1;

    int _activeSettingPage = 0;
    late final List<Widget> _pages = [
        this._buildMainPage(),
        this._buildQualityPage(),
        this._buildLanguagePage(),
        this._buildSubtitlePage(),
    ];

    Widget _buildNavigationButton(String text, int id, [bool isBack = false]) {
        List<Widget> children = [
            Text(text),
            Icon(
                isBack ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                size: 17
            )
        ];
        return ListTile(
            title: Row(
                mainAxisAlignment: isBack ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
                children: isBack ? children.reversed.toList() : children,
            ),
            onTap: () => super.setState(() => this._activeSettingPage = id),
        );
    }

    Widget _buildOptionButton(String text, bool selected, void Function() onTap) {
        return  ListTile(
            title: Row(
                    children: [
                        Icon(Icons.check, size: 17, color: selected ? Colors.white : Colors.transparent),
                        const SizedBox(width: 10),
                        Text(text),
                    ],
                ),
            onTap: () {
                onTap();
                Navigator.of(super.context).pop();
            },
        );
    }

    Widget _buildMainPage() {
        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                const ListTile(title: Text("Impostazioni")),
                const Divider(),
                if(this._hasVideoTacks)
                    this._buildNavigationButton("Qualità", 1),
                if(this._hasAudioTacks)
                    this._buildNavigationButton("Lingua", 2),
                if(this._hasSubtitleTacks)
                    this._buildNavigationButton("Sottotitoli", 3),
            ],
        );
    }

    Widget _buildQualityPage() {
        List<VideoTrack> tracks = super.widget.controller.player.state.tracks.video
            .where((track) => track.id != "auto" && track.id != "no").toList()
            ..sort((a, b) => b.h!.compareTo(a.h!));

        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                this._buildNavigationButton("Qualità", 0, true),
                const Divider(),
                for (VideoTrack track in tracks)
                    this._buildOptionButton("${track.h}p", track == super.widget.controller.player.state.track.video,
                        () => super.widget.controller.player.setVideoTrack(track),
                    ),
                this._buildOptionButton("Auto", super.widget.controller.player.state.track.video.id == "auto",
                    () => super.widget.controller.player.setVideoTrack(VideoTrack.auto()),
                ),
            ],
        );
    }

    Widget _buildLanguagePage() {
        List<AudioTrack> tracks = super.widget.controller.player.state.tracks.audio
            .where((track) => track.id != "auto" && track.id != "no").toList();

        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                this._buildNavigationButton("Lingua", 0, true),
                const Divider(),
                for (AudioTrack track in tracks)
                    this._buildOptionButton((track.language?? track.id).capitalize(), track == super.widget.controller.player.state.track.audio,
                        () => super.widget.controller.player.setAudioTrack(track),
                    ),
            ],
        );
    }

    Widget _buildSubtitlePage() {
        List<SubtitleTrack> tracks = super.widget.controller.player.state.tracks.subtitle
            .where((track) => track.id != "auto" && track.id != "no").toList();

        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                this._buildNavigationButton("Sottotitoli", 0, true),
                const Divider(),
                for (SubtitleTrack track in tracks)
                    this._buildOptionButton((track.language?? track.id).capitalize(), track == super.widget.controller.player.state.track.subtitle,
                        () => super.widget.controller.player.setSubtitleTrack(track),
                    ),
                this._buildOptionButton("Nessuno", super.widget.controller.player.state.track.subtitle.id == "no",
                    () => super.widget.controller.player.setSubtitleTrack(SubtitleTrack.no()),
                ),
            ],
        );
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            width: 200,
            decoration: BoxDecoration(
                color: const Color.fromARGB(200, 0, 0, 0),
                borderRadius: BorderRadius.circular(10),
            ),
            child: this._pages[this._activeSettingPage]
        );
    }
}
