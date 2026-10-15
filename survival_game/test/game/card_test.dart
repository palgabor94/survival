import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/choice_icon.dart';
import 'package:flutter/material.dart' show Icons;

import 'game_engine_test.dart' show FixedRandom;

/// Always picks the event at [index] of the eligible pool.
class IndexRandom extends FixedRandom {
  IndexRandom(this.index);
  final int index;
  @override
  int nextInt(int max) => index.clamp(0, max - 1);
}

void main() {
  late EventCatalog catalog;
  late RecipeCatalog recipes;
  setUpAll(() {
    catalog = EventCatalog.fromJson(
      File('assets/data/events.json').readAsStringSync(),
    );
    recipes = RecipeCatalog.fromJson(
      File('assets/data/recipes.json').readAsStringSync(),
    );
  });

  GameEngine engine({
    int health = 100,
    int sanity = 80,
    int timeLeft = 6,
    Map<String, int> resources = const {'wood': 2},
    Random? random,
  }) => GameEngine(
    catalog,
    recipes: recipes,
    random: random ?? FixedRandom(),
    initialState: RunState(
      timeLeft: timeLeft,
      resources: resources,
      stats: {
        SurvivalStat.health: health,
        SurvivalStat.water: 80,
        SurvivalStat.food: 75,
        SurvivalStat.sanity: sanity,
      },
    ),
  );

  List<String> ids(GameEngine game) =>
      game.visibleChoices.map((c) => c.id).toList();

  GameEngine nightGame({int sanity = 80, int index = 0}) {
    final game = engine(
      timeLeft: 1,
      sanity: sanity,
      random: IndexRandom(index),
    );
    game.startAction(CampAction.rest);
    game.continueFromReport();
    return game;
  }

  test('no situation offers more cards than fit on a phone', () {
    for (final event in catalog.events) {
      expect(
        event.choices.length,
        inInclusiveRange(2, EventCatalog.maxChoices),
        reason: event.id,
      );
    }
  });

  test('a catalog exceeding the scrolling choice limit is rejected', () {
    GameEvent crowded() => GameEvent(
      id: 'crowded',
      trigger: 'forage',
      title: 't',
      description: 'd',
      scene: 'forage',
      choices: [
        for (var i = 0; i <= EventCatalog.maxChoices; i++)
          EventChoice(
            id: 'c$i',
            label: 'c',
            description: 'd',
            effect: EventEffect(),
            result: 'r',
          ),
      ],
    );
    expect(
      () => EventCatalog([
        crowded(),
        ...catalog.events.where((e) => e.id != 'crowded'),
      ]),
      throwsFormatException,
    );
  });

  test('a stat-gated card appears only while the stat is low', () {
    final healthy = engine()..startAction(CampAction.explore);
    expect(healthy.pendingEvent!.id, 'abandoned_bag');
    expect(ids(healthy), isNot(contains('tend')));
    final tend = healthy.pendingEvent!.choices.firstWhere(
      (c) => c.id == 'tend',
    );
    expect(healthy.canChoose(tend), isFalse);
    expect(healthy.choose('tend'), isFalse);

    final hurt = engine(health: 50, resources: {'herb': 1})
      ..startAction(CampAction.explore);
    expect(ids(hurt), contains('tend'));
    expect(hurt.visibleChoices, hasLength(4));
    expect(hurt.choose('tend'), isTrue);
    expect(hurt.state.resource('herb'), 0);
    expect(hurt.report!.changes['Health'], greaterThan(0));
  });

  test('a card needing a herb is shown but locked without one', () {
    final game = engine(health: 50, resources: {})
      ..startAction(CampAction.explore);
    final tend = game.visibleChoices.firstWhere((c) => c.id == 'tend');
    expect(game.canChoose(tend), isFalse);
    expect(game.choose('tend'), isFalse);
    expect(game.pendingEvent, isNotNull);
  });

  test('stat-gated cards unlock above their minimum', () {
    final calm = nightGame(sanity: 60, index: 1);
    expect(calm.pendingEvent!.id, 'strange_noise');
    final hold = calm.visibleChoices.firstWhere((c) => c.id == 'hold');
    expect(calm.canChoose(hold), isTrue);

    // Resting at dusk restores 12 sanity, so start well below the line.
    final shaken = nightGame(sanity: 5, index: 1);
    final lockedHold = shaken.visibleChoices.firstWhere((c) => c.id == 'hold');
    expect(shaken.canChoose(lockedHold), isFalse);
    expect(shaken.choose('hold'), isFalse);
  });

  test('a calming card shows up for a shaken survivor only', () {
    expect(nightGame(sanity: 80).pendingEvent!.id, 'fire_dying');
    expect(ids(nightGame(sanity: 80)), isNot(contains('breathe')));
    final shaken = nightGame(sanity: 20);
    expect(ids(shaken), contains('breathe'));
    expect(shaken.choose('breathe'), isTrue);
  });

  test('there is always an escape card visible and playable', () {
    for (final event in catalog.events) {
      for (final health in [100, 10]) {
        for (final sanity in [100, 5]) {
          final state = RunState(
            resources: const {},
            stats: {
              SurvivalStat.health: health,
              SurvivalStat.water: 0,
              SurvivalStat.food: 0,
              SurvivalStat.sanity: sanity,
            },
          );
          final visible = event.choices.where((c) => c.isVisible(state));
          expect(visible.any((c) => c.isFree), isTrue, reason: event.id);
        }
      }
    }
  });

  group('card icons', () {
    EventChoice choice({
      Map<SurvivalStat, int> stats = const {},
      Map<String, int> resources = const {},
      String? icon,
      String label = 'c',
    }) => EventChoice(
      id: 'c',
      label: label,
      description: 'd',
      effect: EventEffect(stats: stats, resources: resources),
      result: 'r',
      icon: icon,
    );

    test('an explicit icon key wins', () {
      expect(
        choiceIcon(choice(icon: 'torch', stats: {SurvivalStat.water: 30})),
        Icons.local_fire_department_rounded,
      );
    });

    test('hidden rewards never determine the icon; the action label does', () {
      expect(
        choiceIcon(choice(stats: {SurvivalStat.water: 35})),
        Icons.arrow_forward_rounded,
      );
      expect(
        choiceIcon(choice(resources: {'wood': 2})),
        Icons.arrow_forward_rounded,
      );
      expect(
        choiceIcon(choice(label: 'Collect water', resources: {'wood': 99})),
        Icons.water_drop_rounded,
      );
      expect(
        choiceIcon(
          choice(label: 'Gather wood', stats: {SurvivalStat.water: 99}),
        ),
        Icons.forest_rounded,
      );
      expect(choiceIcon(choice()), Icons.arrow_forward_rounded);
      expect(
        choiceIcon(choice(icon: 'unknown_key')),
        Icons.arrow_forward_rounded,
      );
    });
  });
}
