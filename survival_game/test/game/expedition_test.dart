import 'dart:io';
import 'gathering_test.dart' show resolveGatheringForSimulation;
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/fishing_session.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';

import 'fishing_session_test.dart' show reelByTracking, waitForBite;
import 'game_engine_test.dart' show FixedRandom;

void main() {
  late EventCatalog catalog;
  late WorldCatalog world;
  late RecipeCatalog recipes;
  setUpAll(() {
    recipes = RecipeCatalog.fromJson(
      File('assets/data/recipes.json').readAsStringSync(),
    );
    catalog = EventCatalog.fromJson(
      File('assets/data/events.json').readAsStringSync(),
    );
    world = WorldCatalog.fromJson(
      File('assets/data/locations.json').readAsStringSync(),
    );
  });

  GameEngine engine({
    int day = 1,
    int timeLeft = 6,
    Set<String> tools = const {},
    Map<String, int>? resources,
    Map<SurvivalStat, int>? stats,
    Random? random,
  }) => GameEngine(
    catalog,
    world: world,
    recipes: recipes,
    random: random ?? FixedRandom(),
    initialState: RunState(
      day: day,
      timeLeft: timeLeft,
      tools: tools,
      resources: resources,
      stats: stats,
    ),
  );

  GameEngine angler({int timeLeft = 6, int bait = 2, int fish = 0}) => engine(
    timeLeft: timeLeft,
    tools: {'basic_rod'},
    resources: {'bait': bait, 'small_fish': fish},
  );

  /// Casts, hooks after [reaction] seconds and reels by tracking the zone.
  void fish(GameEngine game, {double reaction = .2}) {
    expect(game.castLine(), isTrue);
    final session = game.fishing!;
    waitForBite(session);
    session.update(reaction);
    session.hook();
    reelByTracking(session);
  }

  group('map', () {
    test('ships seven valid locations with the planned time costs', () {
      expect(world.locations.map((l) => l.id), [
        'camp',
        'riverbank',
        'fishing_pond',
        'plane_wreck',
        'ancient_ruins',
        'bamboo_grove',
        'mangrove_shallows',
      ]);
      expect(world.find('riverbank')!.timeCost, 2);
      expect(world.find('fishing_pond')!.timeCost, 2);
    });

    test('day one: riverbank open, pond locked until day 2 or a rod', () {
      final game = engine();
      expect(game.travelBlockReason('camp'), isNull);
      expect(game.travelBlockReason('riverbank'), isNull);
      expect(
        game.travelBlockReason('fishing_pond'),
        'Discover on day 2 or craft a Basic Rod.',
      );
      expect(game.travelTo('fishing_pond'), isFalse);
      expect(game.travelTo('camp'), isFalse);
      expect(game.travelBlockReason('nowhere'), 'Unknown destination.');
    });

    test('day two reveals the pond but fishing still needs rod and bait', () {
      expect(
        engine(day: 2).travelBlockReason('fishing_pond'),
        'Craft a Basic Rod in the workshop.',
      );
      expect(
        angler(bait: 0).travelBlockReason('fishing_pond'),
        'Collect bait at the Riverbank first.',
      );
      expect(angler().travelBlockReason('fishing_pond'), isNull);
    });

    test('wreck and ruins stay locked as later content', () {
      final game = engine(day: 9, tools: {'basic_rod'});
      for (final id in ['plane_wreck', 'ancient_ruins']) {
        expect(game.travelBlockReason(id), contains('Requires Camp Tier'));
        expect(game.travelTo(id), isFalse);
      }
    });

    test('travel needs enough daylight, daytime and an idle camp', () {
      expect(
        engine(timeLeft: 1).travelBlockReason('riverbank'),
        'Need 2 daylight. Rest until tomorrow.',
      );
      final busy = engine()..startAction(CampAction.forage);
      expect(
        busy.travelBlockReason('riverbank'),
        'Finish your current activity first.',
      );
      final night = engine(timeLeft: 1)
        ..startAction(CampAction.rest)
        ..continueFromReport();
      night.choose(night.pendingEvent!.choices.firstWhere((c) => c.isFree).id);
      night.continueFromReport();
      expect(night.state.phase, RunPhase.night);
      expect(night.travelBlockReason('riverbank'), 'Travel resumes at dawn.');
    });
  });

  group('riverbank', () {
    test('picks a riverbank event and charges 2 time only on decision', () {
      final game = engine();
      expect(game.travelTo('riverbank'), isTrue);
      expect(game.state.locationId, 'riverbank');
      expect(game.pendingEvent!.locations, contains('riverbank'));
      expect(game.state.timeLeft, 6);
      expect(game.travelTo('riverbank'), isFalse);

      expect(game.choose('rod_materials'), isTrue);
      expect(game.state.timeLeft, 4);
      expect(game.state.value(SurvivalStat.water), 72);
      expect(game.state.value(SurvivalStat.food), 69);
      expect(game.state.resource('wood'), 4);
      expect(game.state.resource('fiber'), 3);
      expect(game.state.resource('bait'), 2);
      expect(game.choose('rod_materials'), isFalse);

      game.continueFromReport();
      // Daylight is left, so the trip waits for a decision instead of ending.
      expect(game.awaitingExpeditionDecision, isTrue);
      expect(game.state.locationId, 'riverbank');
      expect(game.returnHome(), isTrue);
      expect(game.report!.changes, containsPair('wood', 2));
      game.continueFromReport();
      expect(game.state.locationId, 'camp');
      expect(game.isBusy, isFalse);
    });

    test('every riverbank event offers rod materials and bait', () {
      final events = catalog.events.where(
        (e) =>
            e.locations.contains('riverbank') &&
            e.trigger == 'explore' &&
            e.maxDepth == 0,
      );
      expect(events, hasLength(2));
      for (final event in events) {
        expect(event.trigger, 'explore');
        final gains = event.choices.map((c) => c.effect.resources);
        expect(gains.any((r) => (r['fiber'] ?? 0) >= 3), isTrue);
        expect(gains.any((r) => (r['bait'] ?? 0) >= 1), isTrue);
      }
    });

    test('riverbank events never appear from camp forage or explore', () {
      for (var seed = 0; seed < 30; seed++) {
        final game = engine(random: Random(seed));
        game.startAction(CampAction.explore);
        expect(game.pendingEvent!.locations, isEmpty);
      }
    });

    test('the last trip of the day leads straight into the night', () {
      final game = engine(timeLeft: 2);
      game.travelTo('riverbank');
      game.choose(game.pendingEvent!.choices.first.id);
      expect(game.state.timeLeft, 0);
      game.continueFromReport();
      expect(game.state.phase, RunPhase.night);
      expect(game.pendingEvent!.trigger, 'night');
    });
  });

  group('basic rod', () {
    test('reports what is missing', () {
      expect(
        engine(
          resources: {'wood': 2, 'fiber': 2},
        ).craftBlockReason('basic_rod'),
        'Need 1 fiber more',
      );
      expect(
        engine(
          timeLeft: 0,
          resources: {'wood': 2, 'fiber': 3},
        ).craftBlockReason('basic_rod'),
        'Need 1 daylight',
      );
      expect(
        engine(tools: {'basic_rod'}).craftBlockReason('basic_rod'),
        'Already crafted',
      );
    });

    test('costs 2 wood, 3 fiber and 1 time, and is crafted only once', () {
      final game = engine(resources: {'wood': 3, 'fiber': 4});
      expect(game.craft('basic_rod'), isTrue);
      expect(game.state.tools, contains('basic_rod'));
      expect(game.state.resource('wood'), 1);
      expect(game.state.resource('fiber'), 1);
      expect(game.state.timeLeft, 5);
      expect(game.report!.changes, containsPair('wood', -2));
      expect(game.craft('basic_rod'), isFalse);
      game.continueFromReport();
      expect(game.craft('basic_rod'), isFalse);
      expect(game.travelBlockReason('fishing_pond'), contains('bait'));
    });

    test('riverbank supplies are enough for a rod on day one', () {
      final game = engine(resources: {});
      game.travelTo('riverbank');
      game.choose('rod_materials');
      game.continueFromReport();
      game.returnHome();
      game.continueFromReport();
      expect(game.craft('basic_rod'), isTrue);
      game.continueFromReport();
      expect(game.state.timeLeft, 3);
      expect(game.travelBlockReason('fishing_pond'), isNull);
    });
  });

  group('fishing trip', () {
    test('charges 2 time on departure and opens a session', () {
      final game = angler();
      expect(game.travelTo('fishing_pond'), isTrue);
      expect(game.state.timeLeft, 4);
      expect(game.state.locationId, 'fishing_pond');
      expect(game.fishing!.stage, FishingStage.ready);
      expect(game.isBusy, isTrue);
      expect(game.travelTo('fishing_pond'), isFalse);
      expect(game.canConsume('small_fish'), isFalse);
      expect(game.finishFishing(), isFalse);
    });

    test('one cast per trip, each cast uses one bait', () {
      final game = angler(bait: 3);
      game.travelTo('fishing_pond');
      expect(game.castLine(), isTrue);
      expect(game.state.resource('bait'), 2);
      expect(game.castLine(), isFalse);
      expect(game.state.resource('bait'), 2);
    });

    test('a perfect catch brings 2 fish, a good catch 1', () {
      final perfect = angler();
      perfect.travelTo('fishing_pond');
      fish(perfect);
      expect(perfect.fishing!.quality, CatchQuality.perfect);
      expect(perfect.finishFishing(), isTrue);
      expect(perfect.state.resource('small_fish'), 2);
      expect(perfect.report!.title, 'A perfect catch');
      expect(perfect.report!.changes, containsPair('small_fish', 2));
      expect(perfect.fishing, isNull);
      perfect.continueFromReport();
      expect(perfect.state.locationId, 'camp');

      final good = angler();
      good.travelTo('fishing_pond');
      fish(good, reaction: .9);
      expect(good.fishing!.quality, CatchQuality.good);
      good.finishFishing();
      expect(good.state.resource('small_fish'), 1);
      expect(good.report!.title, 'Fresh from the pond');
    });

    test('the rod is reused across trips', () {
      final game = angler();
      for (var trip = 1; trip <= 2; trip++) {
        expect(game.travelTo('fishing_pond'), isTrue);
        fish(game);
        game.finishFishing();
        game.continueFromReport();
      }
      expect(game.state.tools, contains('basic_rod'));
      expect(game.state.resource('bait'), 0);
      expect(game.state.resource('small_fish'), 4);
      expect(game.state.timeLeft, 2);
    });

    test('returning before the cast keeps the bait', () {
      final game = angler();
      game.travelTo('fishing_pond');
      expect(game.finishFishing(abandon: true), isTrue);
      expect(game.state.resource('bait'), 2);
      expect(game.state.resource('small_fish'), 0);
      expect(game.state.timeLeft, 4);
      expect(game.report!.title, 'Back from the pond');
      expect(game.report!.body, contains('without casting'));
    });

    test('abandoning or missing after the cast loses the bait', () {
      final abandoned = angler();
      abandoned.travelTo('fishing_pond');
      abandoned.castLine();
      abandoned.fishing!.update(2);
      expect(abandoned.finishFishing(abandon: true), isTrue);
      expect(abandoned.state.resource('bait'), 1);
      expect(abandoned.state.resource('small_fish'), 0);
      expect(abandoned.report!.body, contains('slipped away'));

      final missed = angler();
      missed.travelTo('fishing_pond');
      missed.castLine();
      missed.fishing!.update(5);
      expect(missed.fishing!.stage, FishingStage.escaped);
      expect(missed.finishFishing(), isTrue);
      expect(missed.state.resource('small_fish'), 0);
    });

    test('a trip that ends the day continues into the night', () {
      final game = angler(timeLeft: 2);
      game.travelTo('fishing_pond');
      expect(game.state.timeLeft, 0);
      expect(game.state.phase, RunPhase.day);
      fish(game);
      game.finishFishing();
      game.continueFromReport();
      expect(game.state.phase, RunPhase.night);
      expect(game.pendingEvent!.trigger, 'night');
    });

    test('running out of supplies on the trail ends the run', () {
      final game = GameEngine(
        catalog,
        world: world,
        recipes: recipes,
        random: FixedRandom(),
        initialState: RunState(
          tools: {'basic_rod'},
          resources: {'bait': 1},
          stats: {
            SurvivalStat.health: 10,
            SurvivalStat.water: 0,
            SurvivalStat.food: 0,
            SurvivalStat.sanity: 50,
          },
        ),
      );
      expect(game.travelTo('fishing_pond'), isTrue);
      expect(game.state.phase, RunPhase.gameOver);
      expect(game.fishing, isNull);
      game.restart();
      expect(game.state.locationId, 'camp');
      expect(game.state.tools, isEmpty);
    });

    test('restart clears an unfinished session', () {
      final game = angler();
      game.travelTo('fishing_pond');
      game.castLine();
      game.restart();
      expect(game.fishing, isNull);
      expect(game.isBusy, isFalse);
      expect(game.castLine(), isFalse);
    });
  });

  group('eating fish', () {
    test('restores 25 food and uses no daylight', () {
      final game = angler(fish: 2);
      expect(game.canConsume('small_fish'), isTrue);
      expect(game.consume('small_fish'), isTrue);
      expect(game.state.value(SurvivalStat.food), 100);
      expect(game.state.resource('small_fish'), 1);
      expect(game.state.timeLeft, 6);
      expect(game.report!.changes, {'Food': 25, 'small_fish': -1});
      expect(game.consume('small_fish'), isFalse);
    });

    test('is unavailable when full, out of fish or busy', () {
      expect(angler().canConsume('small_fish'), isFalse);
      final full = engine(
        resources: {'small_fish': 1},
        stats: {
          SurvivalStat.health: 100,
          SurvivalStat.water: 80,
          SurvivalStat.food: 100,
          SurvivalStat.sanity: 80,
        },
      );
      expect(full.canConsume('small_fish'), isFalse);
      final busy = angler(fish: 1)..startAction(CampAction.forage);
      expect(busy.canConsume('small_fish'), isFalse);
    });
  });

  test('seeded play with map travel and fishing stays consistent', () {
    for (var seed = 0; seed < 20; seed++) {
      final random = Random(seed);
      final game = GameEngine(
        catalog,
        world: world,
        recipes: recipes,
        random: random,
      );
      for (var step = 0; step < 400 && game.state.isAlive; step++) {
        final session = game.fishing;
        if (session != null) {
          if (session.stage == FishingStage.ready) {
            if (!game.castLine()) game.finishFishing(abandon: true);
          } else if (session.complete) {
            game.finishFishing();
          } else {
            if (session.stage == FishingStage.bite && random.nextBool()) {
              session.hook();
            }
            session.holding = session.cursor < session.target;
            session.update(.1);
          }
        } else if (game.gathering != null) {
          resolveGatheringForSimulation(game);
        } else if (game.pendingEvent != null) {
          final choices = game.pendingEvent!.choices
              .where(game.canChoose)
              .toList();
          expect(choices, isNotEmpty);
          game.choose(choices[step % choices.length].id);
        } else if (game.report != null) {
          game.continueFromReport();
        } else if (game.awaitingExpeditionDecision) {
          if (game.canGoDeeper && step % 3 != 0) {
            game.goDeeper();
          } else {
            game.returnHome();
          }
        } else if (game.canSleep) {
          game.sleep();
        } else if (game.canConsume('small_fish') &&
            game.state.value(SurvivalStat.food) < 60) {
          game.consume('small_fish');
        } else if (game.craftBlockReason('basic_rod') == null) {
          game.craft('basic_rod');
        } else if (game.travelBlockReason('fishing_pond') == null &&
            step.isEven) {
          game.travelTo('fishing_pond');
        } else if (game.travelBlockReason('riverbank') == null &&
            step % 3 == 0) {
          game.travelTo('riverbank');
        } else {
          final actions = [
            CampAction.forage,
            CampAction.rest,
          ].where(game.canAct).toList();
          expect(actions, isNotEmpty, reason: 'seed $seed step $step');
          game.startAction(actions[step % actions.length]);
        }
        for (final value in game.state.stats.values) {
          expect(value, inInclusiveRange(0, 100));
        }
        expect(game.state.timeLeft, inInclusiveRange(0, 6));
        expect(game.state.resources.values.every((v) => v >= 0), isTrue);
        if (!game.isBusy && game.state.isAlive) {
          expect(game.state.locationId, 'camp');
        }
      }
    }
  });
}
