import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/condition_strip.dart';
import 'package:survival_game/ui/expedition_scene.dart';
import 'game/ecology_test.dart' show supplies;
import 'game/gathering_test.dart' show gatheringGame, gatheringSave;
import 'widget_test.dart' show showCamp;
import 'gathering_widget_test.dart' show press;

void main() {
  for (final layout in [
    (const Size(390, 844), 1.0),
    (const Size(375, 667), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets(
      'conditions and poison details fit ${layout.$1} text ${layout.$2}',
      (tester) async {
        final game = gatheringGame(
          state: supplies(
            conditions: [
              for (final kind in ConditionKind.values)
                SurvivalCondition(kind, 4),
            ],
          ),
        );
        await showCamp(tester, game, size: layout.$1, textScale: layout.$2);
        expect(find.byType(ConditionStrip), findsOneWidget);
        final before = game.state.toJson();
        await press(tester, 'condition-poisoned', settle: true);
        expect(tester.takeException(), isNull);
        expect(game.state.toJson(), before);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'inventory identifies a sample through confirmation without eating it',
    (tester) async {
      final game = gatheringGame(state: supplies());
      await showCamp(tester, game);
      await press(tester, 'open-inventory', settle: true);
      await press(tester, 'inventory-tab-0', settle: true);
      final item = find.byKey(const ValueKey('inventory-mooncap'));
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(game.state.knownSpecies, isNot(contains('mooncap')));
      await tester.tap(find.text('STUDY SAMPLE · 1 TIME'));
      await tester.pumpAndSettle();
      expect(game.state.knownSpecies, contains('mooncap'));
      expect(game.state.resource('mooncap'), 1);
      expect(game.state.hasCondition(ConditionKind.poisoned), isFalse);
      expect(game.report, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'campfire drying requires confirmation and never spends time on preview',
    (tester) async {
      final game = gatheringGame(
        state: supplies(
          conditions: [const SurvivalCondition(ConditionKind.wet, 3)],
        ),
      );
      await showCamp(tester, game);
      await press(tester, 'open-inventory', settle: true);
      await tester.tap(find.text('DRY BY FIRE · 1 WOOD · 1 TIME'));
      await tester.pumpAndSettle();
      expect(game.state.timeLeft, 6);
      await press(tester, 'confirm-dry-fire', settle: true);
      expect(game.state.timeLeft, 5);
      expect(game.state.resource('wood'), 19);
      expect(game.state.hasCondition(ConditionKind.wet), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'calm expedition exposes Items and treatment preserves the trip',
    (tester) async {
      final game = gatheringGame(
        state:
            supplies(
              conditions: [const SurvivalCondition(ConditionKind.poisoned, 4)],
            ).copyWith(
              locationId: 'riverbank',
              packResources: {'antidote': 1},
              expeditionGear: {},
            ),
      );
      final save = gatheringSave(game)
        ..['expedition'] = {
          'locationId': 'riverbank',
          'depth': 1,
          'loot': <String, int>{},
        }
        ..['decisionPending'] = true;
      expect(game.restore(save), isTrue);
      await showCamp(tester, game);
      expect(find.byType(ExpeditionScene), findsOneWidget);
      await tester.tap(find.text('USE ITEMS'));
      await tester.pumpAndSettle();
      await press(tester, 'inventory-tab-1', settle: true);
      await press(tester, 'inventory-antidote', settle: true);
      await press(tester, 'consume-antidote', settle: true);
      expect(game.state.hasCondition(ConditionKind.poisoned), isFalse);
      expect(game.expedition, isNotNull);
      expect(game.state.timeLeft, 6);
      await press(tester, 'continue-outcome', settle: true);
      expect(find.byType(ExpeditionScene), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
