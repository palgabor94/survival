import 'dart:math';

import 'crafting.dart';
import 'event_catalog.dart';
import 'expedition.dart';
import 'run_state.dart';
import 'world_catalog.dart';
import 'fishing_session.dart';

/// Synchronous transactions: a decision can only resolve once, and no time
/// passes while a player is reading an event or its outcome.
class GameEngine {
  GameEngine(
    this.catalog, {
    Random? random,
    RunState? initialState,
    WorldCatalog? world,
    RecipeCatalog? recipes,
  }) : world = world ?? WorldCatalog([]),
       recipes = recipes ?? RecipeCatalog([]),
       _random = random ?? Random(),
       _state = initialState ?? RunState();
  final EventCatalog catalog;
  final WorldCatalog world;
  final RecipeCatalog recipes;

  /// Called after every completed transaction, e.g. to autosave the run.
  void Function()? onChanged;
  FishingSession? _fishing;
  FishingSession? get fishing => _fishing;
  RunState? _fishingBefore;
  bool _castSpent = false;
  final Random _random;
  RunState _state;
  RunState get state => _state;
  GameEvent? _pendingEvent;
  GameEvent? get pendingEvent => _pendingEvent;
  CampAction? _pendingAction;
  CampAction? get pendingAction => _pendingAction;
  ActionReport? _report;
  ActionReport? get report => _report;
  final List<String> _journal = [
    'Day 1 · You found a clearing. Make it through the night.',
  ];
  List<String> get journal => List.unmodifiable(_journal);
  bool _nightResolved = false;
  final Map<String, String> _lastEvent = {};

  Expedition? _expedition;

  /// The trip in progress, with what is being carried home.
  Expedition? get expedition => _expedition;
  bool _decisionPending = false;

  /// True between two steps of an expedition: return or go deeper.
  bool get awaitingExpeditionDecision => _decisionPending;
  bool _followUp = false;
  int _pendingCost = 0;

  /// Daylight the pending event will spend once it is resolved.
  int get pendingCost => _pendingCost;
  bool get isBusy =>
      _pendingEvent != null ||
      _report != null ||
      _fishing != null ||
      _decisionPending;
  bool get canSleep =>
      state.phase == RunPhase.night && !isBusy && _nightResolved;

  bool canAct(CampAction action) =>
      state.isAlive &&
      state.phase == RunPhase.day &&
      !isBusy &&
      state.timeLeft >= action.cost;

  bool startAction(CampAction action) {
    if (!canAct(action)) return false;
    if (action == CampAction.rest) {
      final before = state;
      _spendTime(action.cost);
      // Rest cannot revive a survivor lost to dehydration or starvation.
      if (state.isAlive) {
        _apply(
          EventEffect(stats: {SurvivalStat.health: 8, SurvivalStat.sanity: 12}),
        );
      }
      _finish(
        'A moment of quiet',
        'You rest beside the fire. The jungle can wait.',
        before,
      );
    } else {
      _pendingAction = action;
      _pendingCost = action.cost;
      _pendingEvent = _pick(action.name);
      _changed();
    }
    return true;
  }

  String? travelBlockReason(String id) {
    final location = world.find(id);
    if (location == null) return 'Unknown destination.';
    if (id == 'camp') return null;
    if (!state.isAlive || isBusy || state.locationId != 'camp') {
      return 'Finish your current activity first.';
    }
    if (state.phase != RunPhase.day) return 'Travel resumes at dawn.';
    final lock = location.lockReason(state);
    if (lock != null) return lock;
    if (state.timeLeft < location.timeCost) {
      return 'Need ${location.timeCost} daylight. Rest until tomorrow.';
    }
    if (id == 'fishing_pond') {
      if (!state.tools.contains('basic_rod')) {
        return 'Craft a Basic Rod in the workshop.';
      }
      if (state.resource('bait') < 1) {
        return 'Collect bait at the Riverbank first.';
      }
    }
    return null;
  }

