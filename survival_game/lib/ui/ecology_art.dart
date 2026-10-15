import 'package:flutter/material.dart';

const ecologyPlantIds = [
  'ember_berries',
  'dew_fruit',
  'canopy_fig',
  'iron_nut',
  'wild_honey',
  'ribbon_root',
  'wax_berries',
  'mooncap',
  'herb',
];
const ecologySupplyIds = [
  'antidote',
  'bandage',
  'charcoal',
  'leaf_rain_cape',
  'dry_fire',
  'cooked_root',
  'trail_marker',
  'herbal_tea',
];
const ecologyIconIds = [
  'ember_berries',
  'dew_fruit',
  'canopy_fig',
  'iron_nut',
  'wild_honey',
  'ribbon_root',
  'wax_berries',
  'mooncap',
  'antidote',
  'bandage',
  'charcoal',
  'leaf_rain_cape',
  'poisoned',
  'injured',
  'wet',
  'exhausted',
];
bool hasEcologyArt(String id) =>
    ecologyPlantIds.contains(id) || ecologySupplyIds.contains(id);

/// Crop the original generated atlas at render time; inventory icons retain alpha.
class EcologyArt extends StatelessWidget {
  const EcologyArt(this.id, {super.key, this.icon = false});
  final String id;
  final bool icon;
  @override
  Widget build(BuildContext context) {
    final isIcon = icon && ecologyIconIds.contains(id);
    final supplies = ecologySupplyIds.contains(id);
    final ids = isIcon
        ? ecologyIconIds
        : supplies
        ? ecologySupplyIds
        : ecologyPlantIds;
    final index = ids.indexOf(id);
    if (index < 0) return const SizedBox.shrink();
    final columns = isIcon ? 4 : 3;
    final atlas = isIcon
        ? 'ecology_icons_atlas_v1'
        : supplies
        ? 'ecology_supplies_atlas_v1'
        : 'ecology_plants_atlas_v1';
    final width = isIcon ? 1254.0 : 1536.0;
    final height = isIcon ? 1254.0 : 1024.0;
    final cellWidth = width / columns, cellHeight = height / columns;
    return FittedBox(
      fit: isIcon ? BoxFit.contain : BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: cellWidth,
        height: cellHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.translate(
              offset: Offset(
                -(index % columns) * cellWidth,
                -(index ~/ columns) * cellHeight,
              ),
              child: Image.asset(
                'assets/art/$atlas.png',
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
