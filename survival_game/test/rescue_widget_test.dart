import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/rescue_progress.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/beacon_screen.dart';
import 'package:survival_game/ui/event_scene.dart';
import 'package:survival_game/ui/expedition_scene.dart';
import 'package:survival_game/ui/rescued_screen.dart';
import 'package:survival_game/ui/ruins_puzzle_screen.dart';

import 'expedition_widget_test.dart' show tapKey;
import 'game/rescue_test.dart' show rescueGame, rescueState, openAltar, reopen;
import 'widget_test.dart' show showCamp, findUiText;

GameEngine stormGame() {
  final game = rescueGame(
    state: rescueState(
      stage: RescueStage.storm,
    ).copyWith(foundComponents: beaconComponents.keys.toSet()),
  );
  game.metrics.components.addAll(beaconComponents.keys);
  return reopen(game);
}

void main() {
  testWidgets(
    'camp objective opens beacon progress and builds through real outcome',
    (tester) async {
      final game = rescueGame(
        state: rescueState(
          resources: {
            for (final key in beaconComponents.keys) key: 1,
            'metal_scrap': 2,
          },
        ),
      );
      await showCamp(tester, game);
      await tapKey(tester, 'camp-objective');
      expect(find.byType(BeaconScreen), findsOneWidget);
      expect(find.text('1/1'), findsNWidgets(5));
      await tapKey(tester, 'beacon-primary');
      expect(findUiText('Crafted: Emergency Beacon'), findsOneWidget);
      expect(game.state.tools, contains('emergency_beacon'));
      await tapKey(tester, 'continue-outcome');
      await tapKey(tester, 'camp-objective');
      expect(findUiText('The beacon is ready'), findsOneWidget);
      await tapKey(tester, 'beacon-primary');
      expect(findUiText('Signal received'), findsOneWidget);
      expect(game.state.rescueStage, RescueStage.signalSent);
      await tapKey(tester, 'continue-outcome');
      expect(findUiText('Rescue comes tomorrow'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('camp menu exposes missing component sources before upgrades', (
    tester,
  ) async {
    final game = rescueGame(
      state: rescueState(tier: 0, tools: {}, resources: {}),
    );
    await showCamp(tester, game);
    await tapKey(tester, 'camp-menu');
    await tapKey(tester, 'menu-beacon');
    expect(find.byType(BeaconScreen), findsOneWidget);
    expect(find.text('0/1'), findsNWidgets(5));
    expect(find.text('Plane Wreck'), findsNWidgets(4));
    expect(find.text('Ancient Ruins · stone seal'), findsOneWidget);
    expect(
      tester
          .widget<ActionCard>(find.byKey(const ValueKey('beacon-primary')))
          .onTap,
      isNull,
    );
    await tapKey(tester, 'beacon-back');
    expect(find.byType(BeaconScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ruins discs resolve once then show result and expedition return',
    (tester) async {
      final game = rescueGame();
      game.travelTo('ancient_ruins');
      await showCamp(tester, game);
      await tapKey(tester, 'choice-align');
      expect(find.byType(RuinsPuzzleScreen), findsOneWidget);
      expect(find.textContaining('+1 Beacon'), findsNothing);
      final puzzle = game.ruinsPuzzle!;
      for (var i = 0; i < 3; i++) {
        while (puzzle.tiles[i] != puzzle.pattern[i]) {
          await tapKey(tester, 'ruins-disc-$i');
        }
      }
      final rects = [
        for (var i = 0; i < 3; i++)
          tester.getRect(find.byKey(ValueKey('ruins-disc-$i'))),
      ];
      expect(rects.map((r) => r.height).toSet(), hasLength(1));
      expect(rects.map((r) => r.width).toSet(), hasLength(1));
      await tapKey(tester, 'ruins-submit');
      expect(game.ruinsPuzzle, isNull);
      expect(findUiText('The altar opens'), findsOneWidget);
      expect(game.state.resource('beacon_core'), 1);
      await tapKey(tester, 'continue-outcome');
      expect(find.byType(ExpeditionScene), findsOneWidget);
      await tapKey(tester, 'expedition-return');
      await tapKey(tester, 'continue-outcome');
      expect(game.state.locationId, 'camp');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'storm decisions show actual results before saved rescued summary',
    (tester) async {
      final game = stormGame();
      await showCamp(tester, game);
      for (var i = 0; i < 3; i++) {
        expect(find.byType(EventScene), findsOneWidget);
        expect(find.textContaining('FINAL STORM · ${i + 1}/3'), findsOneWidget);
        expect(find.textContaining('+4 Sanity'), findsNothing);
        await tapKey(tester, 'choice-${['raise', 'cut', 'torch'][i]}');
        expect(find.byType(EventScene), findsNothing);
        expect(find.byType(RescuedScreen), findsNothing);
        await tapKey(tester, 'continue-outcome');
      }
      expect(game.state.rescued, isTrue);
      expect(find.byType(RescuedScreen), findsOneWidget);
      expect(findUiText('RESCUED'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      await tapKey(tester, 'rescue-new-run');
      await tester.tap(findUiText('Keep summary'));
      await tester.pumpAndSettle();
      expect(game.state.rescued, isTrue);
      await tapKey(tester, 'rescue-new-run');
      await tapKey(tester, 'confirm-rescue-new-run');
      expect(game.state.day, 1);
      expect(game.state.rescued, isFalse);
      expect(find.byType(RescuedScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a restored victory opens summary immediately', (tester) async {
    final game = stormGame();
    for (final choice in ['raise', 'cut', 'torch']) {
      game.choose(choice);
      game.continueFromReport();
    }
    await showCamp(tester, reopen(game));
    expect(find.byType(RescuedScreen), findsOneWidget);
    expect(find.byType(EventScene), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'rescue screens fit $size with text scale $scale and reduced motion',
        (tester) async {
          final puzzle = rescueGame();
          openAltar(puzzle);
          await showCamp(tester, puzzle, size: size, textScale: scale);
          await tapKey(tester, 'ruins-disc-0');
          await tapKey(tester, 'ruins-leave');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          final beacon = rescueGame();
          await showCamp(tester, beacon, size: size, textScale: scale);
          await tapKey(tester, 'camp-objective');
          expect(find.byType(BeaconScreen), findsOneWidget);
          await tapKey(tester, 'beacon-back');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          final storm = stormGame();
          for (final choice in ['raise', 'cut', 'torch']) {
            storm.choose(choice);
            storm.continueFromReport();
          }
          await showCamp(tester, storm, size: size, textScale: scale);
          await tapKey(tester, 'rescue-new-run');
          await tapKey(tester, 'confirm-rescue-new-run');
          expect(storm.state.day, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
