import 'rescue_progress.dart';
import 'survival_condition.dart';
import 'fishing_catalog.dart';
export 'survival_condition.dart';

enum RunPhase { day, night, gameOver, rescued }

enum CampAction {
  forage('Forage', 1),
  explore('Explore', 2),
  rest('Rest', 1);

  const CampAction(this.label, this.cost);
  final String label;
  final int cost;
}

enum SurvivalStat {
  health('Health'),
  water('Water'),
  food('Food'),
  sanity('Sanity');

  const SurvivalStat(this.label);
  final String label;
}

/// A snapshot cannot be mutated by the UI or by content definitions.
class RunState {
  RunState({
    this.equippedRod = 'basic_rod',
    Set<String> knownFish = const {},
    this.exposure = 0,
    this.strain = 0,
    List<SurvivalCondition> conditions = const [],
    Set<String> worldFlags = const {},
    Set<String> knownSpecies = const {'ember_berries'},
    this.day = 1,
    this.timeLeft = dayLength,
    this.phase = RunPhase.day,
    this.weather = 'Sunny',
    this.locationId = 'camp',
    this.campTier = 0,
    this.rescueStage = RescueStage.searching,
    this.rescueStep = 0,
    this.signalDay,
    Set<String> foundComponents = const {},
    Set<String> tools = const {},
    Map<String, int> durability = const {},
    Map<SurvivalStat, int>? stats,
    Map<String, int>? resources,
  }) : knownFish = Set.unmodifiable(knownFish),
       conditions = List.unmodifiable(conditions),
       knownSpecies = Set.unmodifiable(knownSpecies),
       worldFlags = Set.unmodifiable(worldFlags),
       foundComponents = Set.unmodifiable(foundComponents),
       tools = Set.unmodifiable(tools),
       durability = Map.unmodifiable(durability),
       stats = Map.unmodifiable(
         stats ??
             {
               SurvivalStat.health: 100,
               SurvivalStat.water: 80,
               SurvivalStat.food: 75,
               SurvivalStat.sanity: 80,
             },
       ),
       resources = Map.unmodifiable(
         resources ?? {'wood': 2, 'stone': 0, 'fiber': 0},
       );

  final String equippedRod;
  final Set<String> knownFish;
  final List<SurvivalCondition> conditions;
  final Set<String> worldFlags;
  final Set<String> knownSpecies;
  final int exposure, strain;
  SurvivalCondition? condition(ConditionKind kind) {
    for (final c in conditions) {
      if (c.kind == kind) return c;
    }
    return null;
  }

  bool hasCondition(ConditionKind kind) => condition(kind) != null;
  double get physicalPenalty =>
      ((condition(ConditionKind.poisoned)?.severity ?? 0) == 2
          ? .15
          : hasCondition(ConditionKind.poisoned)
          ? .1
          : 0) +
      (hasCondition(ConditionKind.injured) ? .1 : 0) +
      (hasCondition(ConditionKind.exhausted) ? .1 : 0);
  double get timingScale =>
      ((hasCondition(ConditionKind.injured) ? .9 : 1.0) *
              (hasCondition(ConditionKind.exhausted) ? .85 : 1.0))
          .clamp(.75, 1);
  static const dayLength = 6;
  final int day;
  final int timeLeft;
  final RunPhase phase;
  final String weather;
  final String locationId;
  final int campTier;
  final RescueStage rescueStage;
  final int rescueStep;
  final int? signalDay;
  final Set<String> foundComponents;
  bool get rescued => phase == RunPhase.rescued;

