// Fresh-run balance probes. Run from the app directory with dart run.
// Policies are bounded bots, not measured human players or a proof of optimality.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/fishing_session.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/rescue_progress.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';

enum Policy { informed, careful, novice, reckless, idle }

final catalog = EventCatalog.fromJson(
  File('assets/data/events.json').readAsStringSync(),
);
final world = WorldCatalog.fromJson(
  File('assets/data/locations.json').readAsStringSync(),
);
final recipes = RecipeCatalog.fromJson(
  File('assets/data/recipes.json').readAsStringSync(),
);
const builds = [
  'torch',
  'stone_knife',
  'stone_axe',
  'leaf_bed',
  'camp_tier_1',
  'water_filter',
  'rain_collector',
  'camp_tier_2',
  'machete',
  'camp_tier_3',
  'emergency_beacon',
];

GameEngine fresh(Random random) =>
    GameEngine(catalog, world: world, recipes: recipes, random: random);
double gaussian(Random random) =>
    sqrt(-2 * log(max(.000001, random.nextDouble()))) *
    cos(2 * pi * random.nextDouble());

/// Input error is independent of world RNG. Timing uses the visible marker.
void playGathering(GameEngine game, Policy policy, Random input) {
  final session = game.gathering!;
  if (session.stage == GatheringStage.ready) {
    if (!game.beginGathering()) {
      game.cancelGathering();
      return;
    }
    if (game.gathering == null) return;
  }
  if (session.paused) game.pauseGathering(false);
  if (session.kind == GatheringKind.foraging) {
    final plants = ['berries', 'fiber', 'herb'];
    if (policy == Policy.novice || policy == Policy.reckless) {
      plants.shuffle(input);
    }
    if (policy == Policy.reckless) {
      plants.replaceRange(0, 2, ['unknown_plant', 'mushroom']);
    }
    final limit = policy == Policy.novice ? 1 + input.nextInt(3) : 3;
    for (final plant in plants.take(limit)) {
      if (!session.active) break;
      game.tickGathering(policy == Policy.novice ? 1.4 : .5);
      game.pickGatheringPlant(plant);
    }
  } else {
    final period = session.kind == GatheringKind.hunting ? 1.8 : 1.6;
    final sigma = policy == Policy.informed
        ? 0.0
        : policy == Policy.careful
        ? .065
        : .20;
    while (session.active) {
      final target = (period * .25 + gaussian(input) * sigma).clamp(
        .05,
        period * .48,
      );
      var delta = (target - session.elapsed) % period;
      if (delta < session.feedbackLeft) delta += period;
      game.tickGathering(delta);
      if (session.active && !game.strikeGathering()) {
        throw StateError('Rejected simulated strike');
      }
    }
  }
  if (game.gathering != null) game.finishGathering(leave: session.active);
}

Map<String, double> guess(EventChoice choice) {
  final text = choice.label.toLowerCase();
  final result = <String, double>{};
  void hints(List<String> words, String key, double value) {
    if (words.any(text.contains)) result[key] = value;
  }

  hints(['water', 'drink'], 'Water', 26);
  hints(
    ['berries', 'coconut', 'roots', 'seats', 'pocket', 'shoots'],
    'Food',
    16,
  );
  hints(['coconut'], 'Water', 14);
  hints(['wood', 'branch', 'canes', 'driftwood', 'tree'], 'wood', 3);
  hints(
    ['fiber', 'rope', 'vine', 'canes', 'reeds', 'fishing supplies'],
    'fiber',
    3,
  );
  hints(['stone', 'riverbank'], 'stone', 2);
  hints(['herb'], 'herb', 1);
  hints(['hardwood', 'split'], 'hardwood', 2);
  hints(
    ['dashboard', 'cockpit', 'panels', 'wiring', 'crates', 'cache'],
    'metal_scrap',
    2,
  );
  hints(['battery'], 'battery', 1);
  hints(['wire'], 'wire', 1);
  hints(['mount'], 'metal_parts', 1);
  hints(['radio'], 'radio_module', 1);
  hints(['wounds', 'rest'], 'Health', 10);
  if (choice.minigame == 'wood_chopping') {
    result['wood'] = 6;
    result['hardwood'] = .5;
  }
  if (choice.minigame == 'foraging') {
    result['Food'] = 7;
    result['fiber'] = 2;
    result['herb'] = 1;
  }
  if (choice.minigame == 'hunting') result['raw_meat'] = 2;
  return result;
}

