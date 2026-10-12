import 'dart:convert';

import 'run_state.dart';

enum RecipeKind { tool, campItem, campTier }

/// Passive bonuses granted while an item is owned or a camp tier is reached.
enum CampBonus {
  /// Extra health from a night's sleep when fed and hydrated.
  sleepHealth,

  /// Extra sanity after every sleep.
  sleepSanity,

  /// Water collected at every dawn.
  dawnWater,

  /// Additional dawn water on rainy days.
  rainWater,

  /// Extra water whenever an event choice collects water.
  waterGain,

  /// Extra food from each fish eaten.
  fishFood,
}

/// One data model for tools, camp items and camp upgrades. Everything the
/// survivor builds is a recipe: it costs resources and daylight, may need a
/// camp tier or other items first, and is owned once built.
class Recipe {
  Recipe({
    required this.id,
    required this.name,
    required this.kind,
    required this.description,
    required this.effect,
    required Map<String, int> costs,
    required this.timeCost,
    this.minCampTier = 0,
    this.tier,
    Set<String> requiresItems = const {},
    Map<CampBonus, int> bonuses = const {},
  }) : costs = Map.unmodifiable(costs),
       requiresItems = Set.unmodifiable(requiresItems),
       bonuses = Map.unmodifiable(bonuses);

  final String id, name, description, effect;
  final RecipeKind kind;
  final Map<String, int> costs;
  final int timeCost;
  final int minCampTier;

  /// The camp tier this upgrade builds (camp tier recipes only).
  final int? tier;
  final Set<String> requiresItems;
  final Map<CampBonus, int> bonuses;

  bool isOwnedBy(RunState state) => kind == RecipeKind.campTier
      ? state.campTier >= tier!
      : state.tools.contains(id);

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
    id: j['id'] as String,
    name: j['name'] as String,
    kind: switch (j['kind']) {
      'tool' => RecipeKind.tool,
      'camp_item' => RecipeKind.campItem,
      'camp_tier' => RecipeKind.campTier,
      final other => throw FormatException('Unknown recipe kind: $other'),
    },
    description: j['description'] as String,
    effect: j['effect'] as String,
    costs: Map<String, int>.from(j['costs'] as Map),
    timeCost: j['timeCost'] as int,
    minCampTier: j['minCampTier'] as int? ?? 0,
    tier: j['tier'] as int?,
    requiresItems: Set<String>.from(j['requiresItems'] as List? ?? []),
    bonuses: {
      for (final e in (j['bonuses'] as Map<String, dynamic>? ?? {}).entries)
        CampBonus.values.byName(e.key): e.value as int,
    },
  );
}

class RecipeCatalog {
  RecipeCatalog(List<Recipe> recipes) : recipes = List.unmodifiable(recipes) {
    final ids = <String>{};
    for (final recipe in recipes) {
      if (!ids.add(recipe.id) ||
          recipe.timeCost < 0 ||
          recipe.timeCost > RunState.dayLength ||
          recipe.costs.values.any((v) => v <= 0) ||
          (recipe.kind == RecipeKind.campTier) != (recipe.tier != null)) {
        throw FormatException('Invalid recipe: ${recipe.id}');
      }
    }
    for (final recipe in recipes) {
      for (final item in recipe.requiresItems) {
        if (!ids.contains(item)) {
          throw FormatException('Unknown requirement $item in ${recipe.id}');
        }
      }
    }
    final tiers = campTiers.map((r) => r.tier).toList();
    for (var i = 0; i < tiers.length; i++) {
      if (tiers[i] != i + 1) {
        throw const FormatException('Camp tiers must be 1, 2, 3… in order');
      }
    }
  }

  final List<Recipe> recipes;

  Iterable<Recipe> get crafts =>
      recipes.where((r) => r.kind != RecipeKind.campTier);
  List<Recipe> get campTiers =>
      recipes.where((r) => r.kind == RecipeKind.campTier).toList()
        ..sort((a, b) => a.tier!.compareTo(b.tier!));

  Recipe? find(String id) {
    for (final recipe in recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  /// The next camp upgrade, or null once the camp is fully built.
  Recipe? nextTier(RunState state) {
    for (final tier in campTiers) {
      if (tier.tier! > state.campTier) return tier;
    }
    return null;
  }

  /// Sum of a bonus over owned items and every reached camp tier.
  int bonus(RunState state, CampBonus bonus) => recipes
      .where((r) => r.isOwnedBy(state))
      .fold(0, (sum, r) => sum + (r.bonuses[bonus] ?? 0));

  factory RecipeCatalog.fromJson(String source) => RecipeCatalog(
    (jsonDecode(source) as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Name of camp tier 0 and of every upgrade, for HUD and outcome text.
String campTierName(RecipeCatalog recipes, int tier) {
  if (tier == 0) return 'Crash Shelter';
  for (final recipe in recipes.campTiers) {
    if (recipe.tier == tier) return recipe.name;
  }
  return 'Camp Tier $tier';
}
