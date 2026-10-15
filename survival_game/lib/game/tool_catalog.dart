/// Stable tool identities shared by equipment, event requirements and saves.
class FieldTool {
  const FieldTool(
    this.id,
    this.name,
    this.family,
    this.tier,
    this.durability,
    this.repairs,
  );
  final String id, name, family;
  final int tier, durability;
  final Map<String, int> repairs;
  double get goodScale => 1 + tier * .1;
  double get chanceBonus => family == 'spear' ? [0.0, .08, .15][tier] : 0;
}

const fieldTools = <String, FieldTool>{
  'stone_axe': FieldTool('stone_axe', 'Stone Axe', 'axe', 0, 10, {
    'stone': 1,
    'fiber': 1,
  }),
  'reinforced_axe': FieldTool(
    'reinforced_axe',
    'Reinforced Axe',
    'axe',
    1,
    16,
    {'stone': 1, 'fiber': 2},
  ),
  'salvage_axe': FieldTool('salvage_axe', 'Salvage Axe', 'axe', 2, 24, {
    'metal_scrap': 1,
    'fiber': 2,
  }),
  'stone_spear': FieldTool('stone_spear', 'Stone Spear', 'spear', 0, 10, {
    'stone': 1,
    'fiber': 2,
  }),
  'hunting_spear': FieldTool('hunting_spear', 'Hunting Spear', 'spear', 1, 16, {
    'stone': 1,
    'fiber': 2,
  }),
  'salvage_spear': FieldTool('salvage_spear', 'Salvage Spear', 'spear', 2, 24, {
    'metal_scrap': 1,
    'fiber': 2,
  }),
};
String? requirementFamily(String id) => switch (id) {
  'stone_axe' => 'axe',
  'stone_spear' => 'spear',
  _ => null,
};