class Probe {
  Probe(this.seed, this.policy, {this.restoreEvery = 23})
    : worldRandom = Random(seed),
      input = Random(seed + 91731) {
    game = fresh(worldRandom);
  }
  final int seed, restoreEvery;
  final Policy policy;
  final Random worldRandom, input;
  late GameEngine game;
  final learned = <String, Map<String, double>>{};
  final events = <String, int>{}, operations = <String, int>{};
  final tierDays = <String, int>{};
  int steps = 0, restores = 0, injuryReports = 0, lowSupplySteps = 0;
  int minHealth = 100, minWater = 80, minFood = 75;
  String last = '', blocked = '';
  Map<String, int> needs() {
    final target = builds.firstWhere(
      (id) => !recipes.find(id)!.isOwnedBy(game.state),
      orElse: () => 'emergency_beacon',
    );
    final targetCosts = recipes.find(target)!.costs;
    final repair =
        game.state.tools.contains('stone_axe') &&
        game.state.toolCondition('stone_axe') < 2 &&
        (targetCosts.containsKey('hardwood') ||
            targetCosts.containsKey('wood'));
    final costs = repair ? recipes.find('stone_axe')!.costs : targetCosts;
    return {
      for (final e in costs.entries)
        if (e.value > game.state.resource(e.key))
          e.key: e.value - game.state.resource(e.key),
    };
  }

  double score(EventChoice choice) {
    final event = game.pendingEvent!;
    if (choice.minigame == 'ruins_symbols') return 1000;
    final demand = needs();
    final known = policy == Policy.informed;
    final label = choice.label.toLowerCase();
    if (known && (choice.effect.endsExpedition || choice.effect.dropLoot)) {
      return -1000;
    }
    if (!known &&
        [
          'return',
          'head home',
          'leave it',
          'turn back',
          'run for it',
        ].any(label.contains)) {
      return -200;
    }
    final effect = known
        ? <String, double>{
            for (final e in choice.effect.stats.entries)
              e.key.label: e.value.toDouble(),
            for (final e in choice.effect.resources.entries)
              e.key: e.value.toDouble(),
          }
        : learned['${event.id}/${choice.id}'] ?? guess(choice);
    var value = choice.isRisky
        ? (policy == Policy.reckless ? 15.0 : -45.0)
        : 0.0;
    if (known && choice.minigame != null) {
      effect.addAll(guess(choice));
      if (choice.minigame == 'wood_chopping') {
        effect['wood'] = 9;
        effect['hardwood'] = 2;
      }
    }
    for (final stat in SurvivalStat.values) {
      final current = game.state.value(stat);
      final gain = min(effect[stat.label] ?? 0, 100 - current);
      final weight = stat == SurvivalStat.health
          ? (current < 60 ? 3 : .5)
          : stat == SurvivalStat.water || stat == SurvivalStat.food
          ? (current < 50
                ? 4
                : current < 70
                ? 1.5
                : .3)
          : current < 35
          ? 2
          : .15;
      value += gain * weight;
    }
    for (final e in effect.entries.where(
      (e) => !SurvivalStat.values.any((s) => s.label == e.key),
    )) {
      value +=
          e.value *
          (beaconComponents.containsKey(e.key) &&
                  game.state.resource(e.key) == 0
              ? 150
              : demand.containsKey(e.key)
              ? 10
              : e.key == 'herb'
              ? 4
              : 1);
    }
    // The night/rescue cards expose requirements; safe equipped choices are
    // reasonable without knowledge of exact numerical outcome.
    if (!known &&
        (event.trigger == 'night' || event.trigger == 'rescue') &&
        !choice.isRisky &&
        choice.requiresTools.isNotEmpty) {
      value += 30;
    }
    return value;
  }

