import 'package:survival_game/game/run_progression.dart';
import 'dart:convert';
import 'gathering_test.dart' show resolveGatheringForSimulation;
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/rescue_progress.dart';
import 'package:survival_game/game/ruins_puzzle.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';

import 'game_engine_test.dart' show FixedRandom;

GameEngine rescueGame({RunState? state, Random? random}) => GameEngine(
  EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
  world: WorldCatalog.fromJson(
    File('assets/data/locations.json').readAsStringSync(),
  ),
  recipes: RecipeCatalog.fromJson(
    File('assets/data/recipes.json').readAsStringSync(),
  ),
  random: random ?? FixedRandom(.999),
  initialState: state ?? rescueState(),
);

RunState rescueState({
  int tier = 3,
  int time = 6,
  RescueStage stage = RescueStage.searching,
  int step = 0,
  int health = 100,
  int water = 100,
  int food = 100,
  Set<String> tools = const {'machete', 'torch'},
  Map<String, int> resources = const {
    'wood': 12,
    'fiber': 12,
    'metal_scrap': 8,
  },
}) => RunState(
  day: 8,
  campTier: tier,
  timeLeft: time,
  rescueStage: stage,
  rescueStep: step,
  tools: tools,
  resources: resources,
  stats: {
    SurvivalStat.health: health,
    SurvivalStat.water: water,
    SurvivalStat.food: food,
    SurvivalStat.sanity: 80,
  },
);

GameEngine reopen(GameEngine game) {
  final restored = rescueGame();
  expect(
    restored.restore(
      jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>,
    ),
    isTrue,
  );
  return restored;
}

void openAltar(GameEngine game) {
  expect(game.travelTo('ancient_ruins'), isTrue);
  expect(game.pendingEvent!.id, 'ruins_altar');
  expect(game.choose('align'), isTrue);
  expect(game.ruinsPuzzle, isNotNull);
}

void solveAltar(GameEngine game) {
  final puzzle = game.ruinsPuzzle!;
  for (var i = 0; i < 3; i++) {
    while (puzzle.tiles[i] != puzzle.pattern[i]) {
      expect(game.turnRuinsTile(i), isTrue);
    }
  }
  expect(game.finishRuinsPuzzle(), isTrue);
}

void finishDay(GameEngine game) {
  while (game.state.phase == RunPhase.day && game.state.timeLeft > 0) {
    expect(game.startAction(CampAction.rest), isTrue);
    game.continueFromReport();
  }
  expect(game.pendingEvent!.trigger, 'night');
  game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
  game.continueFromReport();
  expect(game.sleep(), isTrue);
}

