import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/event_scene.dart';

import 'game/game_engine_test.dart' show FixedRandom;
import 'widget_test.dart' show testGame, showCamp, findUiText;

/// A hurt survivor holding a herb, standing in front of the abandoned bag
/// (four cards, one of them stat-gated).
GameEngine bagScene({int health = 50, Map<String, int>? resources}) {
  final base = testGame();
  final game = GameEngine(
    base.catalog,
    recipes: base.recipes,
    world: base.world,
    random: FixedRandom(),
    initialState: RunState(
      resources: resources ?? {'herb': 1, 'wood': 2},
      stats: {
        SurvivalStat.health: health,
        SurvivalStat.water: 40,
        SurvivalStat.food: 30,
        SurvivalStat.sanity: 60,
      },
    ),
  );
  game.startAction(CampAction.explore);
  return game;
}

void main() {
  testWidgets(
    'cards show actions and requirements without revealing their outcomes',
    (tester) async {
      final game = bagScene(health: 50, resources: {});
      await showCamp(tester, game);
      expect(find.byType(EventScene), findsOneWidget);
      expect(findUiText('Someone was here'), findsOneWidget);
      expect(find.byType(ActionCard), findsNWidgets(4));
      expect(findUiText('SAFE'), findsNothing);
      expect(find.textContaining('65%'), findsNothing);

      // The herb card is visible because the survivor is hurt, but locked.
      final tend = tester.widget<ActionCard>(
        find.byKey(const ValueKey('choice-tend')),
      );
      expect(tend.onTap, isNull);
      expect(find.textContaining('Needs 1 herb'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the healthy survivor is not offered the wound card', (
    tester,
  ) async {
    await showCamp(tester, bagScene(health: 100));
    expect(find.byKey(const ValueKey('choice-tend')), findsNothing);
    expect(find.byType(ActionCard), findsNWidgets(3));
  });

  testWidgets('playing a stat-gated card resolves it through the scene', (
    tester,
  ) async {
    final game = bagScene();
    await showCamp(tester, game);
    final tend = find.byKey(const ValueKey('choice-tend'));
    await tester.ensureVisible(tend);
    await tester.pumpAndSettle();
    await tester.tap(tend);
    await tester.pumpAndSettle();
    expect(find.byType(EventScene), findsNothing);
    expect(game.state.resource('herb'), 0);
    expect(game.state.value(SurvivalStat.health), greaterThan(50));
    expect(findUiText('Someone was here'), findsOneWidget);
  });

  testWidgets('a locked card cannot be played', (tester) async {
    final game = bagScene(resources: {});
    await showCamp(tester, game);
    final tend = find.byKey(const ValueKey('choice-tend'));
    await tester.ensureVisible(tend);
    await tester.pumpAndSettle();
    await tester.tap(tend, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(EventScene), findsOneWidget);
    expect(game.pendingEvent, isNotNull);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(768, 1024), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets('four cards fit and stay reachable at $size, text x$scale', (
      tester,
    ) async {
      await showCamp(tester, bagScene(), size: size, textScale: scale);
      expect(find.byType(ActionCard), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      final last = find.byKey(const ValueKey('choice-leave'));
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.byType(EventScene), findsNothing);
    });
  }
}