  bool act(String operation, bool Function() action) {
    last = operation;
    operations.update(operation, (v) => v + 1, ifAbsent: () => 1);
    if (!action()) {
      blocked = 'Rejected $operation';
      return false;
    }
    return true;
  }

  void check() {
    final state = game.state;
    if (state.timeLeft < 0 ||
        state.timeLeft > 6 ||
        state.resources.values.any((v) => v < 0) ||
        state.stats.values.any((v) => v < 0 || v > 100)) {
      throw StateError('Bounds violated: $seed/$policy');
    }
    minHealth = min(minHealth, state.value(SurvivalStat.health));
    minWater = min(minWater, state.value(SurvivalStat.water));
    minFood = min(minFood, state.value(SurvivalStat.food));
    if (state.value(SurvivalStat.water) < 20 ||
        state.value(SurvivalStat.food) < 20) {
      lowSupplySteps++;
    }
    if (state.campTier > 0) {
      tierDays.putIfAbsent('${state.campTier}', () => state.day);
    }
  }

  Map<String, dynamic> run() {
    while (game.state.isAlive &&
        !game.state.rescued &&
        game.state.day <= 80 &&
        steps < 3500) {
      steps++;
      check();
      if (restoreEvery > 0 && steps % restoreEvery == 0) {
        final snapshot =
            jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;
        final restored = fresh(worldRandom);
        if (!restored.restore(snapshot)) throw StateError('Restore failed');
        final expected =
            jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
        // Restore intentionally clears a redundant pending action when no
        // event is pending, and pauses an active gathering session.
        if (expected['pendingEvent'] == null) expected['pendingAction'] = null;
        final gathering = expected['gathering'] as Map<String, dynamic>?;
        if (gathering?['session']['stage'] == 'active') {
          gathering!['session']['paused'] = true;
        }
        if (jsonEncode(canonical(restored.toJson())) !=
            jsonEncode(canonical(expected))) {
          throw StateError(
            'Restore changed gameplay state: seed=$seed step=$steps',
          );
        }
        game = restored;
        restores++;
      }
      if (game.report != null) {
        if ((game.report!.changes['Health'] ?? 0) < 0) injuryReports++;
        act('continue', game.continueFromReport);
        continue;
      }
      if (game.gathering != null) {
        playGathering(game, policy, input);
        continue;
      }
      if (game.ruinsPuzzle != null) {
        final puzzle = game.ruinsPuzzle!;
        for (var i = 0; i < 3; i++) {
          while (puzzle.tiles[i] != puzzle.pattern[i]) {
            game.turnRuinsTile(i);
          }
        }
        if (policy == Policy.novice && input.nextDouble() < .15) {
          game.turnRuinsTile(0);
        }
        act('puzzle', game.finishRuinsPuzzle);
        continue;
      }
      if (game.pendingEvent != null) {
        final event = game.pendingEvent!;
        events.update(event.id, (v) => v + 1, ifAbsent: () => 1);
        final choices = game.visibleChoices.where(game.canChoose).toList();
        if (choices.isEmpty) {
          blocked = 'No available choice: ${event.id}';
          break;
        }
        choices.sort((a, b) => score(b).compareTo(score(a)));
        final randomChoice = policy == Policy.novice
            ? .12
            : policy == Policy.reckless
            ? .35
            : 0.0;
        final choice = input.nextDouble() < randomChoice
            ? choices[input.nextInt(choices.length)]
            : choices.first;
        final before = game.state;
        if (!act(
          'choice:${event.id}/${choice.id}',
          () => game.choose(choice.id),
        )) {
          break;
        }
        if (game.report != null) {
          learned['${event.id}/${choice.id}'] = {
            for (final stat in SurvivalStat.values)
              stat.label: (game.state.value(stat) - before.value(stat))
                  .toDouble(),
            for (final id in {
              ...game.state.resources.keys,
              ...before.resources.keys,
            })
              id: (game.state.resource(id) - before.resource(id)).toDouble(),
          };
        }
        continue;
      }
      if (game.awaitingExpeditionDecision) {
        final cautious = policy != Policy.reckless;
        final go =
            game.canGoDeeper &&
            (!cautious ||
                (game.state.value(SurvivalStat.water) >= 32 &&
                    game.state.value(SurvivalStat.food) >= 24));
        act(go ? 'deeper' : 'return', go ? game.goDeeper : game.returnHome);
        continue;
      }
      if (game.canSleep) {
        act('sleep', game.sleep);
        continue;
      }
      if (policy == Policy.idle) {
        if (!act('rest', () => game.startAction(CampAction.rest))) break;
        continue;
      }
      final water = game.state.value(SurvivalStat.water),
          food = game.state.value(SurvivalStat.food);
      if (food < 65) {
        final meals = [
          'small_fish',
          'raw_meat',
        ].where(game.canConsume).toList();
        if (meals.isNotEmpty) {
          act('eat', () => game.consume(meals.first));
          continue;
        }
      }
      if (game.state.value(SurvivalStat.health) < 65 &&
          game.canConsume('herb')) {
        act('herb', () => game.consume('herb'));
        continue;
      }
      if (game.state.value(SurvivalStat.health) < 45 ||
          game.state.value(SurvivalStat.sanity) < 25) {
        if (!act('rest', () => game.startAction(CampAction.rest))) break;
        continue;
      }
      if (game.state.rescueStage == RescueStage.signalSent) {
        act(
          'prepare',
          () => game.startAction(
            water < 70 || food < 65 ? CampAction.forage : CampAction.rest,
          ),
        );
        continue;
      }
      if (game.activateBeaconBlockReason == null) {
        act('signal', game.activateBeacon);
        continue;
      }
      final thresholdWater =
          policy == Policy.novice || policy == Policy.reckless ? 25 : 45;
      final thresholdFood = policy == Policy.novice || policy == Policy.reckless
          ? 20
          : 40;
      if (water < thresholdWater || food < thresholdFood) {
        if (!act('forage', () => game.startAction(CampAction.forage))) break;
        continue;
      }
      final target = builds.firstWhere(
        (id) => !recipes.find(id)!.isOwnedBy(game.state),
        orElse: () => 'emergency_beacon',
      );
      final targetCosts = recipes.find(target)!.costs;
      if (game.state.toolCondition('stone_axe') < 2 &&
          game.canRepairTool('stone_axe') &&
          (targetCosts.containsKey('hardwood') ||
              targetCosts.containsKey('wood')) &&
          game.craftBlockReason('stone_axe') == null) {
        act('repair:stone_axe', () => game.craft('stone_axe'));
        continue;
      }
      final craftable = builds
          .where(
            (id) =>
                game.craftBlockReason(id) == null &&
                !recipes.find(id)!.isOwnedBy(game.state),
          )
          .toList();
      if (craftable.isNotEmpty) {
        act('craft:${craftable.first}', () => game.craft(craftable.first));
        continue;
      }
      final demand = needs();
      String? destination;
      if (game.state.campTier >= 2 &&
          game.state.tools.contains('machete') &&
          game.state.resource('beacon_core') == 0) {
        destination = 'ancient_ruins';
      } else if (game.state.campTier >= 1 &&
          ([
                'battery',
                'wire',
                'metal_parts',
                'radio_module',
              ].any((id) => game.state.resource(id) == 0) ||
              demand.containsKey('metal_scrap'))) {
        destination = 'plane_wreck';
      } else if (demand.containsKey('hardwood')) {
        destination = 'bamboo_grove';
      }
      final travelWater = policy == Policy.informed || policy == Policy.careful
          ? 60
          : 45;
      final travelFood = policy == Policy.informed || policy == Policy.careful
          ? 55
          : 35;
      if (destination != null &&
          game.travelBlockReason(destination) == null &&
          water >= travelWater &&
          food >= travelFood) {
        act('travel:$destination', () => game.travelTo(destination!));
        continue;
      }
      if (!act('forage', () => game.startAction(CampAction.forage))) break;
    }
    check();
    return {
      'seed': seed,
      'policy': policy.name,
      'outcome': game.state.rescued
          ? 'rescued'
          : !game.state.isAlive
          ? 'dead'
          : blocked.isNotEmpty
          ? 'blocked'
          : 'timeout',
      'day': game.state.day,
      'steps': steps,
      'restores': restores,
      'tierDays': tierDays,
      'minHealth': minHealth,
      'minWater': minWater,
      'minFood': minFood,
      'injuryReports': injuryReports,
      'lowSupplySteps': lowSupplySteps,
      'endHealth': game.state.value(SurvivalStat.health),
      'endWater': game.state.value(SurvivalStat.water),
      'endFood': game.state.value(SurvivalStat.food),
      'campTier': game.state.campTier,
      'resources': game.state.resources,
      'events': events,
      'operations': operations,
      'lastOperation': last,
      'blocked': blocked,
      'lastReport': game.report?.title,
    };
  }
}

Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List) return value.map(canonical).toList();
  return value;
}

