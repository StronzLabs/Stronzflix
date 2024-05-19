import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/components/player_info_prodiver.dart';
import 'package:stronzflix/utils/utils.dart';

class NextButton extends StatefulWidget {

    const NextButton({
        super.key,
    });

    @override
    State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton> {

    late Watchable? _next;

    @override
    void didChangeDependencies() {
        Watchable current = FullScreenProvider.of<PlayerInfo>(context).watchable;
        if (current is Episode) {
            Season season = current.season;
            Series series = season.series;
            int episodeNo = season.episodes.indexOf(current);
            int seasonNo = series.seasons.indexOf(season);

            if (episodeNo < season.episodes.length - 1)
                this._next = season.episodes[episodeNo + 1];
            else if (seasonNo < series.seasons.length - 1)
                this._next = series.seasons[seasonNo + 1].episodes[0];
            else
                this._next = null;        
        } else
            this._next = null;
        super.didChangeDependencies();
    }

    @override
    Widget build(BuildContext context) {
        return IconButton(
            onPressed: () => FullScreenProvider.of<PlayerInfo>(context, listen: false).switchTo(this._next!),
            iconSize: 28.0,
            icon: const Icon(Icons.skip_next),
        );
    }
}
