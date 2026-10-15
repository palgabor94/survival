import 'run_state.dart';

/// Fictional species have fixed properties across saves and runs.
class JungleFood {
  const JungleFood(
    this.id,
    this.name,
    this.description,
    this.nutrition, {
    this.poison = 0,
    this.requiresKnife = false,
  });
  final String id, name, description;
  final Map<SurvivalStat, int> nutrition;
  final int poison;
  final bool requiresKnife;
}

const jungleFoods = <String, JungleFood>{
  'ember_berries': JungleFood(
    'ember_berries',
    'Ember Berries',
    'Three red berries on star-shaped leaves. A reliable trail food.',
    {SurvivalStat.food: 12, SurvivalStat.water: 2},
  ),
  'dew_fruit': JungleFood(
    'dew_fruit',
    'Dew Fruit',
    'A yellow teardrop nestled in a broad leaf cup. Refreshing and juicy.',
    {SurvivalStat.food: 8, SurvivalStat.water: 14},
  ),
  'canopy_fig': JungleFood(
    'canopy_fig',
    'Canopy Fig',
    'A ribbed orange fruit found high in the canopy.',
    {SurvivalStat.food: 18, SurvivalStat.water: 6},
  ),
  'iron_nut': JungleFood(
    'iron_nut',
    'Iron Nut',
    'A heavy hexagonal shell. Open with a knife at camp.',
    {SurvivalStat.food: 22, SurvivalStat.water: -3},
    requiresKnife: true,
  ),
  'wild_honey': JungleFood(
    'wild_honey',
    'Wild Honey',
    'Amber honey from a hollow jungle trunk.',
    {SurvivalStat.food: 16, SurvivalStat.sanity: 3},
  ),
  'ribbon_root': JungleFood(
    'ribbon_root',
    'Ribbon Root',
    'Purple-striped roots. Prepare at camp before eating.',
    {SurvivalStat.food: 5},
    poison: 1,
  ),
  'wax_berries': JungleFood(
    'wax_berries',
    'Wax Berries',
    'Blue pairs with white dots and round waxy leaves. Toxic; useful as trail dye.',
    {SurvivalStat.food: 6},
    poison: 1,
  ),
  'mooncap': JungleFood(
    'mooncap',
    'Mooncap',
    'Ivory cap, blue ring on the stem. Toxic even after cooking.',
    {SurvivalStat.food: 4},
    poison: 2,
  ),
  'cooked_root': JungleFood(
    'cooked_root',
    'Prepared Roots',
    'Ribbon roots carefully prepared over the campfire.',
    {SurvivalStat.food: 18},
  ),
};