double quantile(List<num> source, double percentile) {
  if (source.isEmpty) return 0;
  final sorted = [...source]..sort();
  return sorted[((sorted.length - 1) * percentile).round()].toDouble();
}

Map<String, dynamic> summary(List<Map<String, dynamic>> runs) {
  final wins = runs.where((r) => r['outcome'] == 'rescued').toList();
  final losses = runs.where((r) => r['outcome'] == 'dead').toList();
  return {
    'runs': runs.length,
    'wins': wins.length,
    'deaths': losses.length,
    'timeouts': runs.where((r) => r['outcome'] == 'timeout').length,
    'blocked': runs.where((r) => r['outcome'] == 'blocked').length,
    'winRate': wins.length / runs.length,
    'winDays': {
      'p10': quantile(wins.map((r) => r['day'] as int).toList(), .1),
      'median': quantile(wins.map((r) => r['day'] as int).toList(), .5),
      'p90': quantile(wins.map((r) => r['day'] as int).toList(), .9),
    },
    'deathDayMedian': quantile(losses.map((r) => r['day'] as int).toList(), .5),
    'winningMinHealthMedian': quantile(
      wins.map((r) => r['minHealth'] as int).toList(),
      .5,
    ),
    'winningEndHealthMedian': quantile(
      wins.map((r) => r['endHealth'] as int).toList(),
      .5,
    ),
    'injuryReportsMedian': quantile(
      runs.map((r) => r['injuryReports'] as int).toList(),
      .5,
    ),
    'restores': runs.fold(0, (int n, r) => n + (r['restores'] as int)),
  };
}