  bool travelTo(String id) {
    if (id == 'camp' || travelBlockReason(id) != null) return false;
    final location = world.find(id)!;
    if (id != 'fishing_pond') {
      if (_expeditionPool(id, 0).isEmpty) return false;
      _state = state.copyWith(locationId: id);
      _expedition = Expedition(id);
      _pendingAction = CampAction.explore;
      _pendingCost = location.timeCost;
      _pendingEvent = _pick('explore', locationId: id);
      _changed();
      return true;
    }
    if (id == 'fishing_pond') {
      final before = state;
      _state = state.copyWith(locationId: id);
      _spendTime(location.timeCost);
      if (!state.isAlive) {
        _finish(
          'The long walk',
          'Your supplies ran out on the trail to the pond.',
          before,
        );
      } else {
        _fishingBefore = before;
        _castSpent = false;
        _fishing = FishingSession(random: _random);
        _changed();
      }
      return true;
    }
    return false;
  }

  bool castLine() {
    final session = _fishing;
    if (session == null ||
        session.stage != FishingStage.ready ||
        _castSpent ||
        state.resource('bait') < 1) {
      return false;
    }
    if (!session.cast()) return false;
    _apply(EventEffect(resources: {'bait': -1}));
    _castSpent = true;
    _changed();
    return true;
  }

  bool finishFishing({bool abandon = false}) {
    final session = _fishing;
    if (session == null || _fishingBefore == null) return false;
    if (abandon) session.abandon();
    if (!session.complete) return false;
    final before = _fishingBefore!;
    final caught = session.quality != CatchQuality.missed && _castSpent;
    final count = caught
        ? (session.quality == CatchQuality.perfect ? 2 : 1)
        : 0;
    if (caught) _apply(EventEffect(resources: {'small_fish': count}));
    _state = state.copyWith(locationId: 'camp');
    _fishing = null;
    _fishingBefore = null;
    final baitSpent = _castSpent;
    _castSpent = false;
    _finish(
      caught
          ? (count == 2 ? 'A perfect catch' : 'Fresh from the pond')
          : 'Back from the pond',
      caught
          ? 'You bring home $count small fish. Cook and eat your catch from the inventory.'
          : baitSpent
          ? 'The fish slipped away. Your bait is gone, but you made it home.'
          : 'You return without casting. The journey still used daylight and supplies.',
      before,
    );
    return true;
  }

  String? craftBlockReason(String id) {
    final recipe = recipes.find(id);
    if (recipe == null) return 'Unknown recipe';
    if (recipe.isOwnedBy(state)) {
      return recipe.kind == RecipeKind.campTier ? 'Built' : 'Already crafted';
    }
    if (!state.isAlive || isBusy || state.locationId != 'camp') {
      return 'Return to camp first';
    }
    if (state.phase != RunPhase.day) return 'Build in daylight';
    if (recipe.kind == RecipeKind.campTier &&
        recipe.tier != state.campTier + 1) {
      return 'Build ${campTierName(recipes, recipe.tier! - 1)} first';
    }
    if (state.campTier < recipe.minCampTier) {
      return 'Needs ${campTierName(recipes, recipe.minCampTier)}';
    }
    for (final item in recipe.requiresItems) {
      if (!state.tools.contains(item)) {
        return 'Needs ${recipes.find(item)?.name ?? itemName(item)}';
      }
    }
    final missing = [
      for (final e in recipe.costs.entries)
        if (state.resource(e.key) < e.value)
          '${e.value - state.resource(e.key)} ${itemName(e.key).toLowerCase()}',
    ];
    if (missing.isNotEmpty) return 'Need ${missing.join(', ')} more';
    if (state.timeLeft < recipe.timeCost) {
      return 'Need ${recipe.timeCost} daylight';
    }
    return null;
  }

