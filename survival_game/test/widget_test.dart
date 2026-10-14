import 'expedition_widget_test.dart' show confirmCard;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';
import 'package:survival_game/main.dart';
import 'package:survival_game/ui/camp_widgets.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/event_scene.dart';

/// Match user-facing copy independently of the shared uppercase title style.
Finder findUiText(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text && widget.data?.toLowerCase() == text.toLowerCase(),
);

GameEngine testGame({RunState? state}) => GameEngine(
  EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
  random: Random(42),
  initialState: state,
  world: WorldCatalog.fromJson(
    File('assets/data/locations.json').readAsStringSync(),
  ),
  recipes: RecipeCatalog.fromJson(
    File('assets/data/recipes.json').readAsStringSync(),
  ),
);

Future<void> showCamp(
  WidgetTester tester,
  GameEngine engine, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: LostCanopyApp(engine: engine),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapAction(WidgetTester tester, String id) async {
  final action = find.byKey(ValueKey('action-$id'));
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads shipped content and presents the camp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
    await tester.pumpWidget(const LostCanopyApp(enableAudio: false));
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(findUiText('DAY 1'), findsOneWidget);
    expect(findUiText('Crash Shelter'), findsNothing);
    expect(findUiText('LOST CANOPY'), findsNothing);
    expect(find.byType(StatTile), findsNWidgets(4));
    expect(find.byType(CampActionCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('camp fits and actions remain reachable at $size', (
      tester,
    ) async {
      final game = testGame();
      await showCamp(tester, game, size: size);
      expect(tester.takeException(), isNull);
      await tapAction(tester, 'rest');
      expect(findUiText('A moment of quiet'), findsOneWidget);
      expect(game.state.timeLeft, 5);
      final outcome = find.byKey(const ValueKey('continue-outcome'));
      await tester.ensureVisible(outcome);
      await tester.pumpAndSettle();
      await tester.tap(outcome);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large text and reduced motion preserve readable controls', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await showCamp(
      tester,
      testGame(),
      size: const Size(375, 667),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tapAction(tester, 'forage');
    expect(find.byType(ActionCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'event selection and outcome return to camp without double spending',
    (tester) async {
      final game = testGame();
      await showCamp(tester, game);
      await tapAction(tester, 'forage');
      expect(game.pendingEvent, isNotNull);
      final choice = find
          .descendant(
            of: find.byType(EventScene),
            matching: find.byType(ActionCard),
          )
          .first;
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      await confirmCard(tester);
      await tester.pumpAndSettle();
      expect(game.state.timeLeft, 5);
      expect(game.pendingEvent, isNull);
      await tester.tap(find.byKey(const ValueKey('continue-outcome')));
      await tester.pumpAndSettle();
      expect(game.isBusy, isFalse);
      expect(findUiText('DAY 1'), findsOneWidget);
      expect(findUiText('Crash Shelter'), findsNothing);
      expect(findUiText('LOST CANOPY'), findsNothing);
    },
  );

  testWidgets('night event, sleep, dawn and restart work through the UI', (
    tester,
  ) async {
    final game = testGame(state: RunState(timeLeft: 1));
    await showCamp(tester, game);
    await tapAction(tester, 'rest');
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    expect(findUiText('NIGHT EVENT'), findsOneWidget);
    final available = game.pendingEvent!.choices.firstWhere(game.canChoose);
    final choice = find.byKey(ValueKey('choice-${available.id}'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    await confirmCard(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    expect(findUiText('SLEEP'), findsOneWidget);
    await tapAction(tester, 'rest');
    expect(game.state.day, 2);
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    expect(findUiText('DAY 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('game over offers a complete fresh run', (tester) async {
    final game = testGame(
      state: RunState(
        stats: {
          SurvivalStat.health: 1,
          SurvivalStat.water: 0,
          SurvivalStat.food: 0,
          SurvivalStat.sanity: 10,
        },
      ),
    );
    await showCamp(tester, game);
    await tapAction(tester, 'rest');
    expect(game.report, isNotNull);
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    expect(findUiText('The jungle falls silent'), findsOneWidget);
    await tester.tap(findUiText('Begin again'));
    await tester.pumpAndSettle();
    expect(game.state.phase, RunPhase.day);
    expect(game.state.timeLeft, 6);
    expect(game.state.value(SurvivalStat.health), 100);
  });
}
