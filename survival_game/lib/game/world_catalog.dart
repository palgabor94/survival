import 'ecology_catalog.dart';
import 'fishing_catalog.dart';
import 'dart:convert';

import 'run_state.dart';

class WorldLocation {
  const WorldLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.loot,
    required this.timeCost,
    required this.x,
    required this.y,
    this.minDay = 1,
    this.minCampTier = 0,
    this.unlockTool,
    this.comingSoon,
    this.background,
    this.requiresTool,
  });
  final String id, name, description, loot;
  final int timeCost, minDay, minCampTier;
  final double x, y;
  final String? unlockTool;
  final String? background;
  final String? requiresTool;

  /// Shown once the camp requirement is met but the content is not built yet.
  final String? comingSoon;
  bool isUnlocked(RunState state) => lockReason(state) == null;
  String? lockReason(RunState state) {
    if (state.campTier < minCampTier) {
      return 'Requires Camp Tier $minCampTier. Upgrade your camp first.';
    }
    if (comingSoon != null) return comingSoon;
    if (requiresTool != null && !state.tools.contains(requiresTool)) {
      return 'Requires ${itemName(requiresTool!)}. Craft it in the workshop.';
    }
    final toolUnlocks = unlockTool != null && state.tools.contains(unlockTool);
    if (state.day < minDay && !toolUnlocks) {
      return unlockTool == null
          ? 'Discover on day $minDay.'
          : 'Discover on day $minDay or craft a ${itemName(unlockTool!)}.';
    }
    return null;
  }

  factory WorldLocation.fromJson(Map<String, dynamic> j) => WorldLocation(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    loot: j['loot'] as String,
    timeCost: j['timeCost'] as int,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    minDay: j['minDay'] as int? ?? 1,
    minCampTier: j['minCampTier'] as int? ?? 0,
    unlockTool: j['unlockTool'] as String?,
    comingSoon: j['comingSoon'] as String?,
    background: j['background'] as String?,
    requiresTool: j['requiresTool'] as String?,
  );
}

class WorldCatalog {
  WorldCatalog(List<WorldLocation> locations)
    : locations = List.unmodifiable(locations) {
    final ids = <String>{};
    for (final location in locations) {
      if (!ids.add(location.id) ||
          location.timeCost < 0 ||
          location.timeCost > RunState.dayLength ||
          location.x < 0 ||
          location.x > 1 ||
          location.y < 0 ||
          location.y > 1) {
        throw FormatException('Invalid world location: ${location.id}');
      }
    }
  }
  final List<WorldLocation> locations;
  WorldLocation? find(String id) {
    for (final location in locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  factory WorldCatalog.fromJson(String source) => WorldCatalog(
    (jsonDecode(source) as List)
        .map((e) => WorldLocation.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

String itemName(String id) =>
    fishSpecies[id]?.name ??
    fishingRods[id]?.name ??
    fishingBaits[id]?.name ??
    (preparedFishSource(id) == null
        ? null
        : 'Prepared ${fishSpecies[preparedFishSource(id)]!.name}') ??
    jungleFoods[id]?.name ??
    switch (id) {
      'antidote' => 'Antidote',
      'bandage' => 'Bandage',
      'charcoal' => 'Charcoal',
      'leaf_rain_cape' => 'Leaf Rain Cape',
      'small_fish' => 'Small Fish',
      'basic_rod' => 'Basic Rod',
      'bait' => 'Bait',
      'herb' => 'Herb',
      'hardwood' => 'Hardwood',
      'metal_scrap' => 'Metal Scrap',
      'raw_meat' => 'Raw Meat',
      'machete' => 'Machete',
      'emergency_beacon' => 'Emergency Beacon',
      'battery' => 'Battery',
      'wire' => 'Wire',
      'metal_parts' => 'Metal Parts',
      'radio_module' => 'Radio Module',
      'beacon_core' => 'Beacon Core',
      'wood' => 'Wood',
      'fiber' => 'Fiber',
      'stone' => 'Stone',
      _ => id.replaceAll('_', ' '),
    };