  bool craft(String id) {
    if (craftBlockReason(id) != null) return false;
    final recipe = recipes.find(id)!;
    final before = state;
    _apply(
      EventEffect(
        resources: {for (final e in recipe.costs.entries) e.key: -e.value},
      ),
    );
    _spendTime(recipe.timeCost);
    final upgrade = recipe.kind == RecipeKind.campTier;
    if (state.isAlive) {
      _state = upgrade
          ? state.copyWith(campTier: recipe.tier)
          : state.copyWith(tools: {...state.tools, recipe.id});
    }
    _finish(
      !state.isAlive
          ? 'An unfinished ${recipe.name}'
          : upgrade
          ? 'Camp upgraded: ${recipe.name}'
          : 'Crafted: ${recipe.name}',
      state.isAlive
          ? '${recipe.description} ${recipe.effect}'
          : 'Your supplies ran out before you could finish the ${recipe.name}.',
      before,
    );
    return true;
  }

  /// Items eaten or used from the inventory without spending daylight.
  static const consumables = {'small_fish', 'raw_meat', 'herb'};

  EventEffect consumeEffect(String id) => switch (id) {
    'small_fish' => EventEffect(
      stats: {SurvivalStat.food: 25 + recipes.bonus(state, CampBonus.fishFood)},
      resources: {'small_fish': -1},
    ),
    'raw_meat' => EventEffect(
      stats: {SurvivalStat.food: 22},
      resources: {'raw_meat': -1},
    ),
    'herb' => EventEffect(
      stats: {SurvivalStat.health: 15, SurvivalStat.sanity: 6},
      resources: {'herb': -1},
    ),
    _ => throw ArgumentError.value(id, 'id', 'Not a consumable'),
  };

  bool canConsume(String id) {
    if (!consumables.contains(id) ||
        !state.isAlive ||
        isBusy ||
        state.locationId != 'camp' ||
        state.resource(id) < 1) {
      return false;
    }
    // Only worth using while at least one restored stat is below full.
    return consumeEffect(
      id,
    ).stats.entries.any((e) => e.value > 0 && state.value(e.key) < 100);
  }

  bool consume(String id) {
    if (!canConsume(id)) return false;
    final before = state;
    _apply(consumeEffect(id));
    _finish(id == 'herb' ? 'Herbal tea' : 'A meal by the fire', switch (id) {
      'small_fish' =>
        'You cook one small fish over the campfire and eat it. No daylight spent.',
      'raw_meat' =>
        'You roast the meat until the fat spits and eat it. No daylight spent.',
      _ =>
        'You steep the herbs in hot water. Warmth spreads through your body.',
    }, before);
    return true;
  }

  double chanceFor(EventChoice choice) =>
      (choice.successChance -
              (choice.isRisky && state.value(SurvivalStat.sanity) < 25
                  ? .15
                  : 0))
          .clamp(0, 1);

  bool canChoose(EventChoice choice) =>
      state.isAlive &&
      (_pendingEvent?.choices.contains(choice) ?? false) &&
      choice.isVisible(state) &&
      choice.requires.entries.every((r) => state.resource(r.key) >= r.value) &&
      choice.requiresTools.every(state.tools.contains) &&
      choice.requiresStats.entries.every((r) => state.value(r.key) >= r.value);

  /// The cards on screen for the pending event, given stats and gear.
  List<EventChoice> get visibleChoices => [
    for (final choice in _pendingEvent?.choices ?? const <EventChoice>[])
      if (choice.isVisible(state)) choice,
  ];

  bool choose(String choiceId) {
    if (_pendingEvent == null || _report != null) return false;
    final matches = _pendingEvent!.choices.where((c) => c.id == choiceId);
    if (matches.isEmpty || !canChoose(matches.first)) return false;
    final choice = matches.first;
    final before = state;
    final success = !choice.isRisky || _random.nextDouble() < chanceFor(choice);
    final eventTitle = _pendingEvent!.title;
    final effect = success ? choice.effect : choice.failureEffect!;
    _apply(effect);
    final trip = _expedition;
    if (trip != null) {
      for (final e in effect.resources.entries) {
        if (e.value > 0) {
          trip.loot[e.key] = (trip.loot[e.key] ?? 0) + e.value;
        } else if (e.value < 0 && trip.loot.containsKey(e.key)) {
          // Spend gathered supplies first. A later lost pack must not remove
          // supplies that were already spent, or dip into the camp's stock.
          final remaining = max(0, trip.loot[e.key]! + e.value);
          if (remaining == 0) {
            trip.loot.remove(e.key);
          } else {
            trip.loot[e.key] = remaining;
          }
        }
      }
      if (effect.dropLoot) {
        _apply(
          EventEffect(
            resources: {for (final e in trip.loot.entries) e.key: -e.value},
          ),
        );
        trip.loot.clear();
      }
      if (effect.endsExpedition) {
        _expedition = null;
        _followUp = false;
      }
    }
    if ((effect.stats[SurvivalStat.water] ?? 0) > 0) {
      final filtered = recipes.bonus(state, CampBonus.waterGain);
      if (filtered > 0) {
        _apply(EventEffect(stats: {SurvivalStat.water: filtered}));
      }
    }
    if (_pendingCost > 0) _spendTime(_pendingCost);
    _pendingCost = 0;
    if (state.phase == RunPhase.night) _nightResolved = true;
    _pendingEvent = null;
    _pendingAction = null;
    _finish(
      eventTitle,
      success ? choice.result : choice.failureResult!,
      before,
    );
    return true;
  }

