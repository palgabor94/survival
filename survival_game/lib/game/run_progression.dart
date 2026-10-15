import 'dart:math';

import 'run_state.dart';

const rankNames = [
  'Castaway',
  'Pathfinder',
  'Forager',
  'Survivor',
  'Tracker',
  'Ranger',
  'Trailmaster',
  'Jungle Warden',
  'Canopy Veteran',
  'Lost Canopy Legend',
];
int rankThreshold(int rank) => 50 * (rank - 1) * (rank + 2);
int rankFor(int xp) =>
    List.generate(10, (i) => i + 1).lastWhere((r) => xp >= rankThreshold(r));

class StartingOption {
  const StartingOption(
    this.id,
    this.name,
    this.art,
    this.rank,
    this.items,
    this.description, {
    this.food = 0,
  });
  final String id, name, art, description;
  final int rank, food;
  final Map<String, int> items;
}

const startingOptions = [
  StartingOption(
    'none',
    'No Perk',
    'inventory',
    1,
    {},
    'Standard supplies. No trade.',
  ),
  StartingOption(
    'scavenger',
    'Scavenger Kit',
    'stone',
    3,
    {'wood': -2, 'stone': 2},
    'Bring stone instead of firewood. Gather wood before recipes that need it.',
  ),
  StartingOption(
    'angler',
    'Angler Supplies',
    'bait',
    5,
    {'wood': -1, 'bait': 3},
    'Carry extra worms. You still need to craft a fishing rod.',
  ),
  StartingOption(
    'medic',
    'Field Medic',
    'bandage',
    7,
    {'wood': -1, 'bandage': 1},
    'Start with a bandage, less wood and less food.',
    food: -8,
  ),
];
StartingOption optionById(String id) => startingOptions.firstWhere(
  (p) => p.id == id,
  orElse: () => startingOptions.first,
);

class JourneyMilestone {
  const JourneyMilestone(this.day, this.location, this.title, this.art);
  final int day;
  final String location, title, art;
  Map<String, dynamic> toJson() => {
    'day': day,
    'location': location,
    'title': title,
    'art': art,
  };
  factory JourneyMilestone.fromJson(Map<String, dynamic> j) => JourneyMilestone(
    j['day'] as int,
    j['location'] as String,
    j['title'] as String,
    j['art'] as String,
  );
}