Map<String, dynamic> fishingProbe(Policy policy, int samples) {
  var perfect = 0, good = 0, miss = 0;
  for (var seed = 0; seed < samples; seed++) {
    final session = FishingSession(random: Random(seed));
    session.cast();
    while (session.stage == FishingStage.waiting) {
      session.update(.01);
    }
    final random = Random(seed + 8321);
    final reaction = policy == Policy.informed
        ? .15
        : policy == Policy.careful
        ? .35
        : .45 + random.nextDouble();
    session.update(reaction);
    session.hook();
    final interval = policy == Policy.informed
        ? .05
        : policy == Policy.careful
        ? .2
        : .5;
    while (!session.complete) {
      final noise = policy == Policy.informed
          ? 0.0
          : gaussian(random) * (policy == Policy.careful ? .03 : .13);
      session.holding = session.cursor < session.target + noise;
      session.update(interval);
    }
    switch (session.quality) {
      case CatchQuality.perfect:
        perfect++;
      case CatchQuality.good:
        good++;
      case CatchQuality.missed:
        miss++;
    }
  }
  return {'runs': samples, 'perfect': perfect, 'good': good, 'miss': miss};
}

Map<String, dynamic> gatheringProbe(
  GatheringKind kind,
  Policy policy,
  int samples,
) {
  var wood = 0,
      hardwood = 0,
      meat = 0,
      fiber = 0,
      food = 0,
      injured = 0,
      wear = 0;
  var successes = 0;
  for (var seed = 0; seed < samples; seed++) {
    // Isolated skill fixture only. Full runs above always start from RunState().
    final game = GameEngine(
      catalog,
      world: world,
      recipes: recipes,
      random: Random(seed),
      initialState: RunState(
        tools: {'stone_axe', 'stone_spear', 'stone_knife', 'machete'},
        stats: {for (final stat in SurvivalStat.values) stat: 80},
        resources: {},
      ),
    );
    game.openGathering(kind);
    playGathering(game, policy, Random(seed + 91731));
    wood += game.state.resource('wood');
    hardwood += game.state.resource('hardwood');
    meat += game.state.resource('raw_meat');
    fiber += game.state.resource('fiber');
    food +=
        (game.report?.changes['Food'] ?? 0) +
        3; // Include the paid action's food drain.
    if ((game.report?.changes['Health'] ?? 0) < 0) injured++;
    if (kind != GatheringKind.foraging) {
      wear += 10 - game.state.toolCondition(kind.art);
    }
    if ((kind == GatheringKind.chopping && game.state.resource('wood') > 0) ||
        (kind == GatheringKind.hunting &&
            game.state.resource('raw_meat') > 0) ||
        (kind == GatheringKind.foraging &&
            (game.state.resources.values.any((v) => v > 0) ||
                (game.report?.changes['Food'] ?? 0) + 3 > 0))) {
      successes++;
    }
  }
  return {
    'runs': samples,
    'successes': successes,
    'meanWood': wood / samples,
    'meanHardwood': hardwood / samples,
    'meanMeat': meat / samples,
    'meanFiber': fiber / samples,
    'meanFoodGainBeforeActionDrain': food / samples,
    'injured': injured,
    'meanWear': wear / samples,
  };
}

