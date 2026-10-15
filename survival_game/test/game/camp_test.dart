import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/fishing_session.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';

import 'game_engine_test.dart' show FixedRandom;

/// Like [FixedRandom], but every coin flip lands on rain.
class RainyRandom extends FixedRandom {
  @override
  double nextDouble() => .8;
  @override
  bool nextBool() => false;
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

  GameEngine engine({
    int timeLeft = 6,
    int campTier = 0,
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
      timeLeft: timeLeft,
      campTier: campTier,
      tools: tools,
      resources: resources,
      stats: stats,
    ),
  );

  Map<SurvivalStat, int> stats({
    int health = 50,
    int water = 50,
    int food = 50,
    int sanity = 50,
  }) => {
    SurvivalStat.health: health,
    SurvivalStat.water: water,
    SurvivalStat.food: food,
    SurvivalStat.sanity: sanity,
  };

  /// Ends the day with rest, resolves the night with its free choice, sleeps.
  void sleepThroughNight(GameEngine game) {
    while (game.state.timeLeft > 0) {
      game.startAction(CampAction.rest);
      game.continueFromReport();
    }
    final free = game.pendingEvent!.choices.firstWhere((c) => c.isFree);
    game.choose(free.id);
    game.continueFromReport();
    expect(game.sleep(), isTrue);
  }

  group('recipe data', () {
    test('ships tools, camp items and three ordered camp tiers', () {
      expect(recipes.campTiers.map((r) => r.tier), [1, 2, 3]);
      expect(recipes.find('camp_tier_1')!.costs, {'wood': 8, 'fiber': 6});
      expect(
        recipes.crafts.map((r) => r.id),
        containsAll([
          'basic_rod',
          'stone_knife',
          'stone_axe',
          'torch',
          'leaf_bed',
          'water_filter',
          'rain_collector',
          'drying_rack',
        ]),
      );
    });

    test('every tool an event asks for can be crafted', () {
      for (final event in catalog.events) {
        for (final choice in event.choices) {
          for (final tool in choice.requiresTools) {
            expect(recipes.find(tool), isNotNull, reason: choice.id);
          }
        }
        expect(event.choices.any((c) => c.isFree), isTrue);
      }
    });

    test('rejects duplicate ids and gaps between tiers', () {
      Recipe tier(int n) => Recipe(
        id: 'tier$n',
        name: 'Tier $n',
        kind: RecipeKind.campTier,
        tier: n,
        description: '',
        effect: '',
        costs: {'wood': 1},
        timeCost: 1,
      );
      expect(() => RecipeCatalog([tier(1), tier(1)]), throwsFormatException);
      expect(() => RecipeCatalog([tier(2)]), throwsFormatException);
    });
  });