/// Structured transaction counters; never reconstructed from journal prose.
class RunMetrics {
  RunMetrics({
    String? id,
    this.partialSince,
    this.legacyEnded = false,
    this.option = 'none',
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}-${_ids++}',
       startedAt = DateTime.now().toUtc().toIso8601String();
  static int _ids = 0;
  final String id;
  String startedAt;
  final int? partialSince;
  final bool legacyEnded;
  final String option;
  int nights = 0,
      fishCaught = 0,
      fishKept = 0,
      crafted = 0,
      encounters = 0,
      campTier = 0,
      stormSteps = 0;
  String? fatalCause, fatalLocation;
  List<String> contributing = [];
  final locations = <String>{},
      fishSpecies = <String>{},
      recipes = <String>{},
      encounterTypes = <String>{},
      components = <String>{};
  final milestones = <JourneyMilestone>[];
  void note(int day, String location, String title, String art) {
    milestones.add(JourneyMilestone(day, location, title, art));
    if (milestones.length > 12) milestones.removeAt(0);
  }

  Map<String, int> xpBreakdown(String outcome) => {
    'Nights survived': min(nights, 15) * 8,
    'Unique locations': min(locations.length, 6) * 15,
    'Fish species caught': min(fishSpecies.length, 5) * 10,
    'Unique item recipes': min(recipes.length, 10) * 5,
    'Camp tiers': min(campTier, 3) * 20,
    'Encounter types': min(encounterTypes.length, 6) * 15,
    'Components brought home': min(components.length, 5) * 25,
    'Final storm steps': min(stormSteps, 3) * 25,
    'Rescued': outcome == 'rescued' ? 100 : 0,
  };
  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt,
    'rulesVersion': 1,
    'partialSince': partialSince,
    'legacyEnded': legacyEnded,
    'option': option,
    'nights': nights,
    'fishCaught': fishCaught,
    'fishKept': fishKept,
    'crafted': crafted,
    'encounters': encounters,
    'campTier': campTier,
    'stormSteps': stormSteps,
    'fatalCause': fatalCause,
    'fatalLocation': fatalLocation,
    'contributing': contributing,
    'locations': locations.toList(),
    'fishSpecies': fishSpecies.toList(),
    'recipes': recipes.toList(),
    'encounterTypes': encounterTypes.toList(),
    'components': components.toList(),
    'milestones': milestones.map((e) => e.toJson()).toList(),
  };
  factory RunMetrics.fromJson(Map<String, dynamic> j) {
    final m = RunMetrics(
      id: j['id'] as String,
      partialSince: j['partialSince'] as int?,
      legacyEnded: j['legacyEnded'] as bool? ?? false,
      option: j['option'] as String? ?? 'none',
    );
    m.startedAt = j['startedAt'] as String;
    m.nights = j['nights'] as int;
    m.fishCaught = j['fishCaught'] as int;
    m.fishKept = j['fishKept'] as int;
    m.crafted = j['crafted'] as int;
    m.encounters = j['encounters'] as int;
    m.campTier = j['campTier'] as int;
    m.stormSteps = j['stormSteps'] as int;
    m.fatalCause = j['fatalCause'] as String?;
    m.fatalLocation = j['fatalLocation'] as String?;
    m.contributing = List<String>.from(j['contributing'] as List? ?? []);
    for (final pair in [
      ('locations', m.locations),
      ('fishSpecies', m.fishSpecies),
      ('recipes', m.recipes),
      ('encounterTypes', m.encounterTypes),
      ('components', m.components),
    ]) {
      pair.$2.addAll(List<String>.from(j[pair.$1] as List));
    }
    m.milestones.addAll(
      (j['milestones'] as List).map(
        (e) => JourneyMilestone.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
    );
    if ([
      m.nights,
      m.fishCaught,
      m.fishKept,
      m.crafted,
      m.encounters,
      m.campTier,
      m.stormSteps,
    ].any((n) => n < 0)) {
      throw const FormatException('Negative journey counters');
    }
    return m;
  }
}

class RunSummary {
  RunSummary({
    required RunMetrics metrics,
    required this.outcome,
    required this.day,
    required this.location,
    required Map<SurvivalStat, int> stats,
    required this.xpBefore,
    String? endedAt,
    Map<String, int>? xp,
  }) : stats = Map.unmodifiable(stats),
       _metrics = RunMetrics.fromJson(metrics.toJson()).toJson(),
       endedAt = endedAt ?? DateTime.now().toUtc().toIso8601String(),
       xp = Map.unmodifiable(
         xp ??
             (metrics.legacyEnded
                 ? <String, int>{}
                 : metrics.xpBreakdown(outcome)),
       );
  final Map<String, dynamic> _metrics;
  RunMetrics get metrics => RunMetrics.fromJson(_metrics);
  String get id => _metrics['id'] as String;
  final String outcome, location, endedAt;
  final int day, xpBefore;
  final Map<String, int> xp;
  final Map<SurvivalStat, int> stats;
  int get earned => xp.values.fold(0, (a, b) => a + b);
  int get xpAfter => xpBefore + earned;
  Map<String, dynamic> toJson() => {
    'metrics': metrics.toJson(),
    'outcome': outcome,
    'day': day,
    'location': location,
    'endedAt': endedAt,
    'xpBefore': xpBefore,
    'xp': xp,
    'stats': {for (final e in stats.entries) e.key.name: e.value},
  };
  factory RunSummary.fromJson(Map<String, dynamic> j) => RunSummary(
    metrics: RunMetrics.fromJson(
      Map<String, dynamic>.from(j['metrics'] as Map),
    ),
    outcome: j['outcome'] as String,
    day: j['day'] as int,
    location: j['location'] as String,
    endedAt: j['endedAt'] as String,
    xpBefore: j['xpBefore'] as int,
    xp: Map<String, int>.from(j['xp'] as Map),
    stats: {
      for (final e in (j['stats'] as Map).entries)
        SurvivalStat.values.byName(e.key as String): e.value as int,
    },
  );
}

class PlayerProfile {
  PlayerProfile();
  int xp = 0,
      journeys = 0,
      rescues = 0,
      lost = 0,
      abandoned = 0,
      bestNights = 0,
      fishCaught = 0,
      crafted = 0;
  int? fastestRescue;
  String nextOption = 'none';
  String? lastRecordedId;
  final archive = <RunSummary>[];
  final locations = <String>{}, fishSpecies = <String>{};
  int get rank => rankFor(xp);
  bool canSelect(String id) =>
      startingOptions.any((p) => p.id == id && p.rank <= rank);
  bool record(RunSummary summary) {
    if (lastRecordedId == summary.id ||
        archive.any((s) => s.id == summary.id)) {
      return false;
    }
    final m = summary.metrics;
    lastRecordedId = summary.id;
    xp += summary.earned;
    journeys++;
    if (summary.outcome == 'rescued') {
      rescues++;
      fastestRescue = fastestRescue == null
          ? summary.day
          : min(fastestRescue!, summary.day);
    } else if (summary.outcome == 'lost') {
      lost++;
    } else {
      abandoned++;
    }
    bestNights = max(bestNights, m.nights);
    fishCaught += m.fishCaught;
    crafted += m.crafted;
    locations.addAll(m.locations);
    fishSpecies.addAll(m.fishSpecies);
    archive.insert(0, summary);
    if (archive.length > 20) archive.removeLast();
    return true;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'xp': xp,
    'journeys': journeys,
    'rescues': rescues,
    'lost': lost,
    'abandoned': abandoned,
    'bestNights': bestNights,
    'fishCaught': fishCaught,
    'crafted': crafted,
    'fastestRescue': fastestRescue,
    'nextOption': nextOption,
    'lastRecordedId': lastRecordedId,
    'locations': locations.toList(),
    'fishSpecies': fishSpecies.toList(),
    'archive': archive.map((e) => e.toJson()).toList(),
  };
  factory PlayerProfile.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Unknown profile version');
    }
    final p = PlayerProfile();
    p.xp = j['xp'] as int;
    p.journeys = j['journeys'] as int;
    p.rescues = j['rescues'] as int;
    p.lost = j['lost'] as int;
    p.abandoned = j['abandoned'] as int;
    p.bestNights = j['bestNights'] as int;
    p.fishCaught = j['fishCaught'] as int;
    p.crafted = j['crafted'] as int;
    p.fastestRescue = j['fastestRescue'] as int?;
    p.nextOption = j['nextOption'] as String;
    p.lastRecordedId = j['lastRecordedId'] as String?;
    p.locations.addAll(List<String>.from(j['locations'] as List));
    p.fishSpecies.addAll(List<String>.from(j['fishSpecies'] as List));
    p.archive.addAll(
      (j['archive'] as List).map(
        (e) => RunSummary.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
    );
    if (p.xp < 0 || p.archive.length > 20 || !p.canSelect(p.nextOption)) {
      throw const FormatException('Invalid profile');
    }
    return p;
  }
}