void main() {
  test('ruins require camp tier two, a machete and one extra daylight', () {
    expect(
      rescueGame(
        state: rescueState(tier: 1),
      ).travelBlockReason('ancient_ruins'),
      contains('Tier 2'),
    );
    expect(
      rescueGame(
        state: rescueState(tools: {}),
      ).travelBlockReason('ancient_ruins'),
      contains('Machete'),
    );
    expect(
      rescueGame(state: rescueState(time: 3)).travelTo('ancient_ruins'),
      isFalse,
    );
    expect(
      rescueGame(
        state: rescueState(time: 4),
      ).travelBlockReason('ancient_ruins'),
      isNull,
    );
    expect(
      rescueGame(
        state: rescueState(tier: 1, tools: {}),
      ).craftBlockReason('machete'),
      isNull,
    );
  });

  test('wreck guarantees each missing part once and all four fit one trip', () {
    final game = rescueGame();
    expect(game.travelTo('plane_wreck'), isTrue);
    final expected = ['battery', 'wire', 'metal_parts', 'radio_module'];
    for (var i = 0; i < expected.length; i++) {
      expect(game.pendingEvent!.missingResource, expected[i]);
      expect(game.choose('recover'), isTrue);
      expect(game.state.resource(expected[i]), 1);
      expect(game.report!.changes[expected[i]], 1);
      expect(game.choose('recover'), isFalse);
      game.continueFromReport();
      if (i < expected.length - 1) expect(game.goDeeper(), isTrue);
    }
    expect(game.state.timeLeft, 0);
    expect(game.expedition, isNull);
    expect(game.state.foundComponents, containsAll(expected));
    expect(
      game.catalog
          .eligible('explore', game.state)
          .where((e) => e.id.startsWith('wreck_') && e.missingResource != null),
      isEmpty,
    );
  });

  test(
    'lost parts can be recovered again without erasing discovery history',
    () {
      final resources = {for (final key in beaconComponents.keys) key: 1}
        ..remove('wire');
      final game = rescueGame(state: rescueState(resources: resources));
      expect(game.travelTo('plane_wreck'), isTrue);
      expect(game.pendingEvent!.id, 'wreck_wire');
      game.choose('recover');
      expect(game.state.resource('wire'), 1);
    },
  );

  test(
    'puzzle rotations autosave and restoration keeps busy state and trip',
    () {
      var writes = 0;
      final game = rescueGame()..onChanged = () => writes++;
      openAltar(game);
      final time = game.state.timeLeft;
      game.turnRuinsTile(1);
      expect(writes, 3);
      expect(game.state.timeLeft, time);
      expect(game.turnRuinsTile(3), isFalse);
      final copy = reopen(game);
      expect(copy.ruinsPuzzle!.toJson(), game.ruinsPuzzle!.toJson());
      expect(copy.isBusy, isTrue);
      expect(copy.awaitingExpeditionDecision, isFalse);
      expect(copy.goDeeper(), isFalse);
      expect(copy.returnHome(), isFalse);
      expect(copy.startAction(CampAction.rest), isFalse);
      solveAltar(copy);
      expect(copy.state.resource('beacon_core'), 1);
      expect(copy.expedition!.loot['beacon_core'], 1);
      expect(copy.state.timeLeft, 2);
      expect(copy.report!.changes['Water'], -16);
      expect(copy.report!.changes['beacon_core'], 1);
      expect(copy.finishRuinsPuzzle(), isFalse);
      final result = reopen(copy);
      expect(result.report!.title, 'The altar opens');
      result.continueFromReport();
      result.returnHome();
      expect(result.report!.changes['beacon_core'], 1);
      result.continueFromReport();
      expect(result.state.locationId, 'camp');
      expect(result.state.foundComponents, contains('beacon_core'));
    },
  );

  test('wrong alignment and leaving do not reveal or award the core', () {
    final wrong = rescueGame();
    openAltar(wrong);
    expect(wrong.ruinsPuzzle!.solved, isFalse);
    wrong.finishRuinsPuzzle();
    expect(wrong.state.resource('beacon_core'), 0);
    expect(wrong.state.timeLeft, 2);
    expect(wrong.report!.changes['Sanity'], -3);
    wrong.continueFromReport();
    wrong.goDeeper();
    expect(wrong.choose('align'), isTrue);
    solveAltar(wrong);
    expect(wrong.state.resource('beacon_core'), 1);

    final leave = rescueGame();
    openAltar(leave);
    expect(leave.finishRuinsPuzzle(leave: true), isTrue);
    expect(leave.state.timeLeft, 3);
    expect(leave.state.resource('beacon_core'), 0);
    expect(leave.report!.changes.containsKey('Sanity'), isFalse);
  });

  test(
    'fatal travel or submission cannot open the altar or revive the player',
    () {
      final travel = rescueGame(
        state: rescueState(health: 10, water: 0, food: 0),
      );
      travel.travelTo('ancient_ruins');
      travel.choose('align');
      expect(travel.ruinsPuzzle, isNull);
      expect(travel.state.phase, RunPhase.gameOver);

      final submit = rescueGame(
        state: rescueState(health: 20, water: 12, food: 12),
      );
      openAltar(submit);
      expect(submit.state.isAlive, isTrue);
      solveAltar(submit);
      expect(submit.state.phase, RunPhase.gameOver);
      expect(submit.state.resource('beacon_core'), 0);
    },
  );

  test(
    'beacon assembly consumes all five parts exactly once at Rescue Base',
    () {
      final parts = {
        for (final key in beaconComponents.keys) key: 1,
        'metal_scrap': 2,
      };
      expect(
        rescueGame(
          state: rescueState(tier: 2, resources: parts),
        ).craftBlockReason('emergency_beacon'),
        'Needs Rescue Base',
      );
      final game = rescueGame(state: rescueState(resources: parts));
      expect(game.craft('emergency_beacon'), isTrue);
      expect(game.state.timeLeft, 4);
      expect(game.state.tools, contains('emergency_beacon'));
      expect(game.state.foundComponents, hasLength(5));
      for (final key in parts.keys) {
        expect(game.state.resource(key), 0);
      }
      game.continueFromReport();
      expect(game.craft('emergency_beacon'), isFalse);
      expect(game.craftBlockReason('emergency_beacon'), 'Already crafted');
      expect(
        game.catalog
            .eligible('explore', game.state)
            .where((e) => e.missingResource != null),
        isEmpty,
      );
    },
  );

  test('activation is one transaction and storm begins only next dawn', () {
    var game = rescueGame(
      state: rescueState(
        tools: {'emergency_beacon', 'machete', 'torch', 'rain_collector'},
      ),
    );
    expect(game.activateBeacon(), isTrue);
    expect(game.state.timeLeft, 5);
    expect(game.state.signalDay, 8);
    expect(game.state.rescueStage, RescueStage.signalSent);
    expect(game.activateBeacon(), isFalse);
    game = reopen(game);
    expect(game.report!.title, 'Signal received');
    game.continueFromReport();
    expect(game.canAct(CampAction.forage), isTrue);
    expect(game.activateBeacon(), isFalse);
    finishDay(game);
    expect(game.state.day, 9);
    expect(game.state.weather, 'Storm');
    expect(game.state.value(SurvivalStat.water), 89);
    expect(game.state.rescueStage, RescueStage.storm);
    expect(game.report!.title, 'The rescue storm');
    game = reopen(game);
    game.continueFromReport();
    expect(game.pendingEvent!.id, rescueEventIds.first);
    expect(game.pendingCost, 2);
    expect(game.startAction(CampAction.rest), isFalse);
    expect(game.travelTo('riverbank'), isFalse);
    expect(game.craft('basic_rod'), isFalse);
  });

  test(
    'all storm steps and their unread reports restore, victory stays terminal',
    () {
      var game = rescueGame(state: rescueState(stage: RescueStage.storm));
      game = reopen(game);
      for (var i = 0; i < 3; i++) {
        expect(game.pendingEvent!.id, rescueEventIds[i]);
        game = reopen(game);
        expect(game.choose(['raise', 'cut', 'torch'][i]), isTrue);
        expect(game.choose(['raise', 'cut', 'torch'][i]), isFalse);
        expect(game.state.rescueStep, i + 1);
        expect(game.state.timeLeft, 6 - 2 * (i + 1));
        final title = game.report!.title;
        game = reopen(game);
        expect(game.report!.title, title);
        game.continueFromReport();
      }
      expect(game.state.rescued, isTrue);
      expect(game.pendingEvent, isNull);
      expect(game.isBusy, isFalse);
      expect(game.startAction(CampAction.forage), isFalse);
      expect(game.sleep(), isFalse);
      expect(game.activateBeacon(), isFalse);
      expect(game.canConsume('herb'), isFalse);
      game = reopen(game);
      expect(game.state.rescued, isTrue);
      game.restart();
      expect(game.state.rescued, isFalse);
      expect(game.state.rescueStage, RescueStage.searching);
      expect(game.state.rescueStep, 0);
      expect(game.state.signalDay, isNull);
      expect(game.state.foundComponents, isEmpty);
    },
  );

  test('final storm always has a free path; damage can still end the run', () {
    var free = rescueGame(
      state: rescueState(stage: RescueStage.storm, tools: {}, resources: {}),
    );
    free = reopen(free);
    for (final id in ['hold', 'pull', 'wave']) {
      expect(free.choose(id), isTrue);
      free.continueFromReport();
    }
    expect(free.state.rescued, isTrue);
    expect(free.state.value(SurvivalStat.health), 74);

    var fatal = rescueGame(
      state: rescueState(
        stage: RescueStage.storm,
        step: 2,
        time: 2,
        health: 7,
        tools: {},
        resources: {},
      ),
    );
    fatal = reopen(fatal);
    fatal.choose('wave');
    expect(fatal.state.phase, RunPhase.gameOver);
    expect(fatal.state.rescueStep, 2);
    expect(fatal.report, isNotNull);
    fatal.continueFromReport();
    expect(fatal.pendingEvent, isNull);
    expect(fatal.state.rescued, isFalse);
  });

  test('legacy version-one saves restore without rescue fields', () {
    final saved = rescueGame(state: RunState()).toJson();
    final state = saved['state'] as Map<String, dynamic>;
    for (final key in [
      'rescueStage',
      'rescueStep',
      'signalDay',
      'foundComponents',
    ]) {
      state.remove(key);
    }
    final game = rescueGame();
    expect(game.restore(saved), isTrue);
    expect(game.state.rescueStage, RescueStage.searching);
    expect(game.state.rescueStep, 0);
    expect(game.state.foundComponents, isEmpty);
  });

  test(
    'malformed stone puzzle is rejected without replacing the current run',
    () {
      final game = rescueGame();
      openAltar(game);
      final saved = game.toJson();
      ((saved['ruinsPuzzle'] as Map)['session'] as Map)['tiles'] = [9, 0];
      final restored = rescueGame();
      expect(restored.restore(saved), isFalse);
      expect(restored.ruinsPuzzle, isNull);
      expect(restored.state.day, 8);
      expect(
        () => RuinsPuzzle.fromJson({
          'pattern': [0, 1, 2],
          'tiles': [0, 1, 2],
          'moves': -1,
        }),
        throwsFormatException,
      );
    },
  );

  for (final scenario in [
    for (final seed in [42, 77])
      for (final option in startingOptions) (seed, option),
  ]) {
    final seed = scenario.$1;
    final option = scenario.$2;
    test(
      'fresh run reaches rescue through earned resources with seed $seed option ${option.id}',
      () {
        var game = rescueGame(state: RunState(), random: Random(seed));
        game.profile.xp = rankThreshold(option.rank);
        game.selectStartingOption(option.id);
        game.restart();
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
        var transactions = 0;
        var restorations = 0;
        Map<String, int> needs() {
          final target = builds.firstWhere((id) {
            final recipe = game.recipes.find(id)!;
            return recipe.kind == RecipeKind.campTier
                ? game.state.campTier < recipe.tier!
                : !game.state.tools.contains(id);
          }, orElse: () => 'emergency_beacon');
          return {
            for (final e in game.recipes.find(target)!.costs.entries)
              if (e.value > game.state.resource(e.key))
                e.key: e.value - game.state.resource(e.key),
          };
        }

        double score(EventChoice choice) {
          final effect = choice.effect;
          if (choice.minigame != null) return 1000;
          if (effect.endsExpedition || effect.dropLoot) return -1000;
          final demand = needs();
          var value = choice.isRisky ? -60.0 : 0.0;
          for (final e in effect.stats.entries) {
            final current = game.state.value(e.key);
            final gain = min(e.value, 100 - current);
            value +=
                gain *
                (e.key == SurvivalStat.health
                    ? (current < 60 ? 3 : .5)
                    : e.key == SurvivalStat.water
                    ? (current < 50
                          ? 4
                          : current < 70
                          ? 1.5
                          : .3)
                    : e.key == SurvivalStat.food
                    ? (current < 50
                          ? 4
                          : current < 70
                          ? 1.5
                          : .3)
                    : current < 35
                    ? 2
                    : .15);
          }
          for (final e in effect.resources.entries) {
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
          return value;
        }

        while (!game.state.rescued &&
            game.state.isAlive &&
            transactions++ < 2000) {
          // Persist real intermediate transactions, including carried parts and
          // unfinished choices. No resource, stat or progression injection.
          if (transactions % 23 == 0) {
            final copy = rescueGame(
              state: RunState(),
              random: Random(seed + transactions),
            );
            expect(
              copy.restore(
                jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>,
              ),
              isTrue,
            );
            game = copy;
            restorations++;
          }
          if (game.report != null) {
            game.continueFromReport();
            continue;
          }
          if (game.gathering != null) {
            resolveGatheringForSimulation(game);
            continue;
          }
          if (game.ruinsPuzzle != null) {
            solveAltar(game);
            continue;
          }
          if (game.pendingEvent != null) {
            final choices = game.visibleChoices.where(game.canChoose).toList()
              ..sort((a, b) => score(b).compareTo(score(a)));
            expect(choices, isNotEmpty);
            expect(game.choose(choices.first.id), isTrue);
            continue;
          }
          if (game.awaitingExpeditionDecision) {
            if (game.canGoDeeper &&
                game.state.value(SurvivalStat.water) >= 32 &&
                game.state.value(SurvivalStat.food) >= 24) {
              game.goDeeper();
            } else {
              game.returnHome();
            }
            continue;
          }
          if (game.canSleep) {
            game.sleep();
            continue;
          }
          if (game.state.value(SurvivalStat.food) < 65) {
            final food = [
              'small_fish',
              'raw_meat',
              'ember_berries',
              'dew_fruit',
              'canopy_fig',
              'cooked_root',
              'iron_nut',
              'wild_honey',
            ].where(game.canConsume).toList();
            if (food.isNotEmpty) {
              game.consume(food.first);
              continue;
            }
          }
          if (game.state.value(SurvivalStat.health) < 65 &&
              game.canConsume('herb')) {
            game.consume('herb');
            continue;
          }
          if (game.state.value(SurvivalStat.health) < 45 ||
              game.state.value(SurvivalStat.sanity) < 25) {
            game.startAction(CampAction.rest);
            continue;
          }
          if (game.state.rescueStage == RescueStage.signalSent) {
            game.startAction(
              game.state.value(SurvivalStat.water) < 70 ||
                      game.state.value(SurvivalStat.food) < 65
                  ? CampAction.forage
                  : CampAction.rest,
            );
            continue;
          }
          if (game.activateBeaconBlockReason == null) {
            game.activateBeacon();
            continue;
          }
          if (game.state.value(SurvivalStat.water) < 45 ||
              game.state.value(SurvivalStat.food) < 40) {
            game.startAction(CampAction.forage);
            continue;
          }
          final craftable = builds
              .where((id) => game.craftBlockReason(id) == null)
              .toList();
          if (craftable.isNotEmpty) {
            game.craft(craftable.first);
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
          if (destination != null &&
              game.travelBlockReason(destination) == null &&
              game.state.value(SurvivalStat.water) >= 60 &&
              game.state.value(SurvivalStat.food) >= 55) {
            final gear = {...game.suggestedGear};
            final required = game.world.find(destination)?.requiresTool;
            if (required != null) {
              if (required == 'machete') {
                gear.remove('stone_knife');
              }
              gear.add(required);
            }
            expect(game.travelTo(destination, gear: gear), isTrue);
            continue;
          }
          expect(game.startAction(CampAction.forage), isTrue);
        }
        expect(
          game.state.rescued,
          isTrue,
          reason:
              'day=${game.state.day}, transactions=$transactions, state=${game.state.toJson()}, event=${game.pendingEvent?.id}',
        );
        expect(game.state.campTier, 3);
        expect(game.state.foundComponents, hasLength(5));
        expect(restorations, greaterThan(0));
        expect(game.state.day, lessThan(70));
        stdout.writeln(
          'BALANCE seed=$seed option=${option.id} day=${game.state.day} nights=${game.metrics.nights} transactions=$transactions health=${game.state.value(SurvivalStat.health)}',
        );
      },
    );
  }
}