  /// Every crafted tool and camp item the survivor owns.
  final Set<String> tools;
  static const toolDurability = {
    'stone_axe': 10,
    'stone_spear': 10,
    'basic_rod': 12,
    'reinforced_rod': 20,
    'river_rod': 30,
  };
  final Map<String, int> durability;
  int toolCondition(String id) =>
      tools.contains(id) ? (durability[id] ?? toolDurability[id] ?? 0) : 0;
  bool toolUsable(String id) =>
      tools.contains(id) &&
      (!toolDurability.containsKey(id) || toolCondition(id) > 0);
  final Map<SurvivalStat, int> stats;
  final Map<String, int> resources;
  int value(SurvivalStat stat) => stats[stat] ?? 0;
  int resource(String id) => resources[id] ?? 0;
  bool get isAlive => value(SurvivalStat.health) > 0;
  String get timeLabel => phase == RunPhase.night
      ? 'Nightfall'
      : timeLeft > 4
      ? 'Morning'
      : timeLeft > 2
      ? 'Afternoon'
      : 'Dusk';

  RunState copyWith({
    String? equippedRod,
    Set<String>? knownFish,
    List<SurvivalCondition>? conditions,
    Set<String>? worldFlags,
    Set<String>? knownSpecies,
    int? exposure,
    int? strain,
    int? day,
    int? timeLeft,
    RunPhase? phase,
    String? weather,
    String? locationId,
    int? campTier,
    RescueStage? rescueStage,
    int? rescueStep,
    int? signalDay,
    Set<String>? foundComponents,
    Set<String>? tools,
    Map<String, int>? durability,
    Map<SurvivalStat, int>? stats,
    Map<String, int>? resources,
  }) => RunState(
    equippedRod: equippedRod ?? this.equippedRod,
    knownFish: knownFish ?? this.knownFish,
    conditions: conditions ?? this.conditions,
    worldFlags: worldFlags ?? this.worldFlags,
    knownSpecies: knownSpecies ?? this.knownSpecies,
    exposure: exposure ?? this.exposure,
    strain: strain ?? this.strain,
    day: day ?? this.day,
    timeLeft: timeLeft ?? this.timeLeft,
    phase: phase ?? this.phase,
    weather: weather ?? this.weather,
    locationId: locationId ?? this.locationId,
    campTier: campTier ?? this.campTier,
    rescueStage: rescueStage ?? this.rescueStage,
    rescueStep: rescueStep ?? this.rescueStep,
    signalDay: signalDay ?? this.signalDay,
    foundComponents: foundComponents ?? this.foundComponents,
    tools: tools ?? this.tools,
    durability: durability ?? this.durability,
    stats: stats ?? this.stats,
    resources: resources ?? this.resources,
  );

  Map<String, dynamic> toJson() => {
    'equippedRod': equippedRod,
    'knownFish': knownFish.toList()..sort(),
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'worldFlags': worldFlags.toList()..sort(),
    'knownSpecies': knownSpecies.toList()..sort(),
    'exposure': exposure,
    'strain': strain,
    'day': day,
    'timeLeft': timeLeft,
    'phase': phase.name,
    'weather': weather,
    'locationId': locationId,
    'campTier': campTier,
    'rescueStage': rescueStage.name,
    'rescueStep': rescueStep,
    'signalDay': signalDay,
    'foundComponents': foundComponents.toList()..sort(),
    'tools': tools.toList()..sort(),
    'durability': durability,
    'stats': {for (final e in stats.entries) e.key.name: e.value},
    'resources': resources,
  };

