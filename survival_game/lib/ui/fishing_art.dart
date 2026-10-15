import 'package:flutter/material.dart';
import '../game/fishing_catalog.dart';

bool hasFishingArt(String id) =>
    fishSpecies.containsKey(id) ||
    preparedFishSource(id) != null ||
    fishingBaits.containsKey(id) ||
    fishingRods.containsKey(id);

class FishingArt extends StatelessWidget {
  const FishingArt(this.id, {super.key, this.icon = false});
  final String id;
  final bool icon;
  @override
  Widget build(BuildContext context) {
    const icons = [
      'small_fish',
      'redfin_perch',
      'mud_whisker',
      'spiny_sunlurker',
      'goldspot_riverfish',
      'prepared',
      'bait',
      'insect_bait',
      'fruit_bait',
      'basic_rod',
      'reinforced_rod',
      'river_rod',
    ];
    final prepared = preparedFishSource(id) != null;
    final gear = fishingRods.containsKey(id);
    final cell = icon
        ? icons.indexOf(prepared ? 'prepared' : id)
        : gear
        ? fishingRods.keys.toList().indexOf(id)
        : prepared
        ? 5
        : fishSpecies[id]?.cell ?? fishingBaits[id]?.cell ?? 0;
    final columns = icon ? 4 : 3, rows = 3;
    final width = icon ? 1448.0 : 1536.0, height = icon ? 1086.0 : 1024.0;
    final source = Rect.fromLTWH(
      (cell % columns) * width / columns,
      (cell ~/ columns) * height / rows,
      width / columns,
      height / rows,
    );
    final asset = icon
        ? 'fishing_icons_atlas_v1'
        : gear
        ? 'fishing_gear_atlas_v1'
        : 'fishing_species_atlas_v1';
    return FittedBox(
      fit: icon ? BoxFit.contain : BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: source.width,
        height: source.height,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.translate(
              offset: -source.topLeft,
              child: Image.asset(
                'assets/art/$asset.png',
                width: width,
                height: height,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
