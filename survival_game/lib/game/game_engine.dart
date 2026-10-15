import 'dart:async';
import 'tutorial_progress.dart';
import 'dart:convert';
import 'run_progression.dart';
import 'inventory_catalog.dart';
import 'tool_catalog.dart';
import 'dart:math';

import 'crafting.dart';
import 'event_catalog.dart';
import 'expedition.dart';
import 'run_state.dart';
import 'world_catalog.dart';
import 'fishing_session.dart';
import 'fishing_catalog.dart';
import 'rescue_progress.dart';
import 'ruins_puzzle.dart';
import 'gathering_session.dart';
import 'game_sound.dart';
import 'ecology_catalog.dart';

/// Synchronous transactions: a decision can only resolve once, and no time
/// passes while a player is reading an event or its outcome.
class GameEngine {
  GameEngine(
    this.catalog, {
    Random? random,
    RunState? initialState,
    WorldCatalog? world,
    RecipeCatalog? recipes,
    bool offerFirstRunGuide = false,
  }) : world = world ?? WorldCatalog([]),
       recipes = recipes ?? RecipeCatalog([]),
       _random = random ?? Random(),
       _state =
           initialState ??
           RunState(resources: {'wood': 2, 'stone': 0, 'fiber': 0, 'herb': 2}) {
    metrics.campTier = state.campTier;
    tutorial.offered = offerFirstRunGuide && initialState == null;
  }
  RunMetrics metrics = RunMetrics();
  PlayerProfile profile = PlayerProfile();
  RunSummary? completedRun;
  bool rankNoticePending = false;
  TutorialProgress tutorial = TutorialProgress();
  void decideFirstRunGuide(bool accept) {
    if (!tutorial.welcomePending || profile.firstRunGuideHandled) return;
    profile.firstRunGuideHandled = true;
    tutorial.accepted = accept;
    tutorial.skipped = !accept;
    _changed();
  }

  void collapseGuide(bool value) {
    tutorial.collapsed = value;
    _changed();
  }

  void skipGuide() {
    tutorial.skipped = true;
    profile.firstRunGuideHandled = true;
    _changed();
  }

  void resumeGuide() {
    // Only the original accepted journey can resume its practical lessons.
    if (!tutorial.accepted || tutorial.complete) return;
    tutorial.skipped = false;
    tutorial.collapsed = false;
    _changed();
  }

  void acknowledgeGuideCompletion() {
    if (!tutorial.complete) return;
    tutorial.completionRead = true;
    profile.completedFirstDay = true;
    _changed();
  }

  void acknowledgeRank() {
    rankNoticePending = false;
    _changed();
  }

