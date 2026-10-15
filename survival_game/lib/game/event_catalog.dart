import 'dart:convert';

import 'run_state.dart';
import 'world_catalog.dart';
import 'gathering_session.dart';

class EventEffect {
  EventEffect({
    Map<SurvivalStat, int> stats = const {},
    Map<String, int> resources = const {},
    Set<String> flags = const {},
    List<SurvivalCondition> conditions = const [],
    this.physicalDamage = false,
    this.dropLoot = false,
    this.endsExpedition = false,
  }) : flags = Set.unmodifiable(flags),
       conditions = List.unmodifiable(conditions),
       stats = Map.unmodifiable(stats),
       resources = Map.unmodifiable(resources);
  final Set<String> flags;
  final List<SurvivalCondition> conditions;
  final bool physicalDamage;
  final Map<SurvivalStat, int> stats;
  final Map<String, int> resources;

  /// Expedition outcomes: everything gathered on this trip is lost, and/or
  /// the survivor flees and the trip is over.
  final bool dropLoot;
  final bool endsExpedition;

  factory EventEffect.fromJson(Map<String, dynamic> json) => EventEffect(
    stats: {
      for (final entry
          in (json['stats'] as Map<String, dynamic>? ?? {}).entries)
        SurvivalStat.values.byName(entry.key): entry.value as int,
    },
    resources: Map<String, int>.from(json['resources'] as Map? ?? {}),
    flags: Set<String>.from(json['flags'] as List? ?? []),
    conditions: [
      for (final c in json['conditions'] as List? ?? [])
        SurvivalCondition.fromJson(Map<String, dynamic>.from(c as Map)),
    ],
    physicalDamage: json['physicalDamage'] as bool? ?? false,
    dropLoot: json['dropLoot'] as bool? ?? false,
    endsExpedition: json['endsExpedition'] as bool? ?? false,
  );

  String get summary => [
    for (final e in stats.entries)
      '${e.value > 0 ? '+' : ''}${e.value} ${e.key.label}',
    for (final e in resources.entries)
      '${e.value > 0 ? '+' : ''}${e.value} ${itemName(e.key).toLowerCase()}',
    if (dropLoot) 'lose your haul',
    if (endsExpedition) 'trip over',
  ].join(' · ');
}

class EventChoice {
  EventChoice({
    required this.id,
    required this.label,
    required this.description,
    required this.effect,
    required this.result,
    Map<String, double> weatherChances = const {},
    Set<String> consumesTools = const {},
    this.riskDomain = 'none',
    this.extraTime = 0,
    this.sheltered = false,
    this.successChance = 1,
    this.failureEffect,
    this.failureResult,
    Map<String, int> requires = const {},
    Set<String> requiresTools = const {},
    Map<SurvivalStat, int> requiresStats = const {},
    Map<SurvivalStat, int> showWhenBelow = const {},
    this.icon,
    this.cardImage,
    this.minigame,
  }) : weatherChances = Map.unmodifiable(weatherChances),
       consumesTools = Set.unmodifiable(consumesTools),
       requires = Map.unmodifiable(requires),
       requiresTools = Set.unmodifiable(requiresTools),
       requiresStats = Map.unmodifiable(requiresStats),
       showWhenBelow = Map.unmodifiable(showWhenBelow);
  final String id;
  final String label;
  final String description;
  final EventEffect effect;
  final String result;
  final Map<String, double> weatherChances;
  final Set<String> consumesTools;
  final String riskDomain;
  final int extraTime;
  final bool sheltered;
  final double successChance;
  final EventEffect? failureEffect;
  final String? failureResult;
  final Map<String, int> requires;

  /// Tools or camp items the survivor must own to pick this choice.
  final Set<String> requiresTools;

  /// Minimum stat values: the card is shown but locked below them.
  final Map<SurvivalStat, int> requiresStats;

  /// The card only appears while every listed stat is at or below its value,
  /// e.g. "treat your wounds" shows up only when hurt.
  final Map<SurvivalStat, int> showWhenBelow;

  /// Icon key for the card, and an optional card illustration asset path.
  final String? icon;
  final String? cardImage;
  final String? minigame;
  bool get isRisky => successChance < 1;

  /// A choice that is always visible and always affordable can serve as the
  /// event's escape hatch.
  bool get isFree =>
      requires.isEmpty &&
      requiresTools.isEmpty &&
      requiresStats.isEmpty &&
      showWhenBelow.isEmpty;

  bool isVisible(RunState state) =>
      showWhenBelow.entries.every((e) => state.value(e.key) <= e.value);