  bool continueFromReport() {
    if (_report == null) return false;
    _report = null;
    final trip = _expedition;
    if (trip != null && state.isAlive) {
      final daylight = state.phase == RunPhase.day && state.timeLeft >= 1;
      if (_followUp && daylight) {
        // The danger is past; the stop itself is still waiting.
        _followUp = false;
        _pendingAction = CampAction.explore;
        _pendingCost = 1;
        _pendingEvent = _pick(
          'explore',
          locationId: trip.locationId,
          depth: trip.depth,
        );
      } else if (daylight) {
        _followUp = false;
        _decisionPending = true;
      } else {
        // Night is closing in: the survivor heads home with what they have.
        _expedition = null;
        _followUp = false;
      }
      if (_pendingEvent != null || _decisionPending) {
        _changed();
        return true;
      }
    }
    _state = state.copyWith(locationId: 'camp');
    if (state.isAlive && state.timeLeft == 0 && state.phase == RunPhase.day) {
      _state = state.copyWith(phase: RunPhase.night);
      _nightResolved = false;
      _pendingEvent = _pick('night');
    }
    _changed();
    return true;
  }

  /// Chance that the next step into the jungle runs into something.
  double get nextEncounterChance {
    final trip = _expedition;
    if (trip == null) return 0;
    if (_expeditionPool(
      trip.locationId,
      trip.depth + 1,
      trigger: 'encounter',
    ).isEmpty) {
      return 0;
    }
    return min(.8, .2 + .2 * (trip.depth + 1));
  }

  bool get canGoDeeper =>
      _decisionPending &&
      state.isAlive &&
      state.phase == RunPhase.day &&
      state.timeLeft >= 1;

  /// Presses on: a step deeper costs 1 time and may meet a danger first.
  bool goDeeper() {
    if (!canGoDeeper) return false;
    final trip = _expedition!;
    final chance = nextEncounterChance;
    trip.depth++;
    _decisionPending = false;
    if (chance > 0 && _random.nextDouble() < chance) {
      _pendingAction = null;
      _pendingCost = 0;
      _followUp = true;
      _pendingEvent = _pick(
        'encounter',
        locationId: trip.locationId,
        depth: trip.depth,
      );
    } else {
      _pendingAction = CampAction.explore;
      _pendingCost = 1;
      _pendingEvent = _pick(
        'explore',
        locationId: trip.locationId,
        depth: trip.depth,
      );
    }
    _changed();
    return true;
  }

  /// Heads home with everything gathered on the trip.
  bool returnHome() {
    if (!_decisionPending) return false;
    final trip = _expedition!;
    final before = state;
    _decisionPending = false;
    _expedition = null;
    _followUp = false;
    _state = state.copyWith(locationId: 'camp');
    final haul = Map<String, int>.of(trip.loot);
    _report = ActionReport.saved(
      title: haul.isEmpty ? 'Back at camp' : 'Home with the haul',
      body: haul.isEmpty
          ? 'You walk back along the trail with nothing to show for it, but alive.'
          : 'You make it back to camp with everything you gathered.',
      changes: haul,
    );
    _journal.insert(
      0,
      'Day ${before.day} · ${_report!.title}. ${_report!.body}',
    );
    if (_journal.length > 30) _journal.removeLast();
    _changed();
    return true;
  }

