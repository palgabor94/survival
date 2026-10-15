import 'package:flutter/material.dart';
import 'item_icon.dart';
import 'ecology_art.dart';
import 'fishing_art.dart';

/// Fits each complete painted object from its atlas into the available space.
class CardArt extends StatelessWidget {
  const CardArt(this.id, {super.key, this.size = 72});
  final String id;
  final double size;

  // The generated atlases have uneven gutters and off-center objects.
  // Keep a separate source rectangle per subject instead of cropping every
  // cell by the same inset. Coordinates are fractions of the source image.
  static const _objects = <String, Rect>{
    'forage': Rect.fromLTRB(.035, .065, .23, .23),
    'stone_axe': Rect.fromLTRB(.29, .055, .47, .24),
    'craft': Rect.fromLTRB(.29, .055, .47, .24),
    'basic_rod': Rect.fromLTRB(.51, .065, .72, .23),
    'torch': Rect.fromLTRB(.77, .035, .95, .245),
    'stone_knife': Rect.fromLTRB(.025, .30, .21, .48),
    'stone_spear': Rect.fromLTRB(.28, .28, .46, .485),
    'back': Rect.fromLTRB(.53, .30, .71, .465),
    'trail': Rect.fromLTRB(.77, .30, .97, .48),
    'small_fish': Rect.fromLTRB(.035, .54, .22, .685),
    'bait': Rect.fromLTRB(.285, .525, .465, .68),
    'herb': Rect.fromLTRB(.52, .53, .71, .705),
    'raw_meat': Rect.fromLTRB(.77, .515, .965, .705),
    'water_filter': Rect.fromLTRB(.04, .745, .215, .95),
    'rain_collector': Rect.fromLTRB(.285, .73, .46, .96),
    'drying_rack': Rect.fromLTRB(.5, .735, .715, .955),
    'journal': Rect.fromLTRB(.77, .75, .965, .96),
  };
  static const _hud = <String, Rect>{
    'health': Rect.fromLTRB(.028, .062, .255, .33),
    'water': Rect.fromLTRB(.294, .027, .461, .35),
    'food': Rect.fromLTRB(.5, .066, .727, .339),
    'sanity': Rect.fromLTRB(.746, .06, .978, .34),
    'wood': Rect.fromLTRB(.029, .38, .262, .653),
    'stone': Rect.fromLTRB(.27, .375, .48, .634),
    'fiber': Rect.fromLTRB(.512, .353, .724, .67),
    'sun': Rect.fromLTRB(.747, .348, .978, .652),
    'shelter': Rect.fromLTRB(.022, .648, .258, .957),
    'inventory': Rect.fromLTRB(.276, .66, .487, .96),
    'map': Rect.fromLTRB(.506, .66, .745, .961),
    'moon': Rect.fromLTRB(.77, .66, .978, .95),
  };
  static const _campObjects = <String, Rect>{
    'hardwood': Rect.fromLTRB(.03, .05, .52, .485),
    'metal_scrap': Rect.fromLTRB(.52, .095, .96, .48),
    'leaf_bed': Rect.fromLTRB(.02, .53, .535, .945),
    'firewood': Rect.fromLTRB(.535, .52, .97, .95),
  };

  @override
  Widget build(BuildContext context) {
    if (hasFishingArt(id)) {
      return SizedBox.square(
        dimension: size,
        child: FishingArt(id, icon: true),
      );
    }
    if (id == 'cooked_root') {
      return SizedBox.square(
        dimension: size,
        child: const EcologyArt('ribbon_root', icon: true),
      );
    }
    if (ecologyIconIds.contains(id)) {
      return SizedBox.square(
        dimension: size,
        child: EcologyArt(id, icon: true),
      );
    }
    final standalone = itemIconFor(id);
    if (standalone != null) {
      return ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(standalone, fit: BoxFit.contain, cacheWidth: 180),
        ),
      );
    }
    final camp = _campObjects[id];
    final hud = _hud[id];
    final bounds = camp ?? hud ?? _objects[id] ?? _objects['trail']!;
    final atlas = camp != null
        ? 'assets/art/camp_objects_atlas.png'
        : hud != null
        ? 'assets/art/hud_atlas.png'
        : 'assets/art/card_art_atlas_v2.png';
    final atlasSize = hud != null
        ? const Size(1448, 1086)
        : const Size(1254, 1254);
    final source = Rect.fromLTRB(
      bounds.left * atlasSize.width,
      bounds.top * atlasSize.height,
      bounds.right * atlasSize.width,
      bounds.bottom * atlasSize.height,
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: source.width,
            height: source.height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: atlasSize.width,
                maxWidth: atlasSize.width,
                minHeight: atlasSize.height,
                maxHeight: atlasSize.height,
                child: Transform.translate(
                  offset: -source.topLeft,
                  child: Image.asset(
                    atlas,
                    width: atlasSize.width,
                    height: atlasSize.height,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String artForIcon(IconData icon) =>
    {
      Icons.phishing_rounded: 'basic_rod',
      Icons.content_cut_rounded: 'stone_knife',
      Icons.carpenter_rounded: 'stone_axe',
      Icons.handyman_rounded: 'craft',
      Icons.construction_rounded: 'craft',
      Icons.local_fire_department_rounded: 'torch',
      Icons.fireplace_rounded: 'torch',
      Icons.arrow_upward_rounded: 'stone_spear',
      Icons.call_made_rounded: 'stone_spear',
      Icons.directions_run_rounded: 'back',
      Icons.arrow_back_rounded: 'back',
      Icons.home_rounded: 'shelter',
      Icons.home_work_rounded: 'shelter',
      Icons.bed_rounded: 'leaf_bed',
      Icons.filter_alt_rounded: 'water_filter',
      Icons.umbrella_rounded: 'rain_collector',
      Icons.set_meal_rounded: 'small_fish',
      Icons.spa_rounded: 'herb',
      Icons.grass_rounded: 'fiber',
      Icons.forest_rounded: 'wood',
      Icons.water_drop_rounded: 'water',
      Icons.restaurant_rounded: 'forage',
      Icons.favorite_rounded: 'health',
      Icons.psychology_rounded: 'sanity',
      Icons.self_improvement_rounded: 'sanity',
      Icons.pest_control_rounded: 'bait',
      Icons.inventory_2_rounded: 'inventory',
    }[icon] ??
    'trail';
