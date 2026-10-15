import 'dart:math';

import 'crafting.dart';
import 'event_catalog.dart';
import 'expedition.dart';
import 'run_state.dart';
import 'world_catalog.dart';
import 'fishing_session.dart';
import 'rescue_progress.dart';
import 'ruins_puzzle.dart';
import 'gathering_session.dart';
import 'game_sound.dart';

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
  final _listeners = <void Function()>[];
  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  final _soundListeners = <void Function(GameSound)>[];
  void addSoundListener(void Function(GameSound) listener) =>
      _soundListeners.add(listener);
  void removeSoundListener(void Function(GameSound) listener) =>
      _soundListeners.remove(listener);
  void _sound(GameSound sound) {
    for (final listener in List<void Function(GameSound)>.of(_soundListeners)) {
      listener(sound);
    }
  }

  FishingSession? _fishing;
  FishingSession? get fishing => _fishing;
  RunState? _fishingBefore;
  bool _castSpent = false;
  RuinsPuzzle? _ruinsPuzzle;
  RuinsPuzzle? get ruinsPuzzle => _ruinsPuzzle;
  RunState? _puzzleBefore;
  GatheringSession? _gathering;
  GatheringSession? get gathering => _gathering;
  RunState? _gatheringBefore;
  GameEvent? _gatheringSource;
  int _gatheringCost = 1;
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
  final List<String> _dayHighlights = [];
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
      _ruinsPuzzle != null ||
      _gathering != null ||
      _decisionPending;
  bool get canSleep =>
      state.phase == RunPhase.night && !isBusy && _nightResolved;

  bool canAct(CampAction action) =>
      state.isAlive &&
      state.phase == RunPhase.day &&
      state.rescueStage != RescueStage.storm &&
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
    if (state.rescueStage == RescueStage.storm) {
      return 'Keep the rescue signal alive. The storm must pass first.';
    }
    final lock = location.lockReason(state);
    if (lock != null) return lock;
    if (state.timeLeft < location.timeCost) {
      return 'Need ${location.timeCost} daylight. Rest until tomorrow.';
    }
    if (id == 'ancient_ruins' && state.timeLeft < location.timeCost + 1) {
      return 'Need ${location.timeCost + 1} daylight for the journey and altar.';
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
      _sound(GameSound.travel);
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
        _sound(GameSound.travel);
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

  bool canRepairTool(String id) =>
      state.tools.contains(id) &&
      RunState.toolDurability.containsKey(id) &&
      state.toolCondition(id) < RunState.toolDurability[id]!;

  String? gatheringBlockReason(GatheringKind kind) {
    if (!state.isAlive || state.phase != RunPhase.day) {
      return 'Gather in daylight.';
    }
    if (state.rescueStage == RescueStage.storm) {
      return 'Keep the rescue signal alive.';
    }
    final cost = _gathering?.kind == kind ? _gatheringCost : 1;
    if (state.timeLeft < cost) return 'Need $cost daylight.';
    if (kind != GatheringKind.foraging && !state.toolUsable(kind.art)) {
      return state.tools.contains(kind.art)
          ? 'Repair your ${itemName(kind.art).toLowerCase()} in the workshop.'
          : 'Craft a ${itemName(kind.art).toLowerCase()} in the workshop.';
    }
    return null;
  }

  int get gatheringCost => _gatheringCost;

  /// The ready screen reserves an activity; START spends its time once.
  bool openGathering(GatheringKind kind) {
    if (!canAct(CampAction.forage) || state.locationId != 'camp') return false;
    _gathering = GatheringSession(kind, random: _random);
    _gatheringBefore = state;
    _gatheringSource = null;
    _gatheringCost = 1;
    _changed();
    return true;
  }

  bool beginGathering() {
    final session = _gathering;
    if (session == null ||
        session.stage != GatheringStage.ready ||
        gatheringBlockReason(session.kind) != null) {
      return false;
    }
    session.start();
    _spendTime(_gatheringCost);
    _pendingCost = 0;
    if (!state.isAlive) {
      session.finish(leave: true);
      finishGathering();
    } else {
      _changed();
    }
    return true;
  }

  void tickGathering(double seconds) => _gathering?.update(seconds);
  void saveGatheringProgress() {
    if (_gathering != null) _changed();
  }

  void pauseGathering(bool paused) {
    final session = _gathering;
    if (session == null ||
        session.stage != GatheringStage.active ||
        session.paused == paused) {
      return;
    }
    session.paused = paused;
    _changed();
  }

  bool strikeGathering() {
    if (!(_gathering?.strike() ?? false)) return false;
    _changed();
    if (_gathering!.kind == GatheringKind.chopping &&
        _gathering!.lastQuality != TimingQuality.miss) {
      _sound(GameSound.woodChop);
    }
    return true;
  }

  bool pickGatheringPlant(String id) {
    if (!(_gathering?.pick(id, state.tools) ?? false)) return false;
    _changed();
    return true;
  }

  bool cancelGathering() {
    if (_gathering?.stage != GatheringStage.ready) return false;
    _pendingEvent = _gatheringSource;
    _pendingAction = switch (_gatheringSource?.trigger) {
      'forage' => CampAction.forage,
      'explore' => CampAction.explore,
      _ => null,
    };
    _gathering = null;
    _gatheringBefore = null;
    _gatheringSource = null;
    _changed();
    return true;
  }

  bool finishGathering({bool leave = false}) {
    final session = _gathering;
    if (session == null ||
        _gatheringBefore == null ||
        session.stage == GatheringStage.ready) {
      return false;
    }
    if (!session.complete && !session.finish(leave: leave)) return false;
    final before = _gatheringBefore!;
    final resources = <String, int>{};
    final stats = <SurvivalStat, int>{};
    final notes = <String>[];
    if (state.isAlive) {
      switch (session.kind) {
        case GatheringKind.chopping:
          final wood = session.hits.fold(
            0,
            (total, hit) =>
                total +
                switch (hit) {
                  TimingQuality.miss => 0,
                  TimingQuality.good => 2,
                  TimingQuality.perfect => 3,
                },
          );
          if (wood > 0) resources['wood'] = wood;
          final perfectHits = session.hits
              .where((h) => h == TimingQuality.perfect)
              .length;
          if (perfectHits >= 2) {
            resources['hardwood'] = perfectHits == 3 ? 2 : 1;
          }
          notes.add(
            wood > 0
                ? 'You gathered wood from ${session.hits.length} swings.'
                : 'The axe missed. You recovered no wood.',
          );
        case GatheringKind.hunting:
          final quality = session.hits.isEmpty
              ? TimingQuality.miss
              : session.hits.single;
          if (quality != TimingQuality.miss) {
            resources['raw_meat'] = quality == TimingQuality.perfect ? 3 : 2;
          }
          notes.add(
            quality == TimingQuality.miss
                ? 'The boar escaped. You brought back no meat.'
                : 'Your spear landed cleanly. You recovered fresh meat.',
          );
        case GatheringKind.foraging:
          for (final plant in session.picked) {
            switch (plant) {
              case 'berries':
                stats[SurvivalStat.food] = (stats[SurvivalStat.food] ?? 0) + 7;
              case 'fiber':
                resources['fiber'] = 2;
              case 'herb':
                resources['herb'] = (resources['herb'] ?? 0) + 1;
              case 'mushroom':
                if (session.mushroomSafe) {
                  stats[SurvivalStat.food] =
                      (stats[SurvivalStat.food] ?? 0) + 9;
                  notes.add('The mushrooms were edible.');
                } else {
                  stats[SurvivalStat.health] =
                      (stats[SurvivalStat.health] ?? 0) - 6;
                  notes.add('The mushrooms made you ill.');
                }
              case 'unknown_plant':
                if (session.unknownSafe) {
                  resources['herb'] = (resources['herb'] ?? 0) + 2;
                  notes.add('The unfamiliar plant yielded useful herbs.');
                } else {
                  stats[SurvivalStat.health] =
                      (stats[SurvivalStat.health] ?? 0) - 8;
                  notes.add('The unfamiliar berries irritated your skin.');
                }
            }
          }
          notes.insert(
            0,
            session.picked.isEmpty
                ? 'You left the plants untouched.'
                : 'You gathered ${session.picked.length} different plants.',
          );
      }
      _apply(EventEffect(resources: resources, stats: stats));
      for (final entry in resources.entries) {
        _expedition?.loot.update(
          entry.key,
          (v) => v + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      if (session.kind != GatheringKind.foraging) {
        final tool = session.kind.art;
        final wear = max(
          1,
          session.hits.where((h) => h == TimingQuality.miss).length + 1,
        );
        notes.add(_wearTool(tool, wear));
      }
    } else {
      notes.add('Your supplies ran out before you could gather anything.');
    }
    if (session.timedOut) {
      notes.add('Time ran out; your completed progress was kept.');
    }
    if (session.abandoned) {
      notes.add(
        'You ended the attempt early. The daylight already spent is not returned.',
      );
    }
    final title = switch (session.kind) {
      GatheringKind.chopping =>
        resources.isEmpty ? 'A rough cut' : 'Wood from the clearing',
      GatheringKind.foraging =>
        (stats[SurvivalStat.health] ?? 0) < 0
            ? 'A bitter discovery'
            : 'Gathered from the grove',
      GatheringKind.hunting =>
        resources.isEmpty ? 'The boar escaped' : 'A well-timed throw',
    };
    _gathering = null;
    _gatheringBefore = null;
    _gatheringSource = null;
    _pendingAction = null;
    _pendingCost = 0;
    _finish(title, notes.join(' '), before);
    return true;
  }

  /// Accepted tool use wears equipment even when the attempt fails.
  /// Minigames call this only when resolving, never when opening a card.
  String _wearTool(String tool, int wear) {
    final condition = state.toolCondition(tool);
    final remaining = max(0, condition - wear);
    _state = state.copyWith(durability: {...state.durability, tool: remaining});
    return '${itemName(tool)} durability: $condition → $remaining.${remaining == 0 ? ' Repair it in the workshop.' : ''}';
  }

  String? craftBlockReason(String id) {
    final recipe = recipes.find(id);
    if (recipe == null) return 'Unknown recipe';
    if (recipe.isOwnedBy(state) && !canRepairTool(id)) {
      return recipe.kind == RecipeKind.campTier ? 'Built' : 'Already crafted';
    }
    if (!state.isAlive || isBusy || state.locationId != 'camp') {
      return 'Return to camp first';
    }
    if (state.phase != RunPhase.day) return 'Build in daylight';
    if (state.rescueStage == RescueStage.storm) return 'Keep the signal alive';
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
    final repairing = canRepairTool(id);
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
      if (RunState.toolDurability.containsKey(id)) {
        _state = state.copyWith(
          durability: {...state.durability, id: RunState.toolDurability[id]!},
        );
      }
      if (id == 'emergency_beacon') {
        _state = state.copyWith(
          foundComponents: {...state.foundComponents, ...beaconComponents.keys},
        );
      }
    }
    _finish(
      !state.isAlive
          ? 'An unfinished ${recipe.name}'
          : upgrade
          ? 'Camp upgraded: ${recipe.name}'
          : '${repairing ? 'Repaired' : 'Crafted'}: ${recipe.name}',
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
        state.rescued ||
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
      choice.requiresTools.every(state.toolUsable) &&
      (choice.minigame != 'ruins_symbols' ||
          state.timeLeft >= _pendingCost + 1) &&
      (GatheringKind.fromId(choice.minigame) == null ||
          state.timeLeft >= max(1, _pendingCost)) &&
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
    final gatheringKind = GatheringKind.fromId(choice.minigame);
    if (gatheringKind != null) {
      _gatheringSource = _pendingEvent;
      _gatheringBefore = before;
      _gatheringCost = max(1, _pendingCost);
      _gathering = GatheringSession(gatheringKind, random: _random);
      _pendingEvent = null;
      _changed();
      return true;
    }
    if (choice.minigame == 'ruins_symbols') {
      _spendTime(_pendingCost);
      _pendingCost = 0;
      _pendingEvent = null;
      _pendingAction = null;
      if (state.isAlive) {
        _ruinsPuzzle = RuinsPuzzle(random: _random);
        _puzzleBefore = before;
        _changed();
      } else {
        _finish(
          'The sealed altar',
          'Your supplies ran out before you reached the altar.',
          before,
        );
      }
      return true;
    }
    final rescueTrial = _pendingEvent!.trigger == 'rescue';
    final success = !choice.isRisky || _random.nextDouble() < chanceFor(choice);
    final eventTitle = _pendingEvent!.title;
    final effect = success ? choice.effect : choice.failureEffect!;
    _apply(effect);
    final wearNotes = [
      for (final tool in choice.requiresTools)
        if (RunState.toolDurability.containsKey(tool)) _wearTool(tool, 1),
    ];
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
    if (rescueTrial && state.isAlive) {
      _state = state.copyWith(rescueStep: state.rescueStep + 1);
      if (state.rescueStep == rescueEventIds.length) {
        _state = state.copyWith(phase: RunPhase.rescued, locationId: 'camp');
      }
    }
    _pendingCost = 0;
    if (state.phase == RunPhase.night) _nightResolved = true;
    _pendingEvent = null;
    _pendingAction = null;
    _finish(
      eventTitle,
      [success ? choice.result : choice.failureResult!, ...wearNotes].join(' '),
      before,
    );
    if (choice.requiresTools.contains('stone_axe') &&
        (effect.resources['wood'] ?? 0) > 0) {
      _sound(GameSound.woodChop);
    }
    return true;
  }

  bool continueFromReport() {
    if (_report == null) return false;
    _report = null;
    if (state.rescued || !state.isAlive) {
      _state = state.copyWith(locationId: 'camp');
      _changed();
      return true;
    }
    if (state.rescueStage == RescueStage.storm) {
      _queueRescueEvent();
      _changed();
      return true;
    }
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
      _gathering == null &&
      _ruinsPuzzle == null &&
      _pendingEvent == null &&
      _report == null &&
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
    _sound(GameSound.travel);
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
    _sound(GameSound.travel);
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
      if (state.rescueStage == RescueStage.signalSent) {
        _state = state.copyWith(
          rescueStage: RescueStage.storm,
          rescueStep: 0,
          weather: 'Storm',
        );
      }
      // The final storm fills a rain collector just like other rainy dawns.
      final dawnWater =
          recipes.bonus(state, CampBonus.dawnWater) +
          (state.weather == 'Sunny'
              ? 0
              : recipes.bonus(state, CampBonus.rainWater));
      _apply(EventEffect(stats: {SurvivalStat.water: dawnWater}));
    }
    _nightResolved = false;
    final summary = state.isAlive
        ? DaySummary(day: before.day, highlights: _dayHighlights)
        : null;
    _dayHighlights.clear();
    _finish(
      !state.isAlive
          ? 'The night takes its toll'
          : state.rescueStage == RescueStage.storm
          ? 'The rescue storm'
          : 'A new dawn',
      !state.isAlive
          ? 'Your supplies ran out before dawn. This journey has come to an end.'
          : state.rescueStage == RescueStage.storm
          ? 'A rescue team has your signal. Keep the beacon alive through the storm until they reach the clearing.'
          : 'You survived the night. A new day unfolds beneath the canopy.',
      before,
      daySummary: summary,
    );
    return true;
  }

  int get heldBeaconComponents =>
      beaconComponents.keys.where((id) => state.resource(id) > 0).length;

  String? get activateBeaconBlockReason {
    if (!state.tools.contains('emergency_beacon')) {
      return 'Assemble the Emergency Beacon first';
    }
    if (state.rescueStage != RescueStage.searching || state.rescued) {
      return 'Signal already sent';
    }
    if (!state.isAlive || isBusy || state.locationId != 'camp') {
      return 'Return to camp first';
    }
    if (state.phase != RunPhase.day) return 'Send the signal in daylight';
    if (state.timeLeft < 1) return 'Need 1 daylight';
    return null;
  }

  bool activateBeacon() {
    if (activateBeaconBlockReason != null) return false;
    final before = state;
    _spendTime(1);
    if (state.isAlive) {
      _state = state.copyWith(
        rescueStage: RescueStage.signalSent,
        signalDay: state.day,
      );
    }
    _finish(
      state.isAlive ? 'Signal received' : 'An unfinished signal',
      state.isAlive
          ? 'A distant voice answers. Rescue is coming tomorrow. Prepare food, water and shelter before you sleep.'
          : 'Your supplies ran out before you could send the signal.',
      before,
    );
    return true;
  }

  void _queueRescueEvent() {
    if (state.rescueStep >= rescueEventIds.length) return;
    _pendingEvent = catalog.events.firstWhere(
      (e) => e.id == rescueEventIds[state.rescueStep],
    );
    _pendingAction = null;
    _pendingCost = 2;
  }

  bool turnRuinsTile(int index) {
    if (_ruinsPuzzle == null || !_ruinsPuzzle!.rotate(index)) return false;
    _changed();
    return true;
  }

  bool finishRuinsPuzzle({bool leave = false}) {
    final puzzle = _ruinsPuzzle;
    if (puzzle == null ||
        _puzzleBefore == null ||
        (!leave && state.timeLeft < 1)) {
      return false;
    }
    final before = _puzzleBefore!;
    final solved = !leave && puzzle.solved;
    if (!leave) _spendTime(1);
    if (solved && state.isAlive && state.resource('beacon_core') == 0) {
      _apply(EventEffect(resources: {'beacon_core': 1}));
      _expedition?.loot.update('beacon_core', (v) => v + 1, ifAbsent: () => 1);
    } else if (!leave && state.isAlive) {
      _apply(EventEffect(stats: {SurvivalStat.sanity: -3}));
    }
    _ruinsPuzzle = null;
    _puzzleBefore = null;
    _finish(
      solved && state.isAlive ? 'The altar opens' : 'The sealed altar',
      !state.isAlive
          ? 'The jungle takes its toll before the stone seal opens.'
          : solved
          ? 'The carved discs settle into place. Inside the old survey cache lies a working Beacon Core. Carry it safely home.'
          : leave
          ? 'You leave the stone seal undisturbed. You can return to try again.'
          : 'The discs grind, but the seal stays shut. Look at the carved sequence and try again on another stop.',
      before,
    );
    return true;
  }

  void restart() {
    _state = RunState();
    _fishing = null;
    _fishingBefore = null;
    _castSpent = false;
    _ruinsPuzzle = null;
    _puzzleBefore = null;
    _gathering = null;
    _gatheringBefore = null;
    _gatheringSource = null;
    _gatheringCost = 1;
    _pendingEvent = null;
    _pendingAction = null;
    _pendingCost = 0;
    _expedition = null;
    _decisionPending = false;
    _followUp = false;
    _report = null;
    _nightResolved = false;
    _lastEvent.clear();
    _dayHighlights.clear();
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
    final priority = pool.fold<int>(0, (p, e) => max(p, e.priority));
    final preferred = pool.where((e) => e.priority == priority).toList();
    final fresh = preferred.where((e) => e.id != _lastEvent[trigger]).toList();
    final candidates = fresh.isEmpty ? preferred : fresh;
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
    _state = state.copyWith(
      stats: stats,
      resources: resources,
      foundComponents: {
        ...state.foundComponents,
        for (final entry in effect.resources.entries)
          if (entry.value > 0 && beaconComponents.containsKey(entry.key))
            entry.key,
      },
    );
  }

  void _finish(
    String title,
    String body,
    RunState before, {
    DaySummary? daySummary,
  }) {
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
      daySummary: daySummary,
    );
    if (daySummary == null && before.day == state.day) {
      _dayHighlights.add(title);
      final place = world.find(before.locationId);
      if (place != null && place.id != 'camp') {
        _dayHighlights.add('Explored ${place.name}');
      }
      while (_dayHighlights.length > 50) {
        _dayHighlights.removeAt(0);
      }
    }
    _journal.insert(0, 'Day ${before.day} · $title. $body');
    if (_journal.length > 30) _journal.removeLast();
    _changed();
  }

  void _changed() {
    onChanged?.call();
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

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
    'dayHighlights': List<String>.of(_dayHighlights),
    if (_fishing != null)
      'fishing': {'before': _fishingBefore!.toJson(), 'castSpent': _castSpent},
    if (_ruinsPuzzle != null)
      'ruinsPuzzle': {
        'session': _ruinsPuzzle!.toJson(),
        'before': _puzzleBefore!.toJson(),
      },
    if (_gathering != null)
      'gathering': {
        'session': _gathering!.toJson(),
        'before': _gatheringBefore!.toJson(),
        'source': _gatheringSource?.id,
        'cost': _gatheringCost,
      },
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
      final puzzle = json['ruinsPuzzle'] as Map<String, dynamic>?;
      final gathering = json['gathering'] as Map<String, dynamic>?;
      final journal = List<String>.from(json['journal'] as List);
      final dayHighlights = List<String>.from(
        json['dayHighlights'] as List? ?? [],
      );

      _state = restored;
      _dayHighlights
        ..clear()
        ..addAll(dayHighlights);
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
          puzzle == null &&
          gathering == null &&
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
      _ruinsPuzzle = puzzle == null
          ? null
          : RuinsPuzzle.fromJson(puzzle['session'] as Map<String, dynamic>);
      _puzzleBefore = puzzle == null
          ? null
          : RunState.fromJson(puzzle['before'] as Map<String, dynamic>);
      _gathering = gathering == null
          ? null
          : GatheringSession.fromJson(
              gathering['session'] as Map<String, dynamic>,
            );
      _gatheringBefore = gathering == null
          ? null
          : RunState.fromJson(gathering['before'] as Map<String, dynamic>);
      final sources = catalog.events.where((e) => e.id == gathering?['source']);
      _gatheringSource = sources.isEmpty ? null : sources.first;
      _gatheringCost = gathering == null
          ? 1
          : (gathering['cost'] as int).clamp(1, RunState.dayLength);
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
          _ruinsPuzzle == null &&
          _gathering == null &&
          _expedition == null) {
        _state = state.copyWith(locationId: 'camp');
      }
      if (state.rescueStage == RescueStage.storm &&
          !state.rescued &&
          state.isAlive &&
          _pendingEvent == null &&
          _report == null) {
        if (_gathering != null) return true;
        _queueRescueEvent();
      }
      return true;
    } catch (_) {
      restart();
      return false;
    }
  }
}
