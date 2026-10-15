import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';

import 'game_engine_test.dart' show FixedRandom;

/// Rolls 0.99 for chances (no encounter) and picks the first event.
class QuietRandom extends FixedRandom {
  QuietRandom() : super(.99);
}

/// Rolls 0 for chances (always an encounter) and picks the first event.
class DangerousRandom extends FixedRandom {
  DangerousRandom() : super(0);
}

/// Picks the event at [index] and never lets a roll go the player's way.
class PickRandom extends FixedRandom {
  PickRandom(this.index, {double roll = 0}) : super(roll);
  final int index;
  @override
  int nextInt(int max) => index.clamp(0, max - 1);
}

void main() {
  late EventCatalog catalog;
  late WorldCatalog world;
  late RecipeCatalog recipes;
  setUpAll(() {
    catalog = EventCatalog.fromJson(
      File('assets/data/events.json').readAsStringSync(),
    );
    world = WorldCatalog.fromJson(
      File('assets/data/locations.json').readAsStringSync(),
    );
    recipes = RecipeCatalog.fromJson(
      File('assets/data/recipes.json').readAsStringSync(),
    );
  });

  GameEngine trip({
    Random? random,
    Set<String> tools = const {},
    Map<String, int> resources = const {},
    int campTier = 0,
    int health = 100,
  }) {
    final game = GameEngine(
      catalog,
      world: world,
      recipes: recipes,
      random: random ?? QuietRandom(),
      initialState: RunState(
        campTier: campTier,
        tools: tools,
        resources: resources,
        stats: {
          SurvivalStat.health: health,
          SurvivalStat.water: 80,
          SurvivalStat.food: 75,
          SurvivalStat.sanity: 80,
        },
      ),
    );
    return game;
  }

  /// Walks the first step of the Riverbank and lands on the decision.
  void firstStop(GameEngine game) {
    expect(game.travelTo('riverbank', pack: game.state.resources), isTrue);
    game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
    game.continueFromReport();
    expect(game.awaitingExpeditionDecision, isTrue);
  }

  group('the decision', () {
    test('after a stop you may return or press on, never both', () {
      final game = trip();
      firstStop(game);
      expect(game.expedition!.depth, 0);
      expect(game.isBusy, isTrue);
      expect(game.canAct(CampAction.forage), isFalse);
      expect(game.travelTo('riverbank'), isFalse);
      expect(game.returnHome(), isTrue);
      expect(game.returnHome(), isFalse);
      expect(game.goDeeper(), isFalse);
    });

    test('going deeper costs a step of daylight and supplies', () {
      final game = trip();
      firstStop(game);
      final time = game.state.timeLeft;
      final water = game.state.value(SurvivalStat.water);
      expect(game.goDeeper(), isTrue);
      expect(game.expedition!.depth, 1);
      expect(game.pendingCost, 1);
      expect(game.pendingEvent!.minDepth, lessThanOrEqualTo(1));
      game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
      expect(game.state.timeLeft, time - 1);
      expect(game.state.value(SurvivalStat.water), lessThan(water));
    });

    test('there is no going deeper without daylight', () {
      final game = trip();
      firstStop(game);
      game.goDeeper();
      game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
      game.continueFromReport();
      // 2 (arrival) + 1 (deeper) = 3 of 6 time spent so far.
      for (var i = 0; i < 3 && game.canGoDeeper; i++) {
        game.goDeeper();
        game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
        game.continueFromReport();
      }
      expect(game.state.timeLeft, 0);
      expect(game.canGoDeeper, isFalse);
      expect(game.awaitingExpeditionDecision, isFalse);
      expect(game.expedition, isNull);
      expect(game.state.phase, RunPhase.night);
    });

    test('a trip that runs out the day heads home into the night', () {
      final game = trip();
      firstStop(game);
      while (game.canGoDeeper) {
        game.goDeeper();
        game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
        game.continueFromReport();
      }
      expect(game.state.timeLeft, 0);
      expect(game.state.phase, RunPhase.night);
      expect(game.state.locationId, 'camp');
      expect(game.expedition, isNull);
      expect(game.pendingEvent!.trigger, 'night');
    });

    test('everything gathered is carried home and listed', () {
      final game = trip();
      firstStop(game);
      final wood = game.state.resource('wood');
      expect(game.expedition!.loot, isNotEmpty);
      game.returnHome();
      expect(game.report!.title, 'Home with the haul');
      expect(game.report!.changes, isNotEmpty);
      game.continueFromReport();
      expect(game.state.resource('wood'), wood);
      expect(game.state.locationId, 'camp');
      expect(game.expedition, isNull);
    });
  });

  group('danger', () {
    test('deeper steps can meet an encounter first, and then the stop', () {
      final game = trip(random: DangerousRandom());
      firstStop(game);
      expect(game.nextEncounterChance, closeTo(.4, .001));
      game.goDeeper();
      expect(game.pendingEvent!.trigger, 'encounter');
      expect(game.pendingCost, 0);
      expect(
        game.pendingEvent!.choices.length,
        lessThanOrEqualTo(EventCatalog.maxChoices),
      );

      // Whatever the danger, there is always a card that can be played.
      expect(game.visibleChoices.any((c) => c.isFree), isTrue);
    });

    test('no encounter ever happens on the first stop', () {
      for (var seed = 0; seed < 20; seed++) {
        final game = trip(random: Random(seed));
        game.travelTo('riverbank');
        expect(game.pendingEvent!.trigger, 'explore');
        expect(game.pendingEvent!.minDepth, 0);
      }
    });

    test('the chance of trouble rises with every step and is capped', () {
      final game = trip();
      firstStop(game);
      final chances = <double>[game.nextEncounterChance];
      for (var i = 0; i < 2; i++) {
        game.goDeeper();
        game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
        game.continueFromReport();
        if (!game.awaitingExpeditionDecision) break;
        chances.add(game.nextEncounterChance);
      }
      for (var i = 1; i < chances.length; i++) {
        expect(chances[i], greaterThan(chances[i - 1]));
      }
      expect(chances.every((c) => c <= .8), isTrue);
    });
  });

  /// Meets the jaguar (the first encounter) with the given gear.
  GameEngine meetJaguar({
    Set<String> tools = const {},
    Map<String, int> resources = const {},
    Random? random,
  }) {
    final game = trip(
      tools: tools,
      resources: resources,
      random: random ?? DangerousRandom(),
    );
    firstStop(game);
    game.goDeeper();
    expect(game.pendingEvent!.id, 'jaguar_trail');
    return game;
  }

  group('a jaguar blocks the trail', () {
    test('your gear decides which cards you have', () {
      final bare = meetJaguar();
      final ids = bare.visibleChoices.map((c) => c.id);
      expect(ids, containsAll(['torch', 'spear', 'meat', 'flee']));
      bool usable(GameEngine g, String id) =>
          g.canChoose(g.visibleChoices.firstWhere((c) => c.id == id));
      expect(usable(bare, 'torch'), isFalse);
      expect(usable(bare, 'spear'), isFalse);
      expect(usable(bare, 'meat'), isFalse);
      expect(usable(bare, 'flee'), isTrue);

      final geared = meetJaguar(
        tools: {'torch', 'stone_spear'},
        resources: {'raw_meat': 1},
      );
      expect(usable(geared, 'torch'), isTrue);
      expect(usable(geared, 'spear'), isTrue);
      expect(usable(geared, 'meat'), isTrue);
    });

    test('the torch scares it off and the trip goes on', () {
      final game = meetJaguar(tools: {'torch'});
      final loot = game.expedition!.loot.length;
      expect(game.choose('torch'), isTrue);
      expect(game.state.value(SurvivalStat.health), 100);
      game.continueFromReport();
      // The danger is past, and the stop it guarded is still ahead.
      expect(game.pendingEvent!.trigger, 'explore');
      expect(game.expedition, isNotNull);
      expect(game.pendingCost, 1);
      expect(game.expedition!.loot.length, loot);
    });

    test('meat is spent to get past without a fight', () {
      final game = meetJaguar(resources: {'raw_meat': 1});
      expect(game.choose('meat'), isTrue);
      expect(game.state.resource('raw_meat'), 0);
      expect(game.state.value(SurvivalStat.health), 100);
    });

    test('a won fight brings meat, a lost one costs blood and the pack', () {
      final won = meetJaguar(
        tools: {'stone_spear'},
        random: PickRandom(0, roll: 0),
      );
      expect(won.choose('spear'), isTrue);
      expect(won.state.resource('raw_meat'), 2);
    });

    test('losing a fight drops everything gathered and ends the trip', () {
      final game = trip(tools: {'stone_spear'}, random: _Sequence([0, .95]));
      firstStop(game);
      final carried = Map<String, int>.of(game.expedition!.loot);
      final before = {
        for (final id in carried.keys) id: game.state.resource(id),
      };
      expect(carried, isNotEmpty);
      game.goDeeper();
      expect(game.pendingEvent!.id, 'jaguar_trail');
      expect(game.choose('spear'), isTrue);
      expect(game.state.value(SurvivalStat.health), 76);
      for (final id in carried.keys) {
        expect(game.state.resource(id), before[id]! - carried[id]!);
      }
      expect(game.expedition, isNull);
      game.continueFromReport();
      expect(game.state.locationId, 'camp');
      expect(game.awaitingExpeditionDecision, isFalse);
    });

    test('fleeing is always possible and costs the pack', () {
      final game = meetJaguar();
      final wood = game.state.resource('wood');
      final gained = game.expedition!.loot['wood'] ?? 0;
      expect(game.choose('flee'), isTrue);
      expect(game.state.value(SurvivalStat.sanity), lessThan(80));
      expect(game.state.resource('wood'), wood - gained);
      expect(game.expedition, isNull);
      game.continueFromReport();
      expect(game.state.locationId, 'camp');
      expect(game.isBusy, isFalse);
    });

    test('a bite is treated with a herb only while hurt', () {
      final game = trip(
        random: PickRandom(1, roll: 0),
        resources: {'herb': 1},
        health: 50,
      );
      firstStop(game);
      game.goDeeper();
      expect(game.pendingEvent!.id, 'snake_thicket');
      final treat = game.visibleChoices.firstWhere((c) => c.id == 'treat');
      expect(game.canChoose(treat), isTrue);
      game.choose('treat');
      expect(game.state.value(SurvivalStat.health), greaterThan(50));
      expect(game.state.resource('herb'), 0);

      final healthy = trip(random: PickRandom(1, roll: 0));
      firstStop(healthy);
      healthy.goDeeper();
      expect(healthy.visibleChoices.map((c) => c.id), isNot(contains('treat')));
    });
  });

  group('a trip survives closing the app', () {
    Map<String, dynamic> roundTrip(GameEngine game) =>
        jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;

    GameEngine restored(Map<String, dynamic> json) {
      final game = trip();
      expect(game.restore(json), isTrue);
      return game;
    }

    test('mid-decision, with the pack and depth intact', () {
      final game = trip();
      firstStop(game);
      game.goDeeper();
      game.choose(game.visibleChoices.firstWhere(game.canChoose).id);
      game.continueFromReport();
      final copy = restored(roundTrip(game));
      expect(copy.awaitingExpeditionDecision, isTrue);
      expect(copy.expedition!.depth, game.expedition!.depth);
      expect(copy.expedition!.loot, game.expedition!.loot);
      expect(copy.state.locationId, game.state.locationId);
      expect(copy.returnHome(), isTrue);
    });

    test('mid-encounter, with the danger still ahead and no time charged', () {
      final game = meetJaguar();
      final timeLeft = game.state.timeLeft;
      final copy = restored(roundTrip(game));
      expect(copy.pendingEvent!.id, 'jaguar_trail');
      expect(copy.pendingCost, 0);
      expect(copy.expedition!.depth, 1);
      expect(copy.choose('flee'), isTrue);
      expect(copy.state.timeLeft, timeLeft);
    });

    test('a damaged trip falls back to camp instead of getting stuck', () {
      final game = trip();
      firstStop(game);
      final json = roundTrip(game)
        ..['expedition'] = {'locationId': 'nowhere', 'depth': 1, 'loot': {}}
        ..['decision'] = true;
      final copy = restored(json);
      expect(copy.expedition, isNull);
      expect(copy.awaitingExpeditionDecision, isFalse);
      expect(copy.state.locationId, 'camp');
    });
  });

  test('the Plane Wreck needs the first camp upgrade and 3 daylight', () {
    expect(
      trip().travelBlockReason('plane_wreck'),
      contains('Requires Camp Tier 1'),
    );
    final game = trip(campTier: 1);
    expect(game.travelBlockReason('plane_wreck'), isNull);
    expect(game.travelTo('plane_wreck'), isTrue);
    expect(game.pendingEvent!.locations, contains('plane_wreck'));
    expect(game.pendingCost, 3);
    game.choose('search');
    expect(game.state.resource('metal_scrap'), 2);
    expect(game.state.timeLeft, 3);
  });

  test('deep riverbank stops can yield hardwood for camp upgrades', () {
    final game = trip(tools: {'stone_axe'}, random: PickRandom(0, roll: .99));
    firstStop(game);
    game.goDeeper();
    // First deeper explore event: hardwood grove.
    expect(game.pendingEvent!.id, 'hardwood_grove');
    game.choose('chop');
    expect(game.state.resource('hardwood'), 3);
    expect(recipes.find('camp_tier_2')!.costs['hardwood'], 4);
  });

  test('raw meat can be cooked and eaten at camp', () {
    final game = trip(resources: {'raw_meat': 2});
    expect(game.canConsume('raw_meat'), isTrue);
    expect(game.consume('raw_meat'), isTrue);
    expect(game.state.value(SurvivalStat.food), 97);
    expect(game.state.resource('raw_meat'), 1);
  });
}

/// Hands out the given values to successive `nextDouble` calls.
class _Sequence extends FixedRandom {
  _Sequence(this.values);
  final List<double> values;
  var _i = 0;
  @override
  double nextDouble() => values[_i < values.length ? _i++ : values.length - 1];
}