  String? _pendingFishId;
  int _pendingFishBaseline = 0;
  Future<void> Function(Map<String, dynamic>)? persistSnapshot;
  Future<void> _saveQueue = Future.value();
  int _saveGeneration = 0;
  bool saving = false, saveFailed = false;
  bool get canStartNewRun => !saving && !saveFailed;
  Future<void> get saveSettled => _saveQueue;
  Future<void> retrySave() => _persist();
  Future<void> _persist() {
    final writer = persistSnapshot;
    if (writer == null) return Future.value();
    final snapshot = jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>;
    final generation = ++_saveGeneration;
    saving = true;
    _saveQueue = _saveQueue.then((_) async {
      try {
        await writer(snapshot);
        if (generation == _saveGeneration) saveFailed = false;
      } catch (_) {
        if (generation == _saveGeneration) saveFailed = true;
      } finally {
        if (generation == _saveGeneration) {
          saving = false;
          _notify();
        }
      }
    });
    return _saveQueue;
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  bool selectStartingOption(String id) {
    if (!profile.canSelect(id)) return false;
    profile.nextOption = id;
    _changed();
    return true;
  }

  void ensureRunSummary({String? outcome}) {
    if (completedRun?.id == metrics.id) return;
    final result =
        outcome ??
        (state.rescued
            ? 'rescued'
            : !state.isAlive || state.phase == RunPhase.gameOver
            ? 'lost'
            : null);
    if (result == null) return;
    completedRun = RunSummary(
      metrics: metrics,
      outcome: result,
      day: state.day,
      location: metrics.fatalLocation ?? state.locationId,
      stats: Map.unmodifiable(state.stats),
      xpBefore: profile.xp,
    );
    if (profile.record(completedRun!) && !metrics.legacyEnded) {
      rankNoticePending =
          rankFor(completedRun!.xpAfter) > rankFor(completedRun!.xpBefore);
    }
  }

  bool abandonJourney() {
    if (completedRun != null || !canStartNewRun) return false;
    ensureRunSummary(outcome: 'abandoned');
    _changed();
    return true;
  }

  void _visit(String id) {
    if (metrics.locations.add(id)) {
      metrics.note(
        state.day,
        id,
        'Reached ${world.find(id)?.name ?? id}',
        'map',
      );
    }
  }

  void _recordHomeSupplies() {
    if (!state.isAlive || state.inField) return;
    for (final id in beaconComponents.keys) {
      if ((state.storedResources[id] ?? 0) > 0 && metrics.components.add(id)) {
        metrics.note(state.day, 'camp', 'Brought ${itemName(id)} home', id);
      }
    }
  }

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
    'Day 1 · You found a clearing and 2 medicinal herbs. Gathering stores food: use Items to study, prepare or eat it.',
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
  PackingDraft? _packingDraft;
  PackingDraft? get packingDraft => _packingDraft;
  Map<String, int> _lastPack = {};
  bool _lastPackSaved = false;
  Set<String>? _lastGear;
  bool _returnAfterHaul = false;
  Map<String, int>? _haulSelection;
  Map<String, int> get haulSelection =>
      Map.unmodifiable(_haulSelection ?? haulCandidate);
  bool updateHaulSelection(Map<String, int> kept) {
    if (!hasPendingHaul ||
        kept.entries.any(
          (e) => e.value < 0 || e.value > (haulCandidate[e.key] ?? 0),
        )) {
      return false;
    }
    _haulSelection = {...kept};
    _changed();
    return true;
  }

  bool get hasPendingHaul => state.pendingResources.isNotEmpty;
  Map<String, int> get haulCandidate =>
      mergeItems(state.packResources, state.pendingResources);

  String? get packingNotice {
    if (!_lastPackSaved) return null;
    final missing = [
      for (final e in _lastPack.entries)
        if (e.value > (state.storedResources[e.key] ?? 0)) itemName(e.key),
      for (final id in _lastGear ?? <String>{})
        if (!state.toolUsable(id)) itemName(id),
    ];
    return missing.isEmpty
        ? null
        : 'Last loadout adjusted: ${missing.join(', ')} unavailable or insufficient.';
  }

  Set<String> get suggestedGear => _lastGear == null
      ? {
          if (state.activeFieldTool('axe') case final String id) id,
          if (state.activeFieldTool('spear') case final String id) id,
          if (fishingRods.keys.any(state.toolUsable)) activeFishingRod,
          if (state.tools.contains('machete'))
            'machete'
          else if (state.tools.contains('stone_knife'))
            'stone_knife',
          if (state.tools.contains('torch')) 'torch',
          if (state.availableTools.contains('leaf_rain_cape')) 'leaf_rain_cape',
        }
      : _lastGear!.where(state.toolUsable).toSet();
  Map<String, int> recommendedPack(String destination) {
    final requested = _lastPackSaved
        ? _lastPack
        : <String, int>{
            if (state.resource('prepared_small_fish') > 0)
              'prepared_small_fish': 2,
            if (state.availableResource('herb') > 0) 'herb': 2,
            if (state.availableResource('bandage') > 0) 'bandage': 1,
            for (final id in fishingBaits.keys)
              if (state.resource(id) > 0) id: 2,
          };
    final result = <String, int>{};
    for (final e in requested.entries) {
      final n = min(e.value, state.storedResources[e.key] ?? 0);
      if (n > 0 && packSlots({...result, e.key: n}) <= state.packCapacity) {
        result[e.key] = n;
      }
    }
    return result;
  }

  bool beginPacking(String destination) {
    if (_packingDraft != null ||
        travelBlockReason(destination) != null ||
        destination == 'camp') {
      return false;
    }
    _packingDraft = PackingDraft(
      destination,
      recommendedPack(destination),
      suggestedGear,
    );
    _changed();
    return true;
  }

  bool updatePacking(Map<String, int> items, Set<String> gear) {
    if (_packingDraft == null ||
        items.entries.any(
          (e) => e.value < 0 || e.value > (state.storedResources[e.key] ?? 0),
        ) ||
        !gear.every(state.tools.contains)) {
      return false;
    }
    _packingDraft = PackingDraft(
      _packingDraft!.destination,
      positiveItems(items),
      gear,
    );
    _changed();
    return true;
  }

  void cancelPacking() {
    _packingDraft = null;
    _changed();
  }

  String? departureBlockReason(
    String destination,
    Map<String, int> items,
    Set<String> gear,
  ) {
    final base = travelBlockReason(destination);
    if (base != null) return base;
    if (items.entries.any(
      (e) => e.value < 0 || e.value > (state.storedResources[e.key] ?? 0),
    )) {
      return 'Not enough items in camp storage';
    }
    if (packSlots(items) > state.packCapacity) {
      return 'Pack exceeds ${state.packCapacity} slots';
    }
    final allowed = {
      ...fieldTools.keys,
      ...fishingRods.keys,
      'stone_knife',
      'machete',
      'torch',
      'leaf_rain_cape',
    };
    if (!gear.every((id) => allowed.contains(id) && state.toolUsable(id))) {
      return 'Choose working equipment you own';
    }
    for (final family in ['axe', 'spear', 'rod', 'blade']) {
      final count = gear
          .where(
            (id) =>
                (fieldTools[id]?.family ??
                    (fishingRods.containsKey(id)
                        ? 'rod'
                        : {'stone_knife', 'machete'}.contains(id)
                        ? 'blade'
                        : id)) ==
                family,
          )
          .length;
      if (count > 1) return 'Only one $family can be equipped';
    }
    if (destination == 'fishing_pond' &&
        (!gear.any(fishingRods.containsKey) ||
            !items.entries.any(
              (e) => fishingBaits.containsKey(e.key) && e.value > 0,
            ))) {
      return 'Pack a working rod and at least one bait';
    }
    final required = world.find(destination)?.requiresTool;
    if (required != null && !gear.contains(required)) {
      return 'Equip ${itemName(required)} for this route';
    }
    return null;
  }

  bool leaveCamp() {
    final draft = _packingDraft;
    if (draft == null) return false;
    return travelTo(draft.destination, pack: draft.items, gear: draft.gear);
  }

  void _unloadPack() {
    if (state.inField && state.isAlive && tutorial.completed.contains('pack')) {
      tutorial.learn('return');
    }
    if (_pendingFishId != null) {
      if (state.isAlive &&
          state.availableResource(_pendingFishId!) > _pendingFishBaseline) {
        metrics.fishKept++;
      }
      _pendingFishId = null;
    }
    _state = state.copyWith(
      locationId: 'camp',
      packResources: {},
      pendingResources: {},
      clearExpeditionGear: true,
      legacyPack: false,
    );
    _returnAfterHaul = false;
  }

  bool resolveHaul(Map<String, int> kept) {
    if (!hasPendingHaul ||
        kept.entries.any(
          (e) => e.value < 0 || e.value > (haulCandidate[e.key] ?? 0),
        ) ||
        packSlots(kept) > state.packCapacity) {
      return false;
    }
    final candidate = haulCandidate;
    _haulSelection = null;
    final discarded = {
      for (final e in candidate.entries)
        if (e.value > (kept[e.key] ?? 0)) e.key: e.value - (kept[e.key] ?? 0),
    };
    final total = {...state.resources};
    for (final e in discarded.entries) {
      total[e.key] = max(0, (total[e.key] ?? 0) - e.value);
    }
    final trip = _expedition;
    if (trip != null) {
      for (final e in discarded.entries) {
        trip.loot[e.key] = max(0, (trip.loot[e.key] ?? 0) - e.value);
      }
    }
    _state = state.copyWith(
      resources: total,
      packResources: positiveItems(kept),
      pendingResources: {},
    );
    final report = _report;
    if (report != null) {
      final changes = {...report.changes};
      for (final e in discarded.entries) {
        changes[e.key] = (changes[e.key] ?? 0) - e.value;
      }
      changes.removeWhere((key, value) => value == 0);
      _report = ActionReport.saved(
        title: report.title,
        body:
            report.body +
            (discarded.isEmpty
                ? ''
                : ' Left behind: ${discarded.entries.map((e) => '${e.value} ${itemName(e.key)}').join(', ')}.'),
        changes: changes,
        conditionChanges: report.conditionChanges,
        catchRecord: report.catchRecord,
        daySummary: report.daySummary,
      );
    }
    if (_returnAfterHaul) _unloadPack();
    _changed();
    return true;
  }

  bool get isBusy =>
      completedRun?.outcome == 'abandoned' ||
      hasPendingHaul ||
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
      _packingDraft == null &&
      state.timeLeft >= action.cost;

  bool startAction(CampAction action) {
    if (!canAct(action)) return false;
    if (action == CampAction.rest) {
      final before = state;
      _spendTime(action.cost, outdoor: false);
      // Rest cannot revive a survivor lost to dehydration or starvation.
      if (state.isAlive) {
        _apply(
          EventEffect(stats: {SurvivalStat.health: 8, SurvivalStat.sanity: 12}),
        );
      }
      _shortenCondition(ConditionKind.exhausted, 2);
      _shortenCondition(ConditionKind.injured, 1);
      _state = state.copyWith(strain: max(0, state.strain - 3));
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
      if (!fishingRods.keys.any(state.toolUsable)) {
        return fishingRods.keys.any(state.tools.contains)
            ? 'Repair a fishing rod in the workshop.'
            : 'Craft a Basic Rod in the workshop.';
      }
      if (!fishingBaits.keys.any((id) => state.availableResource(id) > 0)) {
        return 'Collect bait at the Riverbank first.';
      }
    }
    return null;
  }

  bool travelTo(String id, {Map<String, int>? pack, Set<String>? gear}) {
    final selectedPack = positiveItems(pack ?? recommendedPack(id));
    final selectedGear = gear ?? suggestedGear;
    if (id == 'camp' ||
        departureBlockReason(id, selectedPack, selectedGear) != null) {
      return false;
    }
    final location = world.find(id)!;
    if (id != 'fishing_pond' && _expeditionPool(id, 0).isEmpty) return false;
    tutorial.learn('pack');
    _visit(id);
    _lastPack = {...selectedPack};
    _lastPackSaved = true;
    _lastGear = {...selectedGear};
    _packingDraft = null;
    _state = state.copyWith(
      packResources: selectedPack,
      expeditionGear: selectedGear,
      legacyPack: false,
    );
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
        _fishing = FishingSession(
          random: _random,
          zoneScale: before.hasCondition(ConditionKind.exhausted) ? .9 : 1,
        );
        _fishing!.rodId = activeFishingRod;
        _fishing!.baitId = fishingBaits.keys.firstWhere(
          (id) => state.availableResource(id) > 0,
        );
        _changed();
        _sound(GameSound.travel);
      }
      return true;
    }
    return false;
  }

  String get activeFishingRod =>
      state.toolUsable(state.equippedRod) &&
          fishingRods.containsKey(state.equippedRod)
      ? state.equippedRod
      : fishingRods.keys.toList().reversed.firstWhere(
          state.toolUsable,
          orElse: () => 'basic_rod',
        );

  bool selectFishingBait(String id) {
    final session = _fishing;
    if (session == null ||
        session.stage != FishingStage.ready ||
        !fishingBaits.containsKey(id) ||
        state.availableResource(id) < 1) {
      return false;
    }
    session.baitId = id;
    _changed();
    return true;
  }

  bool equipFishingRod(String id) {
    if (!fishingRods.containsKey(id) || !state.toolUsable(id)) return false;
    if (_fishing != null
        ? _fishing!.stage != FishingStage.ready
        : !canUseSupplies || state.locationId != 'camp') {
      return false;
    }
    _state = state.copyWith(equippedRod: id);
    _fishing?.rodId = id;
    _changed();
    return true;
  }

  void saveFishingProgress() {
    if (_fishing != null) _changed();
  }

  void pauseFishing(bool paused) {
    if (_fishing == null ||
        _fishing!.complete ||
        _fishing!.stage == FishingStage.ready) {
      return;
    }
    _fishing!.paused = paused;
    _fishing!.holding = false;
    _changed();
  }

  bool castLine() {
    final session = _fishing;
    if (session == null ||
        session.stage != FishingStage.ready ||
        _castSpent ||
        state.availableResource(session.baitId) < 1 ||
        !state.toolUsable(session.rodId)) {
      return false;
    }
    // Freeze species and size once. Reloads cannot reroll a cast.
    session.catchRecord = FishCatch.draw(
      _random,
      bait: session.baitId,
      rod: session.rodId,
      day: state.day,
    );
    if (!session.cast()) return false;
    _apply(EventEffect(resources: {session.baitId: -1}));
    _wearTool(session.rodId, 1);
    _castSpent = true;
    _changed();
    return true;
  }

  bool finishFishing({bool abandon = false, bool release = false}) {
    final session = _fishing;
    if (session == null || _fishingBefore == null) return false;
    if (abandon && session.stage != FishingStage.caught) session.abandon();
    if (!session.complete) return false;
    final before = _fishingBefore!;
    final caught = session.quality != CatchQuality.missed && _castSpent;
    final record = caught ? session.catchRecord : null;
    // Legacy interrupted sessions may lack a species record.
    final speciesId = record?.speciesId ?? 'small_fish';
    final count = caught ? 1 : 0;
    if (caught) {
      metrics.fishCaught++;
      if (metrics.fishSpecies.add(speciesId)) {
        metrics.note(
          state.day,
          state.locationId,
          'Caught ${itemName(speciesId)}',
          speciesId,
        );
      }
      if (!release) {
        _pendingFishId = speciesId;
        _pendingFishBaseline = before.packResources[speciesId] ?? 0;
      }
      if (!release) _apply(EventEffect(resources: {speciesId: count}));
      _state = state.copyWith(knownFish: {...state.knownFish, speciesId});
    }
    _state = state.copyWith(
      worldFlags: {...state.worldFlags}
        ..remove('trail_marker')
        ..remove('storm_crossing'),
    );
    _fishing = null;
    _fishingBefore = null;
    final baitSpent = _castSpent;
    _castSpent = false;
    _finish(
      caught
          ? release
                ? 'Catch released'
                : session.quality == CatchQuality.perfect
                ? 'A perfect catch'
                : 'Fresh from the pond'
          : 'Back from the pond',
      caught
          ? '${record?.species.name ?? 'Stream Silverfish'}${record == null ? '' : ' · ${record.lengthCm} cm · ${record.weightLabel}'}. ${release ? 'You release the fish alive.' : 'You keep the fish. Prepare it from Items at camp.'}'
          : baitSpent
          ? 'The fish slipped away. Your bait is gone, but you made it home.'
          : 'You return without casting. The journey still used daylight and supplies.',
      before,
      catchRecord: record,
    );
    return true;
  }

  String? prepareFishBlockReason(String id) {
    if (!fishSpecies.containsKey(id)) return 'Unknown fish';
    if (!canAct(CampAction.rest) || state.locationId != 'camp') {
      return 'Prepare at camp in daylight';
    }
    if (state.availableResource(id) < 1) return 'No raw fish available';
    if (state.availableResource('wood') < 1) return 'Need 1 wood';
    if (fishSpecies[id]!.requiresKnife &&
        !state.toolUsable('stone_knife') &&
        !state.toolUsable('machete')) {
      return 'Knife required';
    }
    return null;
  }

  bool prepareFish(String id) {
    if (prepareFishBlockReason(id) != null) return false;
    final before = state;
    _apply(EventEffect(resources: {id: -1, 'wood': -1}));
    _spendTime(1, outdoor: false);
    if (state.isAlive) {
      _apply(EventEffect(resources: {fishSpecies[id]!.preparedId: 1}));
    }
    _finish(
      state.isAlive
          ? 'Fish prepared: ${fishSpecies[id]!.name}'
          : 'An unfinished meal',
      state.isAlive
          ? 'You clean and cook the fish safely. The prepared portion is stored in Items, ready to eat.'
          : 'Your strength gives out before the meal is ready.',
      before,
    );
    return true;
  }

  String? gatheringTool(GatheringKind kind) => kind == GatheringKind.foraging
      ? null
      : state.activeFieldTool(kind == GatheringKind.chopping ? 'axe' : 'spear');

  bool equipFieldTool(String id) {
    final tool = fieldTools[id];
    final choosing = _gathering?.stage == GatheringStage.ready;
    if (tool == null ||
        !state.toolUsable(id) ||
        !state.isAlive ||
        state.phase != RunPhase.day ||
        (!choosing && (isBusy || state.locationId != 'camp'))) {
      return false;
    }
    _state = tool.family == 'axe'
        ? state.copyWith(equippedAxe: id)
        : state.copyWith(equippedSpear: id);
    _changed();
    return true;
  }

  Map<String, int> craftCosts(String id) =>
      canRepairTool(id) && fieldTools.containsKey(id)
      ? fieldTools[id]!.repairs
      : recipes.find(id)?.costs ?? const {};

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
    if (kind != GatheringKind.foraging && !state.satisfiesTool(kind.art)) {
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
    _gathering = GatheringSession(
      kind,
      random: _random,
      day: state.day,
      ecology: true,
      windowScale: state.timingScale,
    );
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
    if (session.kind != GatheringKind.foraging) {
      final toolId = gatheringTool(session.kind)!;
      session.toolId = toolId;
      session.goodScale = fieldTools[toolId]!.goodScale;
      final tool = fieldTools[toolId]!;
      _state = tool.family == 'axe'
          ? state.copyWith(equippedAxe: toolId)
          : state.copyWith(equippedSpear: toolId);
    }
    session.start();
    if (session.kind != GatheringKind.foraging) _addStrain(1);
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
    if (!(_gathering?.pick(id, state.availableTools) ?? false)) return false;
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
    if (_gatheringSource?.trigger == 'encounter' && state.isAlive) {
      metrics.encounters++;
      metrics.encounterTypes.add(_gatheringSource!.id);
    }
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
          final tier = fieldTools[session.toolId]?.tier ?? 0;
          if (wood > 0) resources['wood'] = wood + tier;
          final perfectHits = session.hits
              .where((h) => h == TimingQuality.perfect)
              .length;
          if (perfectHits >= 2) {
            resources['hardwood'] =
                (perfectHits == 3 ? 2 : 1) + (tier == 2 ? 1 : 0);
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
            if (session.ecology && jungleFoods.containsKey(plant)) {
              resources[plant] = 1;
              continue;
            }
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
        final tool = session.toolId ?? session.kind.art;
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
    if (!state.isAlive ||
        isBusy ||
        _packingDraft != null ||
        state.locationId != 'camp') {
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
    for (final item in canRepairTool(id) ? <String>{} : recipe.requiresItems) {
      if (!state.tools.contains(item)) {
        return 'Needs ${recipes.find(item)?.name ?? itemName(item)}';
      }
    }
    if (state.value(SurvivalStat.water) < recipe.waterCost) {
      return 'Need ${recipe.waterCost} water for the recipe';
    }
    final missing = [
      for (final e in craftCosts(id).entries)
        if (state.availableResource(e.key) < e.value)
          '${e.value - state.availableResource(e.key)} ${itemName(e.key).toLowerCase()}',
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
        resources: {for (final e in craftCosts(id).entries) e.key: -e.value},
        stats: {SurvivalStat.water: -recipe.waterCost},
      ),
    );
    _spendTime(recipe.timeCost, outdoor: false);
    final upgrade = recipe.kind == RecipeKind.campTier;
    if (state.isAlive) {
      if (!repairing) {
        if (recipe.kind == RecipeKind.tool) tutorial.learn('craft');
        if (!upgrade) {
          metrics.crafted++;
          metrics.recipes.add(id);
        }
        metrics.note(
          state.day,
          'camp',
          '${upgrade ? 'Built' : 'Crafted'} ${recipe.name}',
          upgrade ? 'shelter' : id,
        );
      }
      if (recipe.outputs.isNotEmpty) {
        _apply(EventEffect(resources: recipe.outputs));
      } else {
        _state = upgrade
            ? state.copyWith(campTier: recipe.tier)
            : state.copyWith(tools: {...state.tools, recipe.id});
      }
      if (RunState.toolDurability.containsKey(id)) {
        _state = state.copyWith(
          durability: {...state.durability, id: RunState.toolDurability[id]!},
        );
      }
      if (!repairing && fieldTools.containsKey(id)) {
        final tool = fieldTools[id]!;
        _state = tool.family == 'axe'
            ? state.copyWith(equippedAxe: id)
            : state.copyWith(equippedSpear: id);
      }
      if (id == 'trail_backpack' || id == 'expedition_pack') {
        _state = state.copyWith(packTier: id == 'trail_backpack' ? 1 : 2);
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
  static const consumables = {
    'redfin_perch',
    'mud_whisker',
    'spiny_sunlurker',
    'goldspot_riverfish',
    'prepared_small_fish',
    'prepared_redfin_perch',
    'prepared_mud_whisker',
    'prepared_spiny_sunlurker',
    'prepared_goldspot_riverfish',
    'small_fish',
    'raw_meat',
    'herb',
    'ember_berries',
    'dew_fruit',
    'canopy_fig',
    'iron_nut',
    'wild_honey',
    'ribbon_root',
    'wax_berries',
    'mooncap',
    'cooked_root',
    'antidote',
    'bandage',
  };

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
    'antidote' => EventEffect(resources: {'antidote': -1}),
    'bandage' => EventEffect(
      stats: {SurvivalStat.health: 4},
      resources: {'bandage': -1},
    ),
    _ when fishSpecies.containsKey(id) => EventEffect(
      stats: {
        SurvivalStat.food: fishSpecies[id]!.hazardous
            ? 8
            : fishSpecies[id]!.food + recipes.bonus(state, CampBonus.fishFood),
      },
      resources: {id: -1},
      conditions: [
        if (fishSpecies[id]!.hazardous)
          SurvivalCondition(
            ConditionKind.poisoned,
            4,
            severity: fishSpecies[id]!.poison,
          ),
      ],
    ),
    _ when preparedFishSource(id) != null => EventEffect(
      stats: {
        SurvivalStat.food:
            fishSpecies[preparedFishSource(id)]!.food +
            recipes.bonus(state, CampBonus.fishFood),
      },
      resources: {id: -1},
    ),
    _ when jungleFoods.containsKey(id) => EventEffect(
      stats: jungleFoods[id]!.nutrition,
      resources: {id: -1},
      conditions: [
        if (jungleFoods[id]!.poison > 0)
          SurvivalCondition(
            ConditionKind.poisoned,
            4,
            severity: jungleFoods[id]!.poison,
          ),
      ],
    ),
    _ => throw ArgumentError.value(id, 'id', 'Not a consumable'),
  };

  bool canConsume(String id) {
    if (!consumables.contains(id) ||
        !state.isAlive ||
        state.rescued ||
        !canUseSupplies ||
        state.availableResource(id) < 1) {
      return false;
    }
    if (state.locationId != 'camp' &&
        (fishSpecies.containsKey(id) || {'raw_meat', 'herb'}.contains(id))) {
      return false;
    }
    if (id == 'antidote') return state.hasCondition(ConditionKind.poisoned);
    if (id == 'bandage') return state.hasCondition(ConditionKind.injured);
    if (jungleFoods[id]?.requiresKnife ?? false) {
      if (state.locationId != 'camp' ||
          !(state.toolUsable('stone_knife') || state.toolUsable('machete'))) {
        return false;
      }
    }
    // Only worth using while at least one restored stat is below full.
    return consumeEffect(id).stats.entries.any(
      (e) =>
          e.value > 0 &&
          state.value(e.key) < 100 &&
          !(e.key == SurvivalStat.health &&
              state.hasCondition(ConditionKind.poisoned)),
    );
  }

  bool consume(String id) {
    if (!canConsume(id)) return false;
    final before = state;
    if (id == 'antidote') _removeCondition(ConditionKind.poisoned);
    if (id == 'bandage') _removeCondition(ConditionKind.injured);
    if (jungleFoods.containsKey(id)) {
      _state = state.copyWith(knownSpecies: {...state.knownSpecies, id});
    }
    final source = fishSpecies.containsKey(id) ? id : preparedFishSource(id);
    if (source != null) {
      _state = state.copyWith(knownFish: {...state.knownFish, source});
    }
    final meal = consumeEffect(id);
    if ((meal.stats[SurvivalStat.food] ?? 0) > 0 &&
        (jungleFoods[id]?.poison ?? 0) == 0 &&
        !(fishSpecies[id]?.hazardous ?? false)) {
      tutorial.learn('eat');
    }
    _apply(meal);
    _finish(
      id == 'herb'
          ? 'Herbal tea'
          : id == 'antidote'
          ? 'Poison treated'
          : id == 'bandage'
          ? 'Injury treated'
          : 'A meal beneath the canopy',
      switch (id) {
        'antidote' =>
          'The poison is cleared. Lost health must recover separately.',
        'bandage' => 'You dress the wound. The injury is cleared.',
        _ when jungleFoods.containsKey(id) =>
          'You eat one portion of ${jungleFoods[id]!.name.toLowerCase()}. ${jungleFoods[id]!.description}',
        _ when fishSpecies.containsKey(id) =>
          '${fishSpecies[id]!.name}: ${fishSpecies[id]!.hazardous ? 'You ate the fish without safe preparation. Poison takes hold.' : 'You cook and eat the fish.'}',
        _ when preparedFishSource(id) != null =>
          'You eat a safely prepared portion of fish.',
        'small_fish' =>
          'You cook one small fish over the campfire and eat it. No daylight spent.',
        'raw_meat' =>
          'You roast the meat until the fat spits and eat it. No daylight spent.',
        _ =>
          'You steep the herbs in hot water. Warmth spreads through your body.',
      },
      before,
    );
    return true;
  }

  bool get canUseSupplies =>
      state.isAlive &&
      !state.rescued &&
      state.rescueStage != RescueStage.storm &&
      !hasPendingHaul &&
      _packingDraft == null &&
      _pendingEvent == null &&
      _report == null &&
      _fishing == null &&
      _ruinsPuzzle == null &&
      _gathering == null &&
      (state.locationId == 'camp' || _decisionPending);

  bool studySpecies(String id) {
    if (!jungleFoods.containsKey(id) ||
        state.knownSpecies.contains(id) ||
        !canUseSupplies ||
        state.locationId != 'camp' ||
        state.phase != RunPhase.day ||
        state.timeLeft < 1 ||
        state.availableResource(id) < 1) {
      return false;
    }
    final before = state;
    _apply(EventEffect(resources: {id: -1}));
    _spendTime(1, outdoor: false);
    if (state.isAlive) {
      _state = state.copyWith(knownSpecies: {...state.knownSpecies, id});
    }
    _finish(
      state.isAlive
          ? 'Species studied: ${jungleFoods[id]!.name}'
          : 'An unfinished study',
      state.isAlive
          ? jungleFoods[id]!.description
          : 'Your strength gives out before the study is complete.',
      before,
    );
    return true;
  }

  bool chewHerbs() {
    final poison = state.condition(ConditionKind.poisoned);
    if (!canUseSupplies ||
        state.availableResource('herb') < 1 ||
        poison == null ||
        poison.remaining <= 1) {
      return false;
    }
    final before = state;
    _apply(EventEffect(resources: {'herb': -1}));
    _shortenCondition(ConditionKind.poisoned, min(2, poison.remaining - 1));
    _finish(
      'Bitter leaf first aid',
      'The poison is weakened, but not cured. No daylight spent.',
      before,
    );
    return true;
  }

  bool dryByFire() {
    if (!canAct(CampAction.rest) ||
        state.locationId != 'camp' ||
        state.availableResource('wood') < 1 ||
        !state.hasCondition(ConditionKind.wet)) {
      return false;
    }
    final before = state;
    _removeCondition(ConditionKind.wet);
    _state = state.copyWith(exposure: 0);
    _apply(EventEffect(resources: {'wood': -1}));
    _spendTime(1, outdoor: false);
    _finish('Dry by the fire', 'Your clothes are dry again.', before);
    return true;
  }

  bool prepareRoots() {
    if (!canAct(CampAction.rest) ||
        state.locationId != 'camp' ||
        state.availableResource('wood') < 1 ||
        state.availableResource('ribbon_root') < 1) {
      return false;
    }
    final before = state;
    final portions = min(3, state.availableResource('ribbon_root'));
    _apply(EventEffect(resources: {'wood': -1, 'ribbon_root': -portions}));
    _spendTime(1, outdoor: false);
    if (state.isAlive) {
      _apply(EventEffect(resources: {'cooked_root': portions}));
      _state = state.copyWith(
        knownSpecies: {...state.knownSpecies, 'ribbon_root', 'cooked_root'},
      );
    }
    _finish(
      state.isAlive ? 'Roots prepared' : 'An unfinished meal',
      state.isAlive
          ? 'You carefully prepare the roots over the fire. They are now safe to eat.'
          : 'Your strength gives out before the roots are ready.',
      before,
    );
    return true;
  }

  double chanceFor(EventChoice choice) {
    if (!choice.isRisky) return 1;
    final penalty = choice.riskDomain == 'physical'
        ? min(.25, state.physicalPenalty)
        : 0;
    final weather =
        state.worldFlags.contains('storm_crossing') &&
            _pendingEvent?.id == 'ecology_crossing'
        ? 'Storm'
        : state.weather;
    final base = choice.weatherChances[weather] ?? choice.successChance;
    final spearAction =
        choice.riskDomain == 'physical' &&
        choice.requiresTools.contains('stone_spear');
    final bonus = spearAction
        ? fieldTools[state.activeFieldTool('spear')]?.chanceBonus ?? 0
        : 0;
    return (base +
            bonus -
            penalty -
            (state.value(SurvivalStat.sanity) < 25 ? .15 : 0))
        .clamp(.1, spearAction ? .9 : .95);
  }

  bool canChoose(EventChoice choice) =>
      state.isAlive &&
      (_pendingEvent?.choices.contains(choice) ?? false) &&
      choice.isVisible(state) &&
      !choice.effect.flags.any(
        (flag) => flag == 'trail_marker' && state.worldFlags.contains(flag),
      ) &&
      (choice.extraTime == 0 ||
          state.timeLeft >= _pendingCost + choice.extraTime) &&
      choice.requires.entries.every(
        (r) => state.availableResource(r.key) >= r.value,
      ) &&
      choice.requiresTools.every(state.satisfiesTool) &&
      choice.consumesTools.every(state.toolUsable) &&
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
      _gathering = GatheringSession(
        gatheringKind,
        random: _random,
        day: state.day,
        ecology: true,
        windowScale: state.timingScale,
      );
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
    final usedTools = choice.requiresTools
        .map(state.resolveTool)
        .whereType<String>()
        .toSet();
    final rescueTrial = _pendingEvent!.trigger == 'rescue';
    final encounterId = _pendingEvent!.trigger == 'encounter'
        ? _pendingEvent!.id
        : null;
    final success = !choice.isRisky || _random.nextDouble() < chanceFor(choice);
    final eventTitle = _pendingEvent!.title;
    final protected =
        state.worldFlags.contains('trail_marker') &&
        _pendingEvent!.id.contains('lost');
    var effect = protected
        ? EventEffect()
        : success
        ? choice.effect
        : choice.failureEffect!;
    if (success &&
        usedTools.any((id) => fieldTools[id]?.family == 'axe') &&
        (effect.resources['wood'] ?? 0) > 0) {
      final tier = usedTools
          .map((id) => fieldTools[id]?.tier ?? 0)
          .fold(0, max);
      effect = EventEffect(
        stats: effect.stats,
        resources: {
          ...effect.resources,
          'wood': effect.resources['wood']! + tier,
        },
        flags: effect.flags,
        conditions: effect.conditions,
        dropLoot: effect.dropLoot,
        endsExpedition: effect.endsExpedition,
        physicalDamage: effect.physicalDamage,
      );
    }
    if (protected || _pendingEvent!.id == 'ecology_crossing') {
      _state = state.copyWith(
        worldFlags: {...state.worldFlags}
          ..remove(protected ? 'trail_marker' : 'storm_crossing'),
      );
    }
    // Pay supplies first, then advance time, then resolve the outcome. An
    // event reward must not revive a survivor who died reaching it.
    _apply(
      EventEffect(
        resources: {
          for (final e in effect.resources.entries)
            if (e.value < 0) e.key: e.value,
        },
      ),
    );
    if (_pendingCost + choice.extraTime > 0) {
      if (_pendingCost > 0) _spendTime(_pendingCost);
      if (choice.extraTime > 0 && state.isAlive) {
        _spendTime(choice.extraTime, outdoor: !choice.sheltered);
      }
    }
    if (state.isAlive) {
      _apply(
        EventEffect(
          stats: effect.stats,
          resources: {
            for (final e in effect.resources.entries)
              if (e.value > 0) e.key: e.value,
          },
          physicalDamage: effect.physicalDamage,
        ),
        source: encounterId == null ? 'event' : 'encounter:$encounterId',
      );
    }
    if (encounterId != null && state.isAlive) {
      metrics.encounters++;
      if (metrics.encounterTypes.add(encounterId)) {
        metrics.note(
          state.day,
          before.locationId,
          'Resolved $eventTitle',
          'stone_spear',
        );
      }
    }
    _state = state.copyWith(
      tools: {...state.tools}..removeAll(choice.consumesTools),
    );
    final wearNotes = [
      for (final tool in usedTools)
        if (RunState.toolDurability.containsKey(tool)) _wearTool(tool, 1),
    ];
    final trip = _expedition;
    if (trip != null) {
      for (final e in effect.resources.entries) {
        if (e.value > 0 && state.isAlive) {
          trip.loot[e.key] = (trip.loot[e.key] ?? 0) + e.value;
        }
      }
      if (effect.dropLoot) {
        final lost = state.legacyPack
            ? {
                for (final e in trip.loot.entries)
                  e.key: min(e.value, state.packResources[e.key] ?? 0),
              }
            : Map<String, int>.of(state.packResources);
        _apply(
          EventEffect(
            resources: {for (final e in lost.entries) e.key: -e.value},
          ),
        );
        trip.loot.clear();
      }
      if (effect.endsExpedition) {
        _expedition = null;
        _followUp = false;
      }
    }
    if (state.isAlive && (effect.stats[SurvivalStat.water] ?? 0) > 0) {
      final filtered = recipes.bonus(state, CampBonus.waterGain);
      if (filtered > 0) {
        _apply(EventEffect(stats: {SurvivalStat.water: filtered}));
      }
    }

    if (state.isAlive) {
      _state = state.copyWith(
        worldFlags: {...state.worldFlags, ...effect.flags},
      );
      for (final condition in effect.conditions) {
        _addCondition(condition);
      }
    }
    if (rescueTrial && state.isAlive) {
      _state = state.copyWith(rescueStep: state.rescueStep + 1);
      metrics.stormSteps = state.rescueStep;
      metrics.note(
        state.day,
        'camp',
        'Survived storm challenge ${state.rescueStep}',
        'shelter',
      );
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
      [
        !state.isAlive
            ? 'Your strength gives out before you can complete the action.'
            : protected
            ? 'Your trail marker guides you back to the route.'
            : success
            ? choice.result
            : choice.failureResult!,
        ...wearNotes,
      ].join(' '),
      before,
    );
    if (choice.requiresTools.contains('stone_axe') &&
        (effect.resources['wood'] ?? 0) > 0) {
      _sound(GameSound.woodChop);
    }
    return true;
  }

  bool continueFromReport() {
    if (_report == null || hasPendingHaul) return false;
    _report = null;
    if (state.rescued || !state.isAlive) {
      _unloadPack();
      _state = state.copyWith(
        locationId: 'camp',
        worldFlags: {...state.worldFlags}
          ..remove('trail_marker')
          ..remove('storm_crossing'),
      );
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
    _unloadPack();
    _state = state.copyWith(
      locationId: 'camp',
      worldFlags: {...state.worldFlags}
        ..remove('trail_marker')
        ..remove('storm_crossing'),
    );
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
      !hasPendingHaul &&
      !(state.legacyPack && state.usedPackSlots > state.packCapacity) &&
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
    _addStrain(1);
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
    if (!_decisionPending || hasPendingHaul) return false;
    final trip = _expedition!;
    final before = state;
    _decisionPending = false;
    _expedition = null;
    _followUp = false;
    _unloadPack();
    _state = state.copyWith(
      locationId: 'camp',
      worldFlags: {...state.worldFlags}
        ..remove('trail_marker')
        ..remove('storm_crossing'),
    );
    _state = state.copyWith(
      worldFlags: {...state.worldFlags}
        ..remove('trail_marker')
        ..remove('storm_crossing'),
    );
    final haul = positiveItems(trip.loot);
    _report = ActionReport.saved(
      title: haul.isEmpty ? 'Back at camp' : 'Home with the haul',
      body: haul.isEmpty
          ? 'You walk back along the trail with nothing to show for it, but alive.'
          : 'Your new finds are safely stored at camp. Unused supplies were returned too; your backpack is empty.',
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
    if (state.campTier >= 2) _removeCondition(ConditionKind.wet);
    final poisonedOvernight = state.hasCondition(ConditionKind.poisoned);
    final injuredOvernight = state.hasCondition(ConditionKind.injured);
    for (var i = 0; i < 2 && state.isAlive; i++) {
      _conditionTick();
    }
    _removeCondition(ConditionKind.exhausted);
    _state = state.copyWith(strain: 0);
    _applyDeprivation();
    if (state.isAlive) {
      if (!poisonedOvernight &&
          state.value(SurvivalStat.water) > 0 &&
          state.value(SurvivalStat.food) > 0) {
        _apply(
          EventEffect(
            stats: {
              SurvivalStat.health:
                  ((10 + recipes.bonus(state, CampBonus.sleepHealth)) /
                          (injuredOvernight &&
                                  !state.hasCondition(ConditionKind.injured)
                              ? 2
                              : 1))
                      .floor(),
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
      metrics.nights++;
      tutorial.learn('night');
      _state = state.copyWith(
        day: state.day + 1,
        timeLeft: RunState.dayLength,
        phase: RunPhase.day,
        weather: _nextWeather(),
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

  int get heldBeaconComponents => beaconComponents.keys
      .where((id) => state.availableResource(id) > 0)
      .length;

  String? get activateBeaconBlockReason {
    if (!state.tools.contains('emergency_beacon')) {
      return 'Assemble the Emergency Beacon first';
    }
    if (state.rescueStage != RescueStage.searching || state.rescued) {
      return 'Signal already sent';
    }
    if (!state.isAlive ||
        isBusy ||
        _packingDraft != null ||
        state.locationId != 'camp') {
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
    if (!canStartNewRun) return;
    ensureRunSummary(outcome: completedRun == null ? 'abandoned' : null);
    final option = optionById(profile.nextOption);
    profile.firstRunGuideHandled = true;
    tutorial = TutorialProgress();
    metrics = RunMetrics(option: option.id);
    completedRun = null;
    rankNoticePending = false;
    _pendingFishId = null;
    _state = RunState(
      resources: {'wood': 2, 'stone': 0, 'fiber': 0, 'herb': 2},
    );
    _state = state.copyWith(
      resources: {
        ...state.resources,
        for (final e in option.items.entries)
          e.key: state.resource(e.key) + e.value,
      },
      stats: {
        ...state.stats,
        SurvivalStat.food: state.value(SurvivalStat.food) + option.food,
      },
    );
    _packingDraft = null;
    _haulSelection = null;
    _lastPack = {};
    _lastPackSaved = false;
    _lastGear = null;
    _returnAfterHaul = false;
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
      ..add(
        'Day 1 · You found a clearing and 2 medicinal herbs. Gathering stores food: use Items to study, prepare or eat it.',
      );
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
    final opener = switch ((trigger, locationId)) {
      ('forage', null) => 'berry_patch',
      ('explore', 'riverbank') when depth == 0 => 'river_supplies',
      ('night', null) => 'fire_dying',
      _ => null,
    };
    if (tutorial.active &&
        opener != null &&
        !tutorial.openers.contains(opener)) {
      final matches = pool.where((e) => e.id == opener);
      if (matches.isNotEmpty) {
        tutorial.openers.add(opener);
        _lastEvent[trigger] = opener;
        return matches.first;
      }
    }
    final priority = pool.fold<int>(0, (p, e) => max(p, e.priority));
    final preferred = pool.where((e) => e.priority == priority).toList();
    final fresh = preferred.where((e) => e.id != _lastEvent[trigger]).toList();
    final candidates = fresh.isEmpty ? preferred : fresh;
    double weight(GameEvent event) => state.weather == 'Sunny'
        ? 1
        : event.id == 'ecology_dew'
        ? 1.5
        : ['ecology_nuts', 'ecology_hive'].contains(event.id)
        ? .5
        : 1;
    GameEvent event;
    if (candidates.every((candidate) => weight(candidate) == 1)) {
      event = candidates[_random.nextInt(candidates.length)];
    } else {
      var draw =
          _random.nextDouble() *
          candidates.fold<double>(0, (total, event) => total + weight(event));
      event = candidates.last;
      for (final candidate in candidates) {
        draw -= weight(candidate);
        if (draw < 0) {
          event = candidate;
          break;
        }
      }
    }
    _lastEvent[trigger] = event.id;
    return event;
  }

  String _nextWeather() {
    final roll = _random.nextDouble();
    if (state.weather == 'Storm') return roll < 2 / 3 ? 'Sunny' : 'Light rain';
    if (state.day + 1 <= 3) return roll < .7 ? 'Sunny' : 'Light rain';
    return roll < .6
        ? 'Sunny'
        : roll < .9
        ? 'Light rain'
        : 'Storm';
  }

  void _removeCondition(ConditionKind kind) => _state = state.copyWith(
    conditions: [
      for (final c in state.conditions)
        if (c.kind != kind) c,
    ],
  );
  void _shortenCondition(ConditionKind kind, int amount) =>
      _state = state.copyWith(
        conditions: [
          for (final c in state.conditions)
            if (c.kind != kind)
              c
            else if (c.remaining > amount)
              c.withRemaining(c.remaining - amount),
        ],
      );
  void _addCondition(SurvivalCondition condition) {
    final old = state.condition(condition.kind);
    _removeCondition(condition.kind);
    _state = state.copyWith(
      conditions: [
        ...state.conditions,
        SurvivalCondition(
          condition.kind,
          max(condition.remaining, old?.remaining ?? 0),
          severity: max(condition.severity, old?.severity ?? 1),
        ),
      ],
    );
  }

  void _addStrain(int amount) {
    final strain = state.strain + amount;
    _state = state.copyWith(strain: strain >= 6 ? 0 : strain);
    if (strain >= 6) {
      _addCondition(const SurvivalCondition(ConditionKind.exhausted, 4));
    }
  }

  void _conditionTick({bool daytime = false}) {
    final poison = state.condition(ConditionKind.poisoned)?.severity ?? 0;
    final wet = state.hasCondition(ConditionKind.wet) ? 1 : 0;
    final tired = state.hasCondition(ConditionKind.exhausted) ? 1 : 0;
    _apply(
      EventEffect(
        stats: {
          SurvivalStat.health: -2 * poison,
          SurvivalStat.water: -(daytime ? 4 : 0) - min(4, poison + tired),
          SurvivalStat.food: -(daytime ? 3 : 0) - min(3, wet + tired),
          SurvivalStat.sanity: -min(2, wet),
        },
      ),
      source: 'poisoned:$poison',
    );
    if (daytime) _applyDeprivation();
    _state = state.copyWith(
      conditions: [
        for (final c in state.conditions)
          if (c.remaining > 1) c.withRemaining(c.remaining - 1),
      ],
    );
  }

  void _spendTime(int cost, {bool outdoor = true}) {
    _state = state.copyWith(timeLeft: max(0, state.timeLeft - cost));
    for (var tick = 0; tick < cost && state.isAlive; tick++) {
      final wasWet = state.hasCondition(ConditionKind.wet);
      _conditionTick(daytime: true);
      if (!state.isAlive) break;
      final rain = outdoor && state.weather != 'Sunny';
      final delta = rain
          ? (state.weather == 'Storm' ? 3 : 2) -
                (state.availableTools.contains('leaf_rain_cape') ? 1 : 0)
          : -2;
      final exposure = max(0, state.exposure + delta);
      _state = state.copyWith(exposure: exposure >= 6 ? 0 : exposure);
      if (exposure >= 6 || (wasWet && rain)) {
        _addCondition(const SurvivalCondition(ConditionKind.wet, 3));
      }
      _addStrain(
        (outdoor ? 1 : 0) +
            (state.value(SurvivalStat.water) <= 15 ||
                    state.value(SurvivalStat.food) <= 15
                ? 1
                : 0),
      );
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
    source: 'deprivation',
  );

  void _apply(EventEffect effect, {String source = 'action'}) {
    final stats = {...state.stats};
    final resources = {...state.resources};
    final carried = {...state.packResources};
    for (final entry in effect.stats.entries) {
      var delta = entry.value;
      if (entry.key == SurvivalStat.health) {
        if (delta > 0 && state.hasCondition(ConditionKind.poisoned)) {
          delta = 0;
        } else if (delta > 0 && state.hasCondition(ConditionKind.injured)) {
          delta = delta ~/ 2;
        } else if (delta < 0 &&
            effect.physicalDamage &&
            state.hasCondition(ConditionKind.injured)) {
          delta = -(delta.abs() * 1.2).ceil();
        }
      }
      stats[entry.key] = (state.value(entry.key) + delta).clamp(0, 100);
      if (entry.key == SurvivalStat.health &&
          state.isAlive &&
          stats[entry.key] == 0 &&
          metrics.fatalCause == null) {
        metrics.fatalCause = source;
        metrics.fatalLocation = state.locationId;
        metrics.contributing = state.conditions
            .where(
              (c) =>
                  !source.startsWith('poisoned:') ||
                  c.kind != ConditionKind.poisoned,
            )
            .take(2)
            .map((c) => c.label)
            .toList();
      }
    }
    for (final entry in effect.resources.entries) {
      final delta = state.inField && entry.value < 0
          ? -min(-entry.value, state.packResources[entry.key] ?? 0)
          : entry.value;
      resources[entry.key] = max(0, state.resource(entry.key) + delta);
      if (state.inField) {
        carried[entry.key] = max(0, (carried[entry.key] ?? 0) + delta);
        if (delta < 0 && _expedition != null) {
          _expedition!.loot[entry.key] = max(
            0,
            (_expedition!.loot[entry.key] ?? 0) + delta,
          );
        }
      }
    }
    _expedition?.loot.removeWhere((id, n) => n <= 0);
    _state = state.copyWith(
      stats: stats,
      resources: resources,
      packResources: state.inField
          ? positiveItems(carried)
          : state.packResources,
      foundComponents: {
        ...state.foundComponents,
        for (final entry in effect.resources.entries)
          if (entry.value > 0 && beaconComponents.containsKey(entry.key))
            entry.key,
      },
    );
    if (state.isAlive) {
      for (final condition in effect.conditions) {
        _addCondition(condition);
      }
    }
  }

  void _finish(
    String title,
    String body,
    RunState before, {
    DaySummary? daySummary,
    FishCatch? catchRecord,
  }) {
    if (state.isAlive &&
        <String>{
          ...jungleFoods.keys.where((id) => id != 'cooked_root'),
          ...fishSpecies.keys,
          'small_fish',
          'raw_meat',
        }.any((id) => state.resource(id) > before.resource(id))) {
      tutorial.learn('gather');
    }
    if (!state.isAlive) {
      _state = state.copyWith(phase: RunPhase.gameOver);
      _expedition = null;
      _decisionPending = false;
      _followUp = false;
    }
    if (before.exposure < 3 &&
        state.exposure >= 3 &&
        !state.worldFlags.contains('rain_explained')) {
      body +=
          ' Your clothes are getting soaked. A leaf rain cape slows exposure; a campfire dries wet clothes.';
      _state = state.copyWith(
        worldFlags: {...state.worldFlags, 'rain_explained'},
      );
    }
    final firstConditions = state.conditions
        .where((c) => !state.worldFlags.contains('learned_${c.kind.name}'))
        .toList();
    if (firstConditions.isNotEmpty) {
      body = [
        body,
        for (final c in firstConditions) '${c.label}: ${c.description}',
      ].join(' ');
      _state = state.copyWith(
        worldFlags: {
          ...state.worldFlags,
          for (final c in firstConditions) 'learned_${c.kind.name}',
        },
      );
    }
    if (state.inField &&
        state.isAlive &&
        !state.legacyPack &&
        state.usedPackSlots > state.packCapacity) {
      final incoming = {
        for (final e in state.packResources.entries)
          if (e.value > (before.packResources[e.key] ?? 0))
            e.key: e.value - (before.packResources[e.key] ?? 0),
      };
      if (incoming.isNotEmpty) {
        _state = state.copyWith(
          pendingResources: incoming,
          packResources: positiveItems({
            for (final e in state.packResources.entries)
              e.key: e.value - (incoming[e.key] ?? 0),
          }),
        );
      }
    }
    if (state.inField &&
        _expedition == null &&
        _fishing == null &&
        _gathering == null &&
        _ruinsPuzzle == null) {
      if (hasPendingHaul) {
        _returnAfterHaul = true;
      } else {
        _unloadPack();
      }
    }
    // Every resolved action is summarized, including the choice that ends a run.
    _report = ActionReport(
      title: title,
      body: body,
      before: before,
      after: state,
      daySummary: daySummary,
      catchRecord: catchRecord,
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
    metrics.campTier = max(metrics.campTier, state.campTier);
    _recordHomeSupplies();
    ensureRunSummary();
    onChanged?.call();
    unawaited(_persist());
    _notify();
  }

  static const saveVersion = 3;

  Map<String, dynamic> toJson() => {
    'version': saveVersion,
    'metrics': metrics.toJson(),
    'profile': profile.toJson(),
    'tutorial': tutorial.toJson(),
    'completedRun': completedRun?.toJson(),
    'rankNoticePending': rankNoticePending,
    'pendingFishId': _pendingFishId,
    'pendingFishBaseline': _pendingFishBaseline,
    'packingDraft': _packingDraft?.toJson(),
    'lastPack': _lastPack,
    'lastPackSaved': _lastPackSaved,
    'lastGear': _lastGear?.toList(),
    'returnAfterHaul': _returnAfterHaul,
    'haulSelection': _haulSelection,
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
      'fishing': {
        'before': _fishingBefore!.toJson(),
        'castSpent': _castSpent,
        'zoneScale': _fishing!.zoneScale,
        'session': _fishing!.toJson(),
      },
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
    final checkpoint = jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>;
    if (_restore(json)) return true;
    _restore(checkpoint);
    return false;
  }

  bool _restore(Map<String, dynamic> json) {
    try {
      if (!{1, 2, saveVersion}.contains(json['version'])) return false;
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

      if (restored.resources.values.any((n) => n < 0) ||
          restored.packResources.entries.any(
            (e) =>
                e.value < 0 ||
                e.value + (restored.pendingResources[e.key] ?? 0) >
                    restored.resource(e.key),
          ) ||
          restored.pendingResources.entries.any(
            (e) =>
                e.value < 0 ||
                e.value + (restored.packResources[e.key] ?? 0) >
                    restored.resource(e.key),
          )) {
        throw const FormatException('Invalid inventory allocation');
      }
      final restoredMetrics = json['metrics'] == null
          ? (RunMetrics(
              partialSince: restored.day,
              legacyEnded:
                  restored.rescued ||
                  !restored.isAlive ||
                  restored.phase == RunPhase.gameOver,
            )..campTier = restored.campTier)
          : RunMetrics.fromJson(
              Map<String, dynamic>.from(json['metrics'] as Map),
            );
      final restoredProfile = json['profile'] == null
          ? PlayerProfile()
          : PlayerProfile.fromJson(
              Map<String, dynamic>.from(json['profile'] as Map),
            );
      final restoredSummary = json['completedRun'] == null
          ? null
          : RunSummary.fromJson(
              Map<String, dynamic>.from(json['completedRun'] as Map),
            );
      if (restoredSummary != null && restoredSummary.id != restoredMetrics.id) {
        throw const FormatException('Mismatched journey summary');
      }
      _state = restored;
      metrics = restoredMetrics;
      profile = restoredProfile;
      tutorial = json['tutorial'] == null
          ? TutorialProgress()
          : TutorialProgress.fromJson(
              Map<String, dynamic>.from(json['tutorial'] as Map),
            );
      if (json['tutorial'] == null) profile.firstRunGuideHandled = true;
      completedRun = restoredSummary;
      rankNoticePending = json['rankNoticePending'] as bool? ?? false;
      _pendingFishId = json['pendingFishId'] as String?;
      _pendingFishBaseline = json['pendingFishBaseline'] as int? ?? 0;
      _packingDraft = json['packingDraft'] == null
          ? null
          : PackingDraft.fromJson(
              Map<String, dynamic>.from(json['packingDraft'] as Map),
            );
      _lastPack = Map<String, int>.from(json['lastPack'] as Map? ?? {});
      _lastPackSaved = json['lastPackSaved'] as bool? ?? _lastPack.isNotEmpty;
      _lastGear = json['lastGear'] == null
          ? null
          : Set<String>.from(json['lastGear'] as List);
      _returnAfterHaul = json['returnAfterHaul'] as bool? ?? false;
      _haulSelection = json['haulSelection'] == null
          ? null
          : Map<String, int>.from(json['haulSelection'] as Map);
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
        _fishing = fishing['session'] == null
            ? FishingSession(
                random: _random,
                zoneScale: (fishing['zoneScale'] as num? ?? 1).toDouble().clamp(
                  .9,
                  1,
                ),
              )
            : FishingSession.fromJson(
                Map<String, dynamic>.from(fishing['session'] as Map),
              );
        // Preserve the old interrupted-cast policy only for legacy saves.
        if (_castSpent && fishing['session'] == null) {
          finishFishing(abandon: true);
        }
      }
      if (_pendingEvent == null &&
          _report == null &&
          _fishing == null &&
          _ruinsPuzzle == null &&
          _gathering == null &&
          _expedition == null &&
          !hasPendingHaul) {
        _unloadPack();
        _state = state.copyWith(
          locationId: 'camp',
          worldFlags: {...state.worldFlags}
            ..remove('trail_marker')
            ..remove('storm_crossing'),
        );
      }
      if (state.rescueStage == RescueStage.storm &&
          !state.rescued &&
          state.isAlive &&
          _pendingEvent == null &&
          _report == null) {
        if (_gathering != null) return true;
        _queueRescueEvent();
      }
      _recordHomeSupplies();
      ensureRunSummary();
      return true;
    } catch (_) {
      return false;
    }
  }
}
