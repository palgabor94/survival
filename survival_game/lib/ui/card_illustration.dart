/// Full-background card illustrations. Small HUD icons keep using CardArt.
const cardIllustrationSubjects = <String>[
  'machete',
  'emergency_beacon',
  'battery',
  'wire',
  'metal_parts',
  'radio_module',
  'beacon_core',
  'forage',
  'stone_axe',
  'basic_rod',
  'torch',
  'stone_knife',
  'stone_spear',
  'back',
  'trail',
  'small_fish',
  'bait',
  'herb',
  'raw_meat',
  'water_filter',
  'rain_collector',
  'drying_rack',
  'journal',
  'health',
  'water',
  'food',
  'sanity',
  'stone',
  'fiber',
  'sun',
  'shelter',
  'inventory',
  'map',
  'moon',
  'hardwood',
  'metal_scrap',
  'leaf_bed',
  'firewood',
  'craft',
  'camp_tier_1',
  'camp_tier_2',
  'camp_tier_3',
];

String? cardIllustrationFor(String subject) {
  final id = {'trail_backpack', 'expedition_pack'}.contains(subject)
      ? 'inventory'
      : subject == 'wood'
      ? 'firewood'
      : subject;
  return cardIllustrationSubjects.contains(id)
      ? 'assets/art/card_${id}_scene_v1.png'
      : null;
}
