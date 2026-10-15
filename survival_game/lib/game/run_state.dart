import 'rescue_progress.dart';

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
  }) : foundComponents = Set.unmodifiable(foundComponents),
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
  static const toolDurability = {'stone_axe': 10, 'stone_spear': 10};
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
  }) : changes = Map.unmodifiable(changes);

  ActionReport({
    required this.title,
    required this.body,
    required RunState before,
    required RunState after,
    this.daySummary,
  }) : changes = Map.unmodifiable({
         for (final stat in SurvivalStat.values)
           if (after.value(stat) != before.value(stat))
             stat.label: after.value(stat) - before.value(stat),
         for (final id in {...before.resources.keys, ...after.resources.keys})
           if (after.resource(id) != before.resource(id))
             id: after.resource(id) - before.resource(id),
       });
  final String title;
  final String body;
  final Map<String, int> changes;
  final DaySummary? daySummary;

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'changes': changes,
    if (daySummary != null) 'daySummary': daySummary!.toJson(),
  };

  factory ActionReport.fromJson(Map<String, dynamic> j) => ActionReport.saved(
    title: j['title'] as String,
    body: j['body'] as String,
    changes: Map<String, int>.from(j['changes'] as Map),
    daySummary: j['daySummary'] == null
        ? null
        : DaySummary.fromJson(j['daySummary'] as Map<String, dynamic>),
  );
}