  bool sleep() {
    if (!canSleep) return false;
    final before = state;
    _apply(
      EventEffect(
        stats: {
          SurvivalStat.water: -10,
          SurvivalStat.food: -8,
          SurvivalStat.sanity: -3,
        },
      ),
    );
    _applyDeprivation();
    if (state.isAlive) {
      if (state.value(SurvivalStat.water) > 0 &&
          state.value(SurvivalStat.food) > 0) {
        _apply(
          EventEffect(
            stats: {
              SurvivalStat.health:
                  10 + recipes.bonus(state, CampBonus.sleepHealth),
            },
          ),
        );
      }
      _apply(
        EventEffect(
          stats: {
            SurvivalStat.sanity: recipes.bonus(state, CampBonus.sleepSanity),
          },
        ),
      );
      _state = state.copyWith(
        day: state.day + 1,
        timeLeft: RunState.dayLength,
        phase: RunPhase.day,
        weather: _random.nextBool() ? 'Sunny' : 'Light rain',
      );
      // Rain fills the collector overnight, so the new weather decides it.
      final dawnWater =
          recipes.bonus(state, CampBonus.dawnWater) +
          (state.weather == 'Sunny'
              ? 0
              : recipes.bonus(state, CampBonus.rainWater));
      _apply(EventEffect(stats: {SurvivalStat.water: dawnWater}));
    }
    _nightResolved = false;
    _finish(
      'A new dawn',
      'You survived the night. A new day unfolds beneath the canopy.',
      before,
    );
    return true;
  }

  void restart() {
    _state = RunState();
    _fishing = null;
    _fishingBefore = null;
    _castSpent = false;
    _pendingEvent = null;
    _pendingAction = null;
    _pendingCost = 0;
    _expedition = null;
    _decisionPending = false;
    _followUp = false;
    _report = null;
    _nightResolved = false;
    _lastEvent.clear();
    _journal
      ..clear()
      ..add('Day 1 · You found a clearing. Make it through the night.');
    _changed();
  }

  List<GameEvent> _expeditionPool(
    String locationId,
    int depth, {
    String trigger = 'explore',
  }) => catalog
      .eligible(trigger, state)
      .where(
        (e) =>
            e.locations.contains(locationId) &&
            depth >= e.minDepth &&
            depth <= e.maxDepth,
      )
      .toList();

  GameEvent _pick(String trigger, {String? locationId, int depth = 0}) {
    final pool = locationId == null
        ? catalog
              .eligible(trigger, state)
              .where((e) => e.locations.isEmpty)
              .toList()
        : _expeditionPool(locationId, depth, trigger: trigger);
    final fresh = pool.where((e) => e.id != _lastEvent[trigger]).toList();
    final candidates = fresh.isEmpty ? pool : fresh;
    final event = candidates[_random.nextInt(candidates.length)];
    _lastEvent[trigger] = event.id;
    return event;
  }

  void _spendTime(int cost) {
    _state = state.copyWith(timeLeft: state.timeLeft - cost);
    for (var tick = 0; tick < cost && state.isAlive; tick++) {
      _apply(
        EventEffect(stats: {SurvivalStat.water: -4, SurvivalStat.food: -3}),
      );
      _applyDeprivation();
    }
  }

  void _applyDeprivation() => _apply(
    EventEffect(
      stats: {
        SurvivalStat.health:
            (state.value(SurvivalStat.water) == 0 ? -12 : 0) +
            (state.value(SurvivalStat.food) == 0 ? -6 : 0),
      },
    ),
  );

  void _apply(EventEffect effect) {
    final stats = {...state.stats};
    final resources = {...state.resources};
    for (final entry in effect.stats.entries) {
      stats[entry.key] = (state.value(entry.key) + entry.value).clamp(0, 100);
    }
    for (final entry in effect.resources.entries) {
      resources[entry.key] = max(0, state.resource(entry.key) + entry.value);
    }
    _state = state.copyWith(stats: stats, resources: resources);
  }