  factory RunState.fromJson(Map<String, dynamic> j) => RunState(
    equippedRod: j['equippedRod'] as String? ?? 'basic_rod',
    knownFish: Set<String>.from(j['knownFish'] as List? ?? []),
    conditions: [
      for (final c in j['conditions'] as List? ?? [])
        SurvivalCondition.fromJson(Map<String, dynamic>.from(c as Map)),
    ],
    worldFlags: Set<String>.from(j['worldFlags'] as List? ?? []),
    knownSpecies: Set<String>.from(
      j['knownSpecies'] as List? ?? ['ember_berries'],
    ),
    exposure: (j['exposure'] as int? ?? 0).clamp(0, 6),
    strain: (j['strain'] as int? ?? 0).clamp(0, 6),
    day: j['day'] as int,
    timeLeft: (j['timeLeft'] as int).clamp(0, dayLength),
    phase: RunPhase.values.byName(j['phase'] as String),
    weather: j['weather'] as String,
    locationId: j['locationId'] as String,
    campTier: j['campTier'] as int? ?? 0,
    rescueStage: RescueStage.values.byName(
      j['rescueStage'] as String? ?? 'searching',
    ),
    rescueStep: (j['rescueStep'] as int? ?? 0).clamp(0, rescueEventIds.length),
    signalDay: j['signalDay'] as int?,
    foundComponents: Set<String>.from(j['foundComponents'] as List? ?? []),
    tools: Set<String>.from(j['tools'] as List),
    durability: {
      for (final e in Map<String, int>.from(
        j['durability'] as Map? ?? {},
      ).entries)
        if (toolDurability.containsKey(e.key))
          e.key: e.value.clamp(0, toolDurability[e.key]!),
    },
    stats: {
      for (final stat in SurvivalStat.values)
        stat: ((j['stats'] as Map)[stat.name] as int).clamp(0, 100),
    },
    resources: Map<String, int>.from(j['resources'] as Map),
  );
}

class DaySummary {
  DaySummary({required this.day, required List<String> highlights})
    : highlights = List.unmodifiable(highlights);
  final int day;
  final List<String> highlights;

  Map<String, dynamic> toJson() => {'day': day, 'highlights': highlights};
  factory DaySummary.fromJson(Map<String, dynamic> json) => DaySummary(
    day: json['day'] as int,
    highlights: List<String>.from(json['highlights'] as List),
  );
}

class ActionReport {
  ActionReport.saved({
    required this.title,
    required this.body,
    required Map<String, int> changes,
    this.daySummary,
    this.catchRecord,
    this.conditionChanges = const [],
  }) : changes = Map.unmodifiable(changes);

  ActionReport({
    required this.title,
    required this.body,
    this.catchRecord,
    required RunState before,
    required RunState after,
    this.daySummary,
  }) : conditionChanges = List.unmodifiable([
         for (final c in after.conditions)
           if (before.condition(c.kind) == null)
             '${c.label} acquired · ${c.remaining} time'
           else if (before.condition(c.kind)!.remaining != c.remaining ||
               before.condition(c.kind)!.severity != c.severity)
             '${c.label} · ${c.remaining} time remaining',
         for (final c in before.conditions)
           if (!after.hasCondition(c.kind)) '${c.label} cleared',
       ]),
       changes = Map.unmodifiable({
         for (final stat in SurvivalStat.values)
           if (after.value(stat) != before.value(stat))
             stat.label: after.value(stat) - before.value(stat),
         for (final id in {...before.resources.keys, ...after.resources.keys})
           if (after.resource(id) != before.resource(id))
             id: after.resource(id) - before.resource(id),
       });
  final FishCatch? catchRecord;
  final String title;
  final String body;
  final Map<String, int> changes;
  final DaySummary? daySummary;
  final List<String> conditionChanges;

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'changes': changes,
    'conditionChanges': conditionChanges,
    if (catchRecord != null) 'catchRecord': catchRecord!.toJson(),
    if (daySummary != null) 'daySummary': daySummary!.toJson(),
  };

  factory ActionReport.fromJson(Map<String, dynamic> j) => ActionReport.saved(
    title: j['title'] as String,
    body: j['body'] as String,
    changes: Map<String, int>.from(j['changes'] as Map),
    catchRecord: j['catchRecord'] == null
        ? null
        : FishCatch.fromJson(
            Map<String, dynamic>.from(j['catchRecord'] as Map),
          ),
    conditionChanges: List<String>.from(j['conditionChanges'] as List? ?? []),
    daySummary: j['daySummary'] == null
        ? null
        : DaySummary.fromJson(j['daySummary'] as Map<String, dynamic>),
  );
}