class FixedAuditRandom implements Random {
  FixedAuditRandom(this.roll);
  final double roll;
  @override
  double nextDouble() => roll;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

Map<String, dynamic> contentProbe() {
  final rows = <Map<String, dynamic>>[];
  for (final event in catalog.events) {
    for (final choice in event.choices) {
      for (final fail
          in choice.isRisky || choice.minigame != null
              ? [false, true]
              : [false]) {
        final resources = <String, int>{
          for (final recipe in recipes.recipes)
            for (final key in recipe.costs.keys) key: 30,
          for (final e in catalog.events)
            for (final c in e.choices)
              for (final key in {
                ...c.effect.resources.keys,
                ...c.requires.keys,
              })
                key: 30,
        };
        final stats = {for (final stat in SurvivalStat.values) stat: 80};
        for (final e in choice.showWhenBelow.entries) {
          stats[e.key] = e.value;
        }
        for (final e in choice.requiresStats.entries) {
          stats[e.key] = max(stats[e.key]!, e.value);
        }
        final location = event.locations.firstOrNull ?? 'camp';
        final state = RunState(
          day: 20,
          campTier: 3,
          locationId: location,
          phase: event.trigger == 'night' ? RunPhase.night : RunPhase.day,
          rescueStage: event.trigger == 'rescue'
              ? RescueStage.storm
              : RescueStage.searching,
          rescueStep: max(0, rescueEventIds.indexOf(event.id)),
          tools: recipes.crafts.map((r) => r.id).toSet(),
          stats: stats,
          resources: resources,
        );
        final game = GameEngine(
          catalog,
          world: world,
          recipes: recipes,
          random: FixedAuditRandom(fail ? .999 : 0),
          initialState: state,
        );
        final saved = game.toJson();
        saved['pendingEvent'] = event.id;
        saved['pendingAction'] = ['forage', 'explore'].contains(event.trigger)
            ? event.trigger
            : null;
        saved['pendingCost'] = event.trigger == 'explore'
            ? 2
            : event.trigger == 'forage'
            ? 1
            : 0;
        if (location != 'camp') {
          saved['expedition'] = {
            'locationId': location,
            'depth': event.minDepth,
            'loot': {'wood': 3, 'fiber': 2},
          };
        }
        if (!game.restore(saved) ||
            !game.canChoose(choice) ||
            !game.choose(choice.id)) {
          throw StateError(
            'Content fixture cannot choose ${event.id}/${choice.id}/$fail',
          );
        }
        if (game.choose(choice.id)) throw StateError('Choice resolved twice');
        if (game.gathering != null) {
          if (fail) {
            game.beginGathering();
            while (game.gathering!.active &&
                game.gathering!.kind != GatheringKind.foraging) {
              game.strikeGathering();
              game.tickGathering(1.6);
            }
            game.finishGathering(leave: game.gathering!.active);
          } else {
            playGathering(game, Policy.informed, Random(1));
          }
        }
        if (game.ruinsPuzzle != null) {
          final puzzle = game.ruinsPuzzle!;
          if (!fail) {
            for (var i = 0; i < 3; i++) {
              while (puzzle.tiles[i] != puzzle.pattern[i]) {
                game.turnRuinsTile(i);
              }
            }
          }
          game.finishRuinsPuzzle();
        }
        if (game.report == null) throw StateError('Missing result popup');
        final snapshot = jsonEncode(game.toJson());
        if (game.choose(choice.id) || jsonEncode(game.toJson()) != snapshot) {
          throw StateError('Repeated choice changed state');
        }
        if (game.state.timeLeft < 0 ||
            game.state.resources.values.any((v) => v < 0) ||
            game.state.stats.values.any((v) => v < 0 || v > 100)) {
          throw StateError('Content bounds');
        }
        final restored = GameEngine(
          catalog,
          world: world,
          recipes: recipes,
          random: FixedAuditRandom(.5),
        );
        if (!restored.restore(jsonDecode(snapshot) as Map<String, dynamic>) ||
            jsonEncode(canonical(restored.state.toJson())) !=
                jsonEncode(canonical(game.state.toJson())) ||
            restored.report!.body != game.report!.body) {
          throw StateError('Content outcome restore');
        }
        rows.add({
          'event': event.id,
          'choice': choice.id,
          'branch': fail ? 'failure' : 'success',
          'report': game.report!.title,
          'changes': game.report!.changes,
        });
      }
    }
  }
  return {
    'events': catalog.events.length,
    'choiceBranches': rows.length,
    'rows': rows,
  };
}

void main(List<String> arguments) {
  final count = arguments.isEmpty ? 200 : int.parse(arguments.first);
  final path = arguments.length > 1
      ? arguments[1]
      : 'design/balance-audit-v1/results.json';
  final runs = <Map<String, dynamic>>[];
  final summaries = <String, dynamic>{};
  for (final policy in Policy.values) {
    final batch = [
      for (var seed = 0; seed < count; seed++) Probe(seed, policy).run(),
    ];
    runs.addAll(batch);
    summaries[policy.name] = summary(batch);
    stdout.writeln('${policy.name}: ${jsonEncode(summaries[policy.name])}');
  }
  final result = {
    'seedsPerPolicy': count,
    'maxDay': 80,
    'maxTransactions': 3500,
    'restoreEvery': 23,
    'summary': summaries,
    'runs': runs,
    'contentChecks': contentProbe(),
    'gathering': {
      for (final kind in GatheringKind.values)
        kind.name: {
          for (final policy in [Policy.informed, Policy.careful, Policy.novice])
            policy.name: gatheringProbe(kind, policy, 1000),
        },
    },
    'fishing': {
      for (final policy in [Policy.informed, Policy.careful, Policy.novice])
        policy.name: fishingProbe(policy, 1000),
    },
  };
  final destination = File(path)..parent.createSync(recursive: true);
  destination.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(result),
  );
  stdout.writeln('Wrote $path');
}
