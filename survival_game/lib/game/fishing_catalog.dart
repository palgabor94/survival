import 'dart:math';

/// Fictional species have stable food safety; only the caught size varies.
class FishSpecies {
  const FishSpecies(
    this.id,
    this.name,
    this.rarity,
    this.cell,
    this.food,
    this.minLength,
    this.maxLength,
    this.minWeight,
    this.maxWeight, {
    this.minRod = 0,
    this.minDay = 1,
    this.poison = 0,
    this.requiresKnife = false,
    this.habitat = 'Quiet jungle pools and river bends.',
  });
  final String id, name, rarity, habitat;
  final int cell, food, minLength, maxLength, minRod, minDay, poison;
  final double minWeight, maxWeight;
  final bool requiresKnife;
  bool get hazardous => poison > 0;
  String get preparedId => 'prepared_$id';
  String get handling => id == 'mud_whisker'
      ? 'Clean and cook at camp. Eating it raw causes Poisoned I.'
      : id == 'spiny_sunlurker'
      ? 'Venomous spines. Remove with a knife and cook at camp. Eating it unprepared causes Poisoned II.'
      : 'Cook at camp before eating, or keep it for later.';
}

const fishSpecies = <String, FishSpecies>{
  'small_fish': FishSpecies(
    'small_fish',
    'Stream Silverfish',
    'Common',
    0,
    25,
    12,
    23,
    .12,
    .38,
  ),
  'redfin_perch': FishSpecies(
    'redfin_perch',
    'Redfin Perch',
    'Uncommon',
    1,
    32,
    19,
    34,
    .35,
    .8,
  ),
  'mud_whisker': FishSpecies(
    'mud_whisker',
    'Mud Whisker',
    'Uncommon',
    2,
    36,
    26,
    46,
    .65,
    1.6,
    minRod: 1,
    poison: 1,
    habitat: 'Muddy pools near mangrove roots.',
  ),
  'spiny_sunlurker': FishSpecies(
    'spiny_sunlurker',
    'Spiny Sunlurker',
    'Uncommon',
    3,
    34,
    21,
    35,
    .4,
    1.1,
    minRod: 1,
    minDay: 3,
    poison: 2,
    requiresKnife: true,
    habitat: 'Shaded pools and slow rocky river bends.',
  ),
  'goldspot_riverfish': FishSpecies(
    'goldspot_riverfish',
    'Goldspot Riverfish',
    'Rare',
    4,
    48,
    35,
    58,
    1.2,
    2.7,
    minRod: 2,
    minDay: 3,
  ),
};

class FishingRod {
  const FishingRod(
    this.id,
    this.name,
    this.tier,
    this.zoneScale,
    this.durability,
  );
  final String id, name;
  final int tier, durability;
  final double zoneScale;
}

const fishingRods = <String, FishingRod>{
  'basic_rod': FishingRod('basic_rod', 'Basic Rod', 0, 1, 12),
  'reinforced_rod': FishingRod('reinforced_rod', 'Reinforced Rod', 1, 1.12, 20),
  'river_rod': FishingRod('river_rod', 'River Rod', 2, 1.22, 30),
};

class FishingBait {
  const FishingBait(
    this.id,
    this.name,
    this.cell,
    this.description,
    this.weights,
  );
  final String id, name, description;
  final int cell;
  final Map<String, int> weights;
}

const fishingBaits = <String, FishingBait>{
  'bait': FishingBait(
    'bait',
    'Worms',
    6,
    'Reliable bait for small and medium fish.',
    {
      'small_fish': 65,
      'redfin_perch': 22,
      'mud_whisker': 8,
      'spiny_sunlurker': 4,
      'goldspot_riverfish': 1,
    },
  ),
  'insect_bait': FishingBait(
    'insect_bait',
    'Insect Bait',
    7,
    'Surface hunters favour insects. Redfin Perch are more likely.',
    {
      'small_fish': 22,
      'redfin_perch': 43,
      'mud_whisker': 10,
      'spiny_sunlurker': 20,
      'goldspot_riverfish': 5,
    },
  ),
  'fruit_bait': FishingBait(
    'fruit_bait',
    'Fruit Bait',
    8,
    'Fruit attracts unusual river fish. A River Rod can land Goldspots.',
    {
      'small_fish': 25,
      'redfin_perch': 12,
      'mud_whisker': 25,
      'spiny_sunlurker': 13,
      'goldspot_riverfish': 25,
    },
  ),
};

class FishCatch {
  const FishCatch({
    required this.speciesId,
    required this.lengthCm,
    required this.weightGrams,
  });
  final String speciesId;
  final int lengthCm, weightGrams;
  FishSpecies get species => fishSpecies[speciesId]!;
  String get weightLabel => '${(weightGrams / 1000).toStringAsFixed(2)} kg';
  String get sizeLabel => weightGrams >= 1200
      ? 'LARGE'
      : weightGrams < 350
      ? 'SMALL'
      : 'MEDIUM';
  Map<String, dynamic> toJson() => {
    'species': speciesId,
    'lengthCm': lengthCm,
    'weightGrams': weightGrams,
  };
  factory FishCatch.fromJson(Map<String, dynamic> j) {
    final id = j['species'] as String;
    if (!fishSpecies.containsKey(id) ||
        (j['lengthCm'] as int) <= 0 ||
        (j['weightGrams'] as int) <= 0) {
      throw const FormatException('Invalid fish catch');
    }
    return FishCatch(
      speciesId: id,
      lengthCm: j['lengthCm'] as int,
      weightGrams: j['weightGrams'] as int,
    );
  }
  static FishCatch draw(
    Random rng, {
    required String bait,
    required String rod,
    required int day,
  }) {
    final weights = fishingBaits[bait]!.weights;
    final pool = fishSpecies.values
        .where((s) => s.minRod <= fishingRods[rod]!.tier && s.minDay <= day)
        .toList();
    var roll = rng.nextInt(pool.fold<int>(0, (sum, s) => sum + weights[s.id]!));
    var species = pool.last;
    for (final s in pool) {
      roll -= weights[s.id]!;
      if (roll < 0) {
        species = s;
        break;
      }
    }
    final size = rng.nextDouble();
    return FishCatch(
      speciesId: species.id,
      lengthCm:
          species.minLength +
          ((species.maxLength - species.minLength) * size).round(),
      weightGrams:
          ((species.minWeight +
                      (species.maxWeight - species.minWeight) * size) *
                  1000)
              .round(),
    );
  }
}

String? preparedFishSource(String id) =>
    id.startsWith('prepared_') && fishSpecies.containsKey(id.substring(9))
    ? id.substring(9)
    : null;