  group('crafting', () {
    test('a tool costs resources and time, then unlocks its choices', () {
      final game = engine(resources: {'wood': 1, 'stone': 1, 'fiber': 1});
      game.startAction(CampAction.forage);
      final roots = game.pendingEvent!.choices.firstWhere(
        (c) => c.id == 'roots',
      );
      expect(game.canChoose(roots), isFalse);
      expect(game.choose('roots'), isFalse);
      game.choose('gather');
      game.continueFromReport();

      expect(game.craft('stone_knife'), isTrue);
      expect(game.state.tools, contains('stone_knife'));
      expect(game.state.resource('wood'), 0);
      expect(game.state.timeLeft, 4);
      expect(game.report!.title, 'Crafted: Stone Knife');
      game.continueFromReport();
      expect(game.craftBlockReason('stone_knife'), 'Already crafted');

      game.startAction(CampAction.forage);
      expect(game.pendingEvent!.id, isNot('berry_patch'));
    });

    test('explains every reason a recipe cannot be built yet', () {
      expect(engine().craftBlockReason('nope'), 'Unknown recipe');
      expect(
        engine(resources: {'wood': 9}).craftBlockReason('rain_collector'),
        'Needs Basic Refuge',
      );
      expect(
        engine(resources: {}).craftBlockReason('camp_tier_1'),
        'Need 8 wood, 6 fiber more',
      );
      expect(
        engine(
          resources: {'wood': 20, 'hardwood': 9, 'fiber': 20},
        ).craftBlockReason('camp_tier_2'),
        'Build Basic Refuge first',
      );
      expect(
        engine(
          timeLeft: 1,
          resources: {'wood': 8, 'fiber': 6},
        ).craftBlockReason('camp_tier_1'),
        'Need 2 daylight',
      );
      final busy = engine(resources: {'wood': 8, 'fiber': 6})
        ..startAction(CampAction.forage);
      expect(busy.craftBlockReason('camp_tier_1'), 'Return to camp first');
      expect(busy.craft('camp_tier_1'), isFalse);
    });

    test('Basic Refuge raises the camp tier and opens tier-1 recipes', () {
      final game = engine(resources: {'wood': 12, 'fiber': 10});
      expect(
        world.find('plane_wreck')!.lockReason(game.state),
        contains('Tier 1'),
      );
      expect(recipes.nextTier(game.state)!.id, 'camp_tier_1');

      expect(game.craft('camp_tier_1'), isTrue);
      expect(game.state.campTier, 1);
      expect(game.state.timeLeft, 4);
      expect(game.state.resource('wood'), 4);
      expect(game.state.resource('fiber'), 4);
      expect(game.report!.title, 'Camp upgraded: Basic Refuge');
      game.continueFromReport();

      expect(game.craftBlockReason('camp_tier_1'), 'Built');
      expect(recipes.nextTier(game.state)!.id, 'camp_tier_2');
      expect(game.craftBlockReason('drying_rack'), isNull);
      expect(game.craftBlockReason('camp_tier_2'), contains('hardwood'));
      // The wreck opens with the first camp upgrade.
      expect(world.find('plane_wreck')!.lockReason(game.state), isNull);
      expect(game.travelBlockReason('plane_wreck'), isNull);
    });

    test('crafting with empty supplies can end the run', () {
      final game = engine(
        resources: {'wood': 2, 'fiber': 3},
        stats: stats(health: 5, water: 0, food: 0),
      );
      expect(game.craft('basic_rod'), isTrue);
      expect(game.state.phase, RunPhase.gameOver);
      expect(game.state.tools, isEmpty);
    });
  });

  group('camp bonuses', () {
    test('Leaf Bed and Basic Refuge improve every sleep', () {
      final plain = engine(timeLeft: 1, stats: stats());
      sleepThroughNight(plain);
      final cozy = engine(
        timeLeft: 1,
        campTier: 1,
        tools: {'leaf_bed'},
        stats: stats(),
      );
      sleepThroughNight(cozy);
      expect(
        cozy.state.value(SurvivalStat.health) -
            plain.state.value(SurvivalStat.health),
        10,
      );
      expect(
        cozy.state.value(SurvivalStat.sanity) -
            plain.state.value(SurvivalStat.sanity),
        8,
      );
    });

    test('the Rain Collector fills at dawn, more after rain', () {
      int dawnWater(Random random) {
        final without = engine(timeLeft: 1, stats: stats(), random: random);
        sleepThroughNight(without);
        final collector = engine(
          timeLeft: 1,
          campTier: 1,
          tools: {'rain_collector'},
          stats: stats(),
          random: random,
        );
        sleepThroughNight(collector);
        return collector.state.value(SurvivalStat.water) -
            without.state.value(SurvivalStat.water);
      }

      expect(dawnWater(FixedRandom()), 5);
      expect(dawnWater(RainyRandom()), 17);
    });

    test('the camp Water Filter does not affect remote water collection', () {
      int collect(Set<String> tools) {
        final game = engine(tools: tools, stats: stats());
        game.travelTo('riverbank');
        game.choose('water');
        return game.state.value(SurvivalStat.water);
      }

      expect(collect({'water_filter'}) - collect({}), 0);
    });

    test('the Drying Rack makes each fish more filling', () {
      final rack = engine(
        campTier: 1,
        tools: {'drying_rack'},
        resources: {'small_fish': 1},
        stats: stats(),
      );
      expect(rack.consume('small_fish'), isTrue);
      expect(rack.state.value(SurvivalStat.food), 85);
    });
  });

  test('herbs heal and calm without spending daylight', () {
    final game = engine(resources: {'herb': 1}, stats: stats());
    expect(game.canConsume('herb'), isTrue);
    expect(game.consume('herb'), isTrue);
    expect(game.state.value(SurvivalStat.health), 65);
    expect(game.state.value(SurvivalStat.sanity), 56);
    expect(game.state.resource('herb'), 0);
    expect(game.state.timeLeft, 6);
    expect(game.report!.title, 'Herbal tea');
    game.continueFromReport();
    expect(game.consume('herb'), isFalse);
    expect(game.canConsume('wood'), isFalse);
  });

