import 'dart:io';
import 'gathering_test.dart' show resolveGatheringForSimulation;
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';

class FixedRandom implements Random {
  FixedRandom([this.roll = 0]);
  final double roll;
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => roll;
  @override
  int nextInt(int max) => 0;
}

void main() {
  late EventCatalog catalog;
  setUp(
    () => catalog = EventCatalog.fromJson(
      File('assets/data/events.json').readAsStringSync(),
    ),
  );

  RunState stateWith({
    int health = 100,
    int water = 80,
    int food = 75,
    int sanity = 80,
    int timeLeft = 6,
    Map<String, int>? resources,
  }) => RunState(
    timeLeft: timeLeft,
    resources: resources,
    stats: {
      SurvivalStat.health: health,
      SurvivalStat.water: water,
      SurvivalStat.food: food,
      SurvivalStat.sanity: sanity,
    },
  );

  test('all shipped events are valid and have an affordable fallback', () {
    expect(catalog.events, hasLength(37));
    for (final event in catalog.events) {
      expect(event.choices.any((c) => c.requires.isEmpty), isTrue);
    }
  });

  test('decision is atomic, spends time once, and rejects repeated input', () {
    final game = GameEngine(catalog, random: FixedRandom());
    expect(game.startAction(CampAction.forage), isTrue);
    expect(game.state.timeLeft, 6);
    expect(game.startAction(CampAction.explore), isFalse);
    expect(game.choose('missing'), isFalse);
    expect(game.choose('gather'), isTrue);
    expect(game.state.timeLeft, 5);
    expect(game.state.value(SurvivalStat.food), 92);
    expect(game.state.value(SurvivalStat.water), 76);
    expect(game.state.resource('fiber'), 1);
    expect(game.choose('gather'), isFalse);
    expect(game.startAction(CampAction.rest), isFalse);
    expect(game.report!.changes['Food'], 17);
    game.continueFromReport();
    expect(game.canAct(CampAction.rest), isTrue);
  });

  test('six time leads to one night event, sleep then resets daylight', () {
    final game = GameEngine(catalog, random: FixedRandom());
    for (var i = 0; i < 6; i++) {
      game.startAction(CampAction.rest);
      game.continueFromReport();
    }
    expect(game.state.phase, RunPhase.night);
    expect(game.pendingEvent!.trigger, 'night');
    expect(game.canSleep, isFalse);
    expect(game.startAction(CampAction.rest), isFalse);
    expect(game.choose('wood'), isTrue);
    expect(game.state.resource('wood'), 0);
    expect(game.canSleep, isFalse);
    game.continueFromReport();
    expect(game.canSleep, isTrue);
    expect(game.sleep(), isTrue);
    expect(game.state.day, 2);
    expect(game.state.timeLeft, 6);
    expect(game.state.value(SurvivalStat.water), 46);
    expect(game.state.value(SurvivalStat.food), 49);
    expect(game.sleep(), isFalse);
    game.continueFromReport();
    expect(game.canAct(CampAction.explore), isTrue);
  });

  test('insufficient daylight prevents exploration but still allows rest', () {
    final game = GameEngine(catalog, initialState: stateWith(timeLeft: 1));
    expect(game.startAction(CampAction.explore), isFalse);
    expect(game.state.timeLeft, 1);
    expect(game.startAction(CampAction.rest), isTrue);
  });

  test(
    'requirements disable spending unavailable resources without blocking free choice',
    () {
      final game = GameEngine(
        catalog,
        random: FixedRandom(),
        initialState: stateWith(timeLeft: 1, resources: {}),
      );
      game.startAction(CampAction.rest);
      game.continueFromReport();
      expect(game.pendingEvent!.id, 'fire_dying');
      expect(game.choose('wood'), isFalse);
      expect(game.choose('dark'), isTrue);
      expect(game.state.resource('wood'), 0);
    },
  );

  test('risk succeeds or fails and low sanity reduces displayed chance', () {
    final successful = GameEngine(catalog, random: FixedRandom(0.6));
    successful.startAction(CampAction.forage);
    successful.choose('risk');
    expect(successful.state.value(SurvivalStat.health), 100);
    final anxious = GameEngine(
      catalog,
      random: FixedRandom(0.6),
      initialState: stateWith(sanity: 20),
    );
    anxious.startAction(CampAction.forage);
    expect(
      anxious.chanceFor(
        anxious.pendingEvent!.choices.firstWhere((c) => c.id == 'risk'),
      ),
      closeTo(.55, .001),
    );
    anxious.choose('risk');
    expect(anxious.state.value(SurvivalStat.health), 84);
    expect(anxious.state.value(SurvivalStat.sanity), 15);
  });

  test('empty supplies cause damage per time and health zero ends the run', () {
    final game = GameEngine(
      catalog,
      initialState: stateWith(health: 10, water: 0, food: 0),
    );
    game.startAction(CampAction.rest);
    expect(game.state.value(SurvivalStat.health), 0);
    expect(game.state.phase, RunPhase.gameOver);
    expect(game.report, isNotNull);
    expect(game.report!.changes['Health'], -10);
    game.continueFromReport();
    expect(game.report, isNull);
    expect(game.state.phase, RunPhase.gameOver);
    expect(game.startAction(CampAction.forage), isFalse);
    expect(game.sleep(), isFalse);
    game.restart();
    expect(game.state.day, 1);
    expect(game.state.timeLeft, 6);
    expect(game.state.value(SurvivalStat.health), 100);
    expect(game.journal, hasLength(1));
    expect(game.canAct(CampAction.explore), isTrue);
  });

  test('stats clamp to 100 and reports show actual changes', () {
    final game = GameEngine(
      catalog,
      initialState: stateWith(health: 99, sanity: 99),
    );
    game.startAction(CampAction.rest);
    expect(game.state.value(SurvivalStat.health), 100);
    expect(game.report!.changes['Health'], 1);
    expect(game.state.value(SurvivalStat.sanity), 100);
    expect(game.report!.changes['Sanity'], 1);
  });

  test('catalog filters progression and stat requirements', () {
    expect(
      catalog.eligible('explore', RunState()).map((e) => e.id),
      isNot(contains('broken_bridge')),
    );
    expect(
      catalog.eligible('explore', RunState(day: 2)).map((e) => e.id),
      contains('broken_bridge'),
    );
    expect(
      catalog.eligible('explore', stateWith(water: 20)).map((e) => e.id),
      contains('low_water'),
    );
  });

  test('events do not repeat immediately when alternatives exist', () {
    final game = GameEngine(catalog, random: FixedRandom());
    game.startAction(CampAction.forage);
    final id = game.pendingEvent!.id;
    game.choose(game.pendingEvent!.choices.first.id);
    game.continueFromReport();
    game.startAction(CampAction.forage);
    expect(game.pendingEvent!.id, isNot(id));
  });

  test('seeded multi-day play never escapes bounds or deadlocks', () {
    for (var seed = 0; seed < 20; seed++) {
      final game = GameEngine(catalog, random: Random(seed));
      for (var step = 0; step < 300 && game.state.isAlive; step++) {
        if (game.gathering != null) {
          resolveGatheringForSimulation(game);
        } else if (game.pendingEvent != null) {
          final choices = game.pendingEvent!.choices
              .where(game.canChoose)
              .toList();
          expect(choices, isNotEmpty);
          game.choose(choices[step % choices.length].id);
        } else if (game.report != null) {
          game.continueFromReport();
        } else if (game.canSleep) {
          game.sleep();
        } else {
          final actions = CampAction.values.where(game.canAct).toList();
          expect(actions, isNotEmpty);
          game.startAction(actions[step % actions.length]);
        }
        for (final value in game.state.stats.values) {
          expect(value, inInclusiveRange(0, 100));
        }
        expect(game.state.timeLeft, inInclusiveRange(0, 6));
        expect(game.state.resources.values.every((v) => v >= 0), isTrue);
      }
    }
  });
}
