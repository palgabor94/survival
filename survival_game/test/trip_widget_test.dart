import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/event_scene.dart';
import 'package:survival_game/ui/expedition_scene.dart';

import 'expedition_widget_test.dart' show tapKey;
import 'game/game_engine_test.dart' show FixedRandom;
import 'widget_test.dart' show testGame, showCamp, findUiText;

GameEngine tripGame({
  double roll = .99,
  Set<String> tools = const {},
  Map<String, int> resources = const {},
}) {
  final base = testGame();
  return GameEngine(
    base.catalog,
    world: base.world,
    recipes: base.recipes,
    random: FixedRandom(roll),
    initialState: RunState(
      tools: tools,
      resources: {'wood': 2, 'bait': 0, ...resources},
    ),
  );
}

void main() {
  testWidgets('the decision shows the pack, the danger and both cards', (
    tester,
  ) async {
    final game = tripGame();
    game.travelTo('riverbank');
    game.choose(game.visibleChoices.first.id);
    game.continueFromReport();
    await showCamp(tester, game);

    expect(find.byType(ExpeditionScene), findsOneWidget);
    expect(findUiText('Push on, or head home?'), findsOneWidget);
    expect(findUiText('DANGER'), findsOneWidget);
    expect(find.byKey(const ValueKey('expedition-return')), findsOneWidget);
    final deeper = tester.widget<ActionCard>(
      find.byKey(const ValueKey('expedition-deeper')),
    );
    expect(deeper.onTap, isNotNull);
    expect(findUiText('40% DANGER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('going deeper leads to the next stop, returning ends the trip', (
    tester,
  ) async {
    final game = tripGame();
    game.travelTo('riverbank');
    game.choose(game.visibleChoices.first.id);
    game.continueFromReport();
    await showCamp(tester, game);

    await tapKey(tester, 'expedition-deeper');
    expect(find.byType(ExpeditionScene), findsNothing);
    expect(find.byType(EventScene), findsOneWidget);
    expect(game.expedition!.depth, 1);

    final playable = game.visibleChoices.firstWhere(game.canChoose);
    await tapKey(tester, 'choice-${playable.id}');
    await tapKey(tester, 'continue-outcome');
    expect(find.byType(ExpeditionScene), findsOneWidget);

    await tapKey(tester, 'expedition-return');
    expect(findUiText('Home with the haul'), findsOneWidget);
    await tapKey(tester, 'continue-outcome');
    expect(game.expedition, isNull);
    expect(game.state.locationId, 'camp');
    expect(find.byType(ExpeditionScene), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an attack shows gear-based cards and locks the rest', (
    tester,
  ) async {
    final game = tripGame(roll: 0, tools: {'torch'});
    game.travelTo('riverbank');
    game.choose(game.visibleChoices.first.id);
    game.continueFromReport();
    game.goDeeper();
    await showCamp(tester, game);

    expect(findUiText('DANGER · RIVERBANK'), findsOneWidget);
    expect(findUiText('Eyes in the grass'), findsOneWidget);
    expect(find.byType(ActionCard), findsNWidgets(4));
    ActionCard card(String id) =>
        tester.widget<ActionCard>(find.byKey(ValueKey('choice-$id')));
    expect(card('torch').onTap, isNotNull);
    expect(card('flee').onTap, isNotNull);
    expect(card('spear').onTap, isNull);
    expect(card('meat').onTap, isNull);
    await tester.tap(find.byKey(const ValueKey('choice-spear')));
    await tester.pumpAndSettle();
    expect(findUiText('Needs Stone Spear'), findsOneWidget);
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('lose your haul'), findsNothing);

    await tapKey(tester, 'choice-torch');
    expect(find.byType(EventScene), findsNothing);
    expect(game.state.value(SurvivalStat.health), 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fleeing drops the pack and brings you back to camp', (
    tester,
  ) async {
    final game = tripGame(roll: 0);
    game.travelTo('riverbank');
    game.choose(game.visibleChoices.first.id);
    game.continueFromReport();
    game.goDeeper();
    await showCamp(tester, game);
    final woodBefore = game.state.resource('wood');
    await tapKey(tester, 'choice-flee');
    await tapKey(tester, 'continue-outcome');
    expect(game.expedition, isNull);
    expect(game.state.locationId, 'camp');
    expect(game.state.resource('wood'), lessThan(woodBefore));
    expect(find.byType(ExpeditionScene), findsNothing);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets('decision and attack fit at $size, text x$scale', (
      tester,
    ) async {
      final game = tripGame(roll: 0, tools: {'torch', 'stone_spear'});
      game.travelTo('riverbank');
      game.choose(game.visibleChoices.first.id);
      game.continueFromReport();
      await showCamp(tester, game, size: size, textScale: scale);
      expect(find.byType(ExpeditionScene), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'expedition-deeper');
      expect(find.byType(EventScene), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'choice-flee');
      expect(tester.takeException(), isNull);
    });
  }
}
