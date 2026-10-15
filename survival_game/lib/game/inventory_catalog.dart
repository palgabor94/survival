import 'fishing_catalog.dart';
import 'ecology_catalog.dart';

int stackLimit(String id) {
  if ({'wood', 'fiber', 'charcoal'}.contains(id) ||
      fishingBaits.containsKey(id)) {
    return 10;
  }
  if ({'stone', 'hardwood', 'metal_scrap', 'herb'}.contains(id)) return 5;
  if (fishSpecies.containsKey(id) ||
      preparedFishSource(id) != null ||
      jungleFoods.containsKey(id) ||
      {'raw_meat', 'cooked_root', 'bandage', 'antidote'}.contains(id)) {
    return 3;
  }
  return 1;
}

int packSlots(Map<String, int> items) => items.entries.fold(
  0,
  (sum, e) =>
      sum +
      (e.value <= 0
          ? 0
          : (e.value + stackLimit(e.key) - 1) ~/ stackLimit(e.key)),
);
Map<String, int> positiveItems(Map<String, int> items) => {
  for (final e in items.entries)
    if (e.value > 0) e.key: e.value,
};
Map<String, int> mergeItems(Map<String, int> a, Map<String, int> b) =>
    positiveItems({
      for (final id in {...a.keys, ...b.keys}) id: (a[id] ?? 0) + (b[id] ?? 0),
    });

class PackingDraft {
  PackingDraft(this.destination, Map<String, int> items, Set<String> gear)
    : items = Map.unmodifiable(items),
      gear = Set.unmodifiable(gear);
  final String destination;
  final Map<String, int> items;
  final Set<String> gear;
  Map<String, dynamic> toJson() => {
    'destination': destination,
    'items': items,
    'gear': gear.toList(),
  };
  factory PackingDraft.fromJson(Map<String, dynamic> j) => PackingDraft(
    j['destination'] as String,
    Map<String, int>.from(j['items'] as Map),
    Set<String>.from(j['gear'] as List),
  );
}