  factory EventChoice.fromJson(Map<String, dynamic> json) => EventChoice(
    id: json['id'] as String,
    label: json['label'] as String,
    description: json['description'] as String,
    effect: EventEffect.fromJson(json['effect'] as Map<String, dynamic>),
    result: json['result'] as String,
    weatherChances: {
      for (final e
          in (json['weatherChances'] as Map<String, dynamic>? ?? {}).entries)
        e.key: (e.value as num).toDouble(),
    },
    consumesTools: Set<String>.from(json['consumesTools'] as List? ?? []),
    riskDomain: json['riskDomain'] as String? ?? 'none',
    extraTime: json['extraTime'] as int? ?? 0,
    sheltered: json['sheltered'] as bool? ?? false,
    successChance: (json['successChance'] as num? ?? 1).toDouble(),
    failureEffect: json['failureEffect'] == null
        ? null
        : EventEffect.fromJson(json['failureEffect'] as Map<String, dynamic>),
    failureResult: json['failureResult'] as String?,
    requires: Map<String, int>.from(json['requires'] as Map? ?? {}),
    requiresTools: Set<String>.from(json['requiresTools'] as List? ?? []),
    requiresStats: _stats(json['requiresStats']),
    showWhenBelow: _stats(json['showWhenBelow']),
    icon: json['icon'] as String?,
    cardImage: json['cardImage'] as String?,
    minigame: json['minigame'] as String?,
  );

  static Map<SurvivalStat, int> _stats(Object? json) => {
    for (final e in (json as Map<String, dynamic>? ?? {}).entries)
      SurvivalStat.values.byName(e.key): e.value as int,
  };
}

class GameEvent {
  GameEvent({
    required this.id,
    required this.trigger,
    required this.title,
    required this.description,
    required this.scene,
    required List<EventChoice> choices,
    this.minDay = 1,
    this.maxWater = 100,
    List<String> locations = const [],
    this.background,
    this.heroImage,
    this.minDepth = 0,
    this.maxDepth = 99,
    this.priority = 0,
    this.missingResource,
  }) : choices = List.unmodifiable(choices),
       locations = List.unmodifiable(locations);
  final String id;
  final String trigger;
  final String title;
  final String description;
  final String scene;
  final List<EventChoice> choices;
  final int minDay;
  final int maxWater;
  final List<String> locations;

  /// Optional scene and illustration assets; missing art falls back to the
  /// location background and the shared icon atlas.
  final String? background;
  final String? heroImage;

  /// Expedition steps this event can appear at (0 is the first stop).
  final int minDepth, maxDepth;
  final int priority;
  final String? missingResource;
  bool eligible(RunState state) =>
      state.day >= minDay &&
      state.value(SurvivalStat.water) <= maxWater &&
      (missingResource == null ||
          (!state.tools.contains('emergency_beacon') &&
              state.resource(missingResource!) == 0));

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    id: json['id'] as String,
    trigger: json['trigger'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    scene: json['scene'] as String,
    minDay: json['minDay'] as int? ?? 1,
    maxWater: json['maxWater'] as int? ?? 100,
    locations: List<String>.from(json['locations'] as List? ?? []),
    background: json['background'] as String?,
    heroImage: json['heroImage'] as String?,
    minDepth: json['minDepth'] as int? ?? 0,
    maxDepth: json['maxDepth'] as int? ?? 99,
    priority: json['priority'] as int? ?? 0,
    missingResource: json['missingResource'] as String?,
    choices: (json['choices'] as List)
        .map((e) => EventChoice.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class EventCatalog {
  /// Compact choices scroll in one row; the boar offers five alternatives.
  static const maxChoices = 5;

  EventCatalog(List<GameEvent> events) : events = List.unmodifiable(events) {
    final ids = <String>{};
    for (final event in events) {
      if (!ids.add(event.id) ||
          event.choices.length < 2 ||
          event.choices.length > maxChoices ||
          event.choices.map((c) => c.id).toSet().length !=
              event.choices.length) {
        throw FormatException('Invalid event or duplicate ID: ${event.id}');
      }
      for (final choice in event.choices) {
        if (choice.minigame != null &&
            choice.minigame != 'ruins_symbols' &&
            GatheringKind.fromId(choice.minigame) == null) {
          throw FormatException('Unknown minigame: ${choice.minigame}');
        }
        if (choice.extraTime < 0 ||
            choice.extraTime > RunState.dayLength ||
            !{
              'physical',
              'mental',
              'environment',
              'none',
            }.contains(choice.riskDomain) ||
            choice.weatherChances.values.any((v) => v < 0 || v > 1) ||
            choice.successChance < 0 ||
            choice.successChance > 1 ||
            (choice.isRisky &&
                (choice.failureEffect == null ||
                    choice.failureResult == null))) {
          throw FormatException(
            'Invalid risk outcome: ${event.id}/${choice.id}',
          );
        }
        for (final effect in [choice.effect, choice.failureEffect]) {
          if (effect == null) continue;
          for (final resource in effect.resources.entries) {
            if (resource.value < 0 &&
                (choice.requires[resource.key] ?? 0) < -resource.value) {
              throw FormatException(
                'Resource cost needs a requirement: ${choice.id}',
              );
            }
          }
        }
      }
      if (!event.choices.any((c) => c.isFree)) {
        throw FormatException('Event needs a free escape choice: ${event.id}');
      }
    }
    for (final trigger in ['forage', 'explore', 'night']) {
      if (!events.any(
        (e) => e.trigger == trigger && e.minDay == 1 && e.maxWater == 100,
      )) {
        throw FormatException('Missing unconditional event for $trigger');
      }
    }
  }
  final List<GameEvent> events;
  factory EventCatalog.fromJson(String source) => EventCatalog(
    (jsonDecode(source) as List)
        .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  List<GameEvent> eligible(String trigger, RunState state) =>
      events.where((e) => e.trigger == trigger && e.eligible(state)).toList();
}
