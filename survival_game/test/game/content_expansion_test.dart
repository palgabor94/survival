import 'dart:convert';
import 'gathering_test.dart' show resolveGatheringForSimulation;
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';

import 'game_engine_test.dart' show FixedRandom;

class ExpansionRoll extends FixedRandom {
  ExpansionRoll({this.fail = false});
  final bool fail;
  var calls = 0;
  @override
  double nextDouble() => calls++ == 0 ? 0 : (fail ? .999 : 0);
}

void main() {
  final catalog = EventCatalog.fromJson(
    File('assets/data/events.json').readAsStringSync(),
  );
  final world = WorldCatalog.fromJson(
    File('assets/data/locations.json').readAsStringSync(),
  );
  final recipes = RecipeCatalog.fromJson(
    File('assets/data/recipes.json').readAsStringSync(),
  );
  const dangers = ['crocodile_shallows', 'hornet_nest', 'monkey_raiders'];
  const stops = [
    'bamboo_shoots',
    'bamboo_tangle',
    'mangrove_driftwood',
    'mangrove_root_pool',
  ];

  GameEngine make({EventCatalog? content, Random? random, RunState? state}) =>
      GameEngine(
        content ?? catalog,
        world: world,
        recipes: recipes,
        random: random ?? FixedRandom(.999),
        initialState:
            state ??
            RunState(
              day: 3,
              campTier: 1,
              tools: recipes.recipes.map((r) => r.id).toSet(),
              resources: {
                'wood': 20,
                'fiber': 20,
                'stone': 20,
                'bait': 20,
                'herb': 20,
                'raw_meat': 20,
                'small_fish': 20,
              },
              stats: {for (final s in SurvivalStat.values) s: 80},
            ),
      );

  void arrival(GameEngine game, String location) {
    expect(
      game.travelTo(
        location,
        pack: {
          ...game.recommendedPack(location),
          if (game.state.resource('small_fish') > 0) 'small_fish': 1,
        },
      ),
      isTrue,
    );
    final safe = game.visibleChoices.firstWhere(
      (c) => game.canChoose(c) && !c.effect.endsExpedition,
    );
    expect(game.choose(safe.id), isTrue);
    expect(game.continueFromReport(), isTrue);
    expect(game.awaitingExpeditionDecision, isTrue);
  }

  GameEngine encounter(String id, {bool fail = false, RunState? state}) {
    final event = catalog.events.firstWhere((e) => e.id == id);
    final content = EventCatalog(
      catalog.events
          .where((e) => e.trigger != 'encounter' || e.id == id)
          .toList(),
    );
    final game = make(
      content: content,
      random: ExpansionRoll(fail: fail),
      state: state,
    );
    arrival(game, event.locations.first);
    expect(game.goDeeper(), isTrue);
    expect(game.pendingEvent!.id, id);
    return game;
  }

  void bounds(GameEngine game) {
    expect(game.state.timeLeft, inInclusiveRange(0, RunState.dayLength));
    for (final s in SurvivalStat.values) {
      expect(game.state.value(s), inInclusiveRange(0, 100));
    }
    for (final value in game.state.resources.values) {
      expect(value, greaterThanOrEqualTo(0));
    }
    for (final value in game.expedition?.loot.values ?? <int>[]) {
      expect(value, greaterThan(0));
    }
  }

  test(
    'new routes unlock at day two and camp tier one with distinct scenes',
    () {
      final bamboo = world.find('bamboo_grove')!;
      final mangrove = world.find('mangrove_shallows')!;
      expect(bamboo.lockReason(RunState()), 'Discover on day 2.');
      expect(bamboo.isUnlocked(RunState(day: 2)), isTrue);
      expect(mangrove.isUnlocked(RunState(day: 3)), isFalse);
      expect(mangrove.isUnlocked(RunState(day: 3, campTier: 1)), isTrue);
      expect(bamboo.background, isNot(mangrove.background));
      for (final location in [bamboo, mangrove]) {
        expect(File(location.background!).existsSync(), isTrue);
      }
    },
  );

  for (final location in ['bamboo_grove', 'mangrove_shallows']) {
    test(
      '$location has distinct arrival and deeper stops; travel charged once',
      () {
        final game = make();
        expect(
          game.travelTo(
            location,
            pack: {
              ...game.recommendedPack(location),
              if (game.state.resource('small_fish') > 0) 'small_fish': 1,
            },
          ),
          isTrue,
        );
        final first = game.pendingEvent!.id;
        expect(game.state.timeLeft, 6);
        final cost = game.pendingCost;
        final choice = game.visibleChoices.firstWhere(
          (c) => game.canChoose(c) && !c.effect.endsExpedition,
        );
        expect(game.choose(choice.id), isTrue);
        expect(game.state.timeLeft, 6 - cost);
        expect(game.choose(choice.id), isFalse);
        game.continueFromReport();
        expect(game.goDeeper(), isTrue);
        expect(game.pendingEvent!.id, isNot(first));
        expect(stops, contains(game.pendingEvent!.id));
        expect(game.pendingCost, 1);
        bounds(game);
      },
    );
  }

  for (final id in dangers) {
    final event = catalog.events.firstWhere((e) => e.id == id);
    for (final choice in event.choices) {
      for (final fail in choice.isRisky ? [false, true] : [false]) {
        test(
          '$id / ${choice.id} / ${fail ? 'failure' : 'success'} resolves once and reports actual result',
          () {
            final game = encounter(id, fail: fail);
            final before = game.state;
            expect(game.canChoose(choice), isTrue);
            expect(game.choose(choice.id), isTrue);
            expect(game.pendingEvent, isNull);
            expect(game.choose(choice.id), isFalse);
            expect(game.state.timeLeft, before.timeLeft);
            final result = fail ? choice.failureResult! : choice.result;
            final wornTools = choice.requiresTools
                .where(RunState.toolDurability.containsKey)
                .toList();
            expect(
              game.report!.body,
              wornTools.isEmpty ? equals(result) : startsWith(result),
            );
            for (final tool in wornTools) {
              expect(
                game.state.toolCondition(tool),
                before.toolCondition(tool) - 1,
              );
              expect(game.report!.body, contains('durability:'));
            }
            final effect = fail ? choice.failureEffect! : choice.effect;
            if (effect.endsExpedition) expect(game.expedition, isNull);
            for (final e in effect.resources.entries.where(
              (e) => e.value < 0,
            )) {
              expect(
                game.state.resource(e.key),
                lessThanOrEqualTo(before.resource(e.key) + e.value),
              );
            }
            bounds(game);
            expect(game.continueFromReport(), isTrue);
            if (effect.endsExpedition) {
              expect(game.state.locationId, 'camp');
            } else {
              expect(game.pendingEvent!.trigger, 'explore');
              expect(game.pendingCost, 1);
            }
          },
        );
      }
    }

    test('$id restores its pending encounter and haul', () {
      final game = encounter(id);
      final copy = make();
      expect(copy.restore(jsonDecode(jsonEncode(game.toJson()))), isTrue);
      expect(copy.pendingEvent!.id, id);
      expect(copy.pendingCost, 0);
      expect(copy.expedition!.loot, game.expedition!.loot);
      final fallback = copy.visibleChoices.firstWhere((c) => c.isFree);
      expect(copy.choose(fallback.id), isTrue);
      expect(copy.report, isNotNull);
      bounds(copy);
    });
  }

  test(
    'spent gathered fiber is not lost again; camp supplies survive a stolen pack',
    () {
      final content = EventCatalog(
        catalog.events
            .where(
              (e) =>
                  e.trigger != 'encounter' ||
                  ['hornet_nest', 'monkey_raiders'].contains(e.id),
            )
            .toList(),
      );
      final game = make(
        content: content,
        random: FixedRandom(),
        state: RunState(
          day: 3,
          campTier: 1,
          resources: {'fiber': 5},
          stats: {for (final s in SurvivalStat.values) s: 100},
        ),
      );
      expect(game.travelTo('bamboo_grove'), isTrue);
      expect(game.choose('gather'), isTrue);
      game.continueFromReport();
      expect(game.state.resource('fiber'), 8);
      expect(game.expedition!.loot['fiber'], 3);
      game.goDeeper();
      expect(game.pendingEvent!.id, 'hornet_nest');
      expect(game.choose('cover'), isTrue);
      expect(game.state.resource('fiber'), 6);
      expect(game.expedition!.loot['fiber'], 1);
      game.continueFromReport();
      expect(game.choose('crawl'), isTrue);
      game.continueFromReport();
      game.goDeeper();
      expect(game.pendingEvent!.id, 'monkey_raiders');
      expect(game.choose('leave'), isTrue);
      expect(game.state.resource('fiber'), 5);
      expect(game.expedition, isNull);
    },
  );

  test('fatal encounter still retains the result before run end', () {
    final game = encounter(
      'crocodile_shallows',
      fail: true,
      state: RunState(
        day: 3,
        campTier: 1,
        tools: {'stone_spear'},
        stats: {
          SurvivalStat.health: 1,
          SurvivalStat.water: 100,
          SurvivalStat.food: 100,
          SurvivalStat.sanity: 100,
        },
      ),
    );
    expect(game.choose('spear'), isTrue);
    expect(game.state.isAlive, isFalse);
    expect(game.report, isNotNull);
    expect(game.report!.changes['Health'], -1);
    expect(game.choose('retreat'), isFalse);
    bounds(game);
  });

  test(
    '200 seeded runs exercise routes, events, save/restore and bounded transactions',
    () {
      var transactions = 0;
      var restores = 0;
      final visited = <String>{};
      for (var seed = 0; seed < 200; seed++) {
        final decisions = Random(seed + 400);
        var game = make(random: Random(seed));
        for (
          var step = 0;
          step < 250 && (game.state.isAlive || game.report != null);
          step++
        ) {
          bounds(game);
          if (step % 17 == 0) {
            final copy = make(random: Random(seed + step));
            expect(copy.restore(jsonDecode(jsonEncode(game.toJson()))), isTrue);
            expect(copy.state.toJson(), game.state.toJson());
            expect(copy.pendingEvent?.id, game.pendingEvent?.id);
            expect(copy.report?.body, game.report?.body);
            expect(copy.expedition?.loot, game.expedition?.loot);
            game = copy;
            restores++;
          }
          if (game.report != null) {
            expect(game.continueFromReport(), isTrue);
          } else if (game.gathering != null) {
            resolveGatheringForSimulation(game);
          } else if (game.pendingEvent != null) {
            visited.add(game.pendingEvent!.id);
            final choices = game.visibleChoices.where(game.canChoose).toList();
            expect(choices, isNotEmpty);
            expect(
              game.choose(choices[decisions.nextInt(choices.length)].id),
              isTrue,
            );
          } else if (game.awaitingExpeditionDecision) {
            if (game.canGoDeeper && decisions.nextBool()) {
              expect(game.goDeeper(), isTrue);
            } else {
              expect(game.returnHome(), isTrue);
            }
          } else if (game.canSleep) {
            expect(game.sleep(), isTrue);
          } else {
            final routes = world.locations
                .where(
                  (l) =>
                      !['camp', 'fishing_pond'].contains(l.id) &&
                      game.travelBlockReason(l.id) == null,
                )
                .toList();
            if (routes.isNotEmpty && decisions.nextBool()) {
              expect(
                game.travelTo(routes[decisions.nextInt(routes.length)].id),
                isTrue,
              );
            } else {
              final actions = CampAction.values.where(game.canAct).toList();
              expect(actions, isNotEmpty, reason: 'seed $seed / step $step');
              expect(
                game.startAction(actions[decisions.nextInt(actions.length)]),
                isTrue,
              );
            }
          }
          transactions++;
        }
        bounds(game);
      }
      expect(transactions, greaterThan(4000));
      expect(restores, greaterThan(200));
      expect(visited, containsAll([...stops, ...dangers]));
      // Recorded in the expanded test log for the final validation report.
      stdout.writeln(
        'SIMULATION: $transactions transactions, $restores restores, ${visited.length} event types across 200 runs',
      );
    },
  );
}