  void _finish(String title, String body, RunState before) {
    if (!state.isAlive) {
      _state = state.copyWith(phase: RunPhase.gameOver);
      _expedition = null;
      _decisionPending = false;
      _followUp = false;
    }
    // Every resolved action is summarized, including the choice that ends a run.
    _report = ActionReport(
      title: title,
      body: body,
      before: before,
      after: state,
    );
    _journal.insert(0, 'Day ${before.day} · $title. $body');
    if (_journal.length > 30) _journal.removeLast();
    _changed();
  }

  void _changed() => onChanged?.call();

  static const saveVersion = 1;

  Map<String, dynamic> toJson() => {
    'version': saveVersion,
    'state': state.toJson(),
    'pendingEvent': _pendingEvent?.id,
    'pendingAction': _pendingAction?.name,
    'report': _report?.toJson(),
    'nightResolved': _nightResolved,
    'pendingCost': _pendingCost,
    'followUp': _followUp,
    'decision': _decisionPending,
    if (_expedition != null) 'expedition': _expedition!.toJson(),
    'lastEvent': _lastEvent,
    'journal': _journal,
    if (_fishing != null)
      'fishing': {'before': _fishingBefore!.toJson(), 'castSpent': _castSpent},
  };

  /// Continues a saved run. Returns false and keeps the current run when the
  /// save is from another version or cannot be read.
  bool restore(Map<String, dynamic> json) {
    try {
      if (json['version'] != saveVersion) return false;
      final restored = RunState.fromJson(json['state'] as Map<String, dynamic>);
      final eventId = json['pendingEvent'] as String?;
      final events = catalog.events.where((e) => e.id == eventId);
      final actionName = json['pendingAction'] as String?;
      final reportJson = json['report'] as Map<String, dynamic>?;
      final fishing = json['fishing'] as Map<String, dynamic>?;
      final journal = List<String>.from(json['journal'] as List);

      _state = restored;
      _pendingEvent = events.isEmpty ? null : events.first;
      _pendingAction = _pendingEvent == null || actionName == null
          ? null
          : CampAction.values.byName(actionName);
      _report = reportJson == null ? null : ActionReport.fromJson(reportJson);
      _nightResolved = json['nightResolved'] as bool;
      _pendingCost =
          json['pendingCost'] as int? ??
          (_pendingAction == null ? 0 : _pendingAction!.cost);
      _followUp = json['followUp'] as bool? ?? false;
      _decisionPending = json['decision'] as bool? ?? false;
      final tripJson = json['expedition'] as Map<String, dynamic>?;
      _expedition = tripJson == null ? null : Expedition.fromJson(tripJson);
      if (_expedition != null && world.find(_expedition!.locationId) == null) {
        _expedition = null;
      }
      if (_expedition == null) {
        _decisionPending = false;
        _followUp = false;
      } else if (_pendingEvent == null &&
          _report == null &&
          !_decisionPending) {
        // A trip never rests between steps without a decision to make.
        _decisionPending = true;
      }
      // A night event removed from the content cannot block sleep forever.
      if (state.phase == RunPhase.night && _pendingEvent == null) {
        _nightResolved = true;
      }
      _lastEvent
        ..clear()
        ..addAll(Map<String, String>.from(json['lastEvent'] as Map));
      _journal
        ..clear()
        ..addAll(journal);
      _fishing = null;
      _fishingBefore = null;
      _castSpent = false;
      if (fishing != null) {
        _fishingBefore = RunState.fromJson(
          fishing['before'] as Map<String, dynamic>,
        );
        _castSpent = fishing['castSpent'] as bool;
        _fishing = FishingSession(random: _random);
        // A cast interrupted by closing the app is lost, like letting go.
        if (_castSpent) finishFishing(abandon: true);
      }
      if (_pendingEvent == null &&
          _report == null &&
          _fishing == null &&
          _expedition == null) {
        _state = state.copyWith(locationId: 'camp');
      }
      return true;
    } catch (_) {
      restart();
      return false;
    }
  }
}
