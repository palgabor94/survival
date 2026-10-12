/// A trip out of camp: how deep the survivor has gone and what they carry.
/// Everything in [loot] is already in the pack, but it is lost if the
/// survivor drops it while fleeing.
class Expedition {
  Expedition(this.locationId, {this.depth = 0, Map<String, int>? loot})
    : loot = {...?loot};

  final String locationId;
  int depth;
  final Map<String, int> loot;

  Map<String, dynamic> toJson() => {
    'locationId': locationId,
    'depth': depth,
    'loot': loot,
  };

  factory Expedition.fromJson(Map<String, dynamic> j) => Expedition(
    j['locationId'] as String,
    depth: j['depth'] as int,
    loot: Map<String, int>.from(j['loot'] as Map),
  );
}
