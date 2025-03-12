import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:sutils/utils.dart';

class SeasonsDropdownButton extends StatelessWidget {
    
    final Season selectedSeason;
    final List<Season> seasons;
    final Function(Season) onSeasonSelected;

    const SeasonsDropdownButton({
        super.key,
        required this.selectedSeason,
        required this.seasons,
        required this.onSeasonSelected
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).disabledColor, width: 2.0),
                borderRadius: BorderRadius.circular(20.0),
            ),
            child: DropdownButton<Season>(
                focusColor: EPlatform.isTV ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                underline: const SizedBox.shrink(),
                value: this.selectedSeason,
                items: [
                    for (Season season in this.seasons)
                        DropdownMenuItem(
                            value: season,
                            child: Text(season.name ?? "Stagione ${season.seasonNo}")
                        )
                ],
                onChanged: this.seasons.length == 1 ? null : (selected) => this.onSeasonSelected(selected!)
            )
        );
    }
}