  group('save and restore', () {
    Map<String, dynamic> roundTrip(GameEngine game) =>
        jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;

    GameEngine restored(Map<String, dynamic> json) {
      final game = engine();
      expect(game.restore(json), isTrue);
      return game;
    }

    test('every completed step notifies the autosave', () {
      final game = engine(resources: {'wood': 2, 'fiber': 3});
      var saves = 0;
      game.onChanged = () => saves++;
      game.startAction(CampAction.forage);
      expect(saves, 1);
      game.choose(game.pendingEvent!.choices.first.id);
      expect(saves, 2);
      game.continueFromReport();
      game.craft('basic_rod');
      game.continueFromReport();
      expect(saves, 5);
    });

    test('a calm camp restores exactly', () {
      final game = engine(
        campTier: 1,
        tools: {'basic_rod', 'torch'},
        resources: {'wood': 3, 'herb': 2},
        stats: stats(health: 42),
      );
      game.startAction(CampAction.rest);
      game.continueFromReport();
      final copy = restored(roundTrip(game));
      expect(copy.state.toJson(), game.state.toJson());
      expect(copy.journal, game.journal);
      expect(copy.isBusy, isFalse);
    });

    test('a pending event resumes without a reroll or a second charge', () {
      final game = engine();
      game.travelTo('riverbank');
      final id = game.pendingEvent!.id;
      final copy = restored(roundTrip(game));
      expect(copy.pendingEvent!.id, id);
      expect(copy.state.locationId, 'riverbank');
      expect(copy.choose(copy.pendingEvent!.choices.first.id), isTrue);
      expect(copy.state.timeLeft, 4);
    });

    test('an unread outcome and the coming night survive a restart', () {
      final game = engine(timeLeft: 1);
      game.startAction(CampAction.rest);
      final copy = restored(roundTrip(game));
      expect(copy.report!.title, game.report!.title);
      expect(copy.report!.changes, game.report!.changes);
      copy.continueFromReport();
      expect(copy.state.phase, RunPhase.night);
      expect(copy.pendingEvent!.trigger, 'night');
      expect(copy.canSleep, isFalse);
    });

    test('a resolved night can still be slept through', () {
      final game = engine(timeLeft: 1);
      game.startAction(CampAction.rest);
      game.continueFromReport();
      game.choose(game.pendingEvent!.choices.firstWhere((c) => c.isFree).id);
      game.continueFromReport();
      expect(restored(roundTrip(game)).canSleep, isTrue);
    });

    test('closing the app before casting returns you to the pond', () {
      final game = engine(tools: {'basic_rod'}, resources: {'bait': 2});
      game.travelTo('fishing_pond');
      final copy = restored(roundTrip(game));
      expect(copy.fishing!.stage, FishingStage.ready);
      expect(copy.state.timeLeft, 4);
      expect(copy.castLine(), isTrue);
      expect(copy.state.resource('bait'), 1);
    });

    test('closing the app mid-cast preserves the paid cast paused', () {
      final game = engine(tools: {'basic_rod'}, resources: {'bait': 2});
      game.travelTo('fishing_pond');
      game.castLine();
      final copy = restored(roundTrip(game));
      expect(copy.fishing, isNotNull);
      expect(copy.fishing!.paused, isTrue);
      expect(
        copy.fishing!.catchRecord!.toJson(),
        game.fishing!.catchRecord!.toJson(),
      );
      expect(copy.report, isNull);
      expect(copy.state.resource('bait'), 1);
      expect(copy.state.resource('small_fish'), 0);
      expect(copy.finishFishing(abandon: true), isTrue);
      copy.continueFromReport();
      expect(copy.state.locationId, 'camp');
    });

    test('a missing night event cannot block sleep', () {
      final game = engine(timeLeft: 1);
      game.startAction(CampAction.rest);
      game.continueFromReport();
      final json = roundTrip(game)..['pendingEvent'] = 'deleted_event';
      final copy = restored(json);
      expect(copy.pendingEvent, isNull);
      expect(copy.canSleep, isTrue);
    });

    test(
      'another version or a broken save preserves the current valid run',
      () {
        final game = engine(campTier: 1);
        final old = roundTrip(game)..['version'] = 0;
        final fresh = engine();
        expect(fresh.restore(old), isFalse);
        expect(fresh.state.campTier, 0);

        final broken = roundTrip(game)..['state'] = {'day': 'three'};
        final reset = engine(campTier: 1);
        expect(reset.restore(broken), isFalse);
        expect(reset.state.campTier, 1);
        expect(reset.state.day, 1);
        expect(reset.isBusy, isFalse);
      },
    );
  });
}
