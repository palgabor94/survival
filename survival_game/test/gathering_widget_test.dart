import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/craft_screen.dart';
import 'package:survival_game/ui/gathering_screen.dart';

import 'game/gathering_test.dart';
import 'widget_test.dart' show showCamp, findUiText;

Future<void> press(
  WidgetTester tester,
  String key, {
  bool settle = false,
}) async {
  final target = find.byKey(ValueKey(key)).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

void main() {
  testWidgets('camp menu opens gathering; plants commit once in the outcome', (
    tester,
  ) async {
    final game = gatheringGame();
    await showCamp(tester, game);
    await press(tester, 'camp-menu', settle: true);
    await press(tester, 'menu-gather', settle: true);
    await press(tester, 'open-gathering-foraging', settle: true);
    expect(find.byType(GatheringScreen), findsOneWidget);
    expect(game.state.timeLeft, 6);
    await press(tester, 'gathering-start');
    await tester.pump(const Duration(milliseconds: 100));
    await press(tester, 'plant-ember_berries');
    await press(tester, 'plant-fiber');
    expect(game.gathering!.picked, {'ember_berries', 'fiber'});
    expect(game.state.resource('fiber'), 20);
    await press(tester, 'gathering-finish', settle: true);
    expect(game.gathering, isNull);
    expect(game.state.resource('fiber'), 22);
    expect(game.state.timeLeft, 5);
    expect(find.byKey(const ValueKey('continue-outcome')), findsOneWidget);
    await press(tester, 'continue-outcome', settle: true);
    expect(game.report, isNull);
    expect(game.state.resource('fiber'), 22);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing axe opens workshop without charging daylight', (
    tester,
  ) async {
    final game = gatheringGame(
      state: RunState(resources: {'wood': 20, 'stone': 10, 'fiber': 20}),
    );
    game.openGathering(GatheringKind.chopping);
    await showCamp(tester, game);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gathering-start')))
          .onPressed,
      isNull,
    );
    await press(tester, 'gathering-back', settle: true);
    expect(find.byType(CraftScreen), findsOneWidget);
    expect(game.gathering, isNull);
    expect(game.state.timeLeft, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pause freezes target and resume preserves a successful hunt', (
    tester,
  ) async {
    final game = gatheringGame();
    game.openGathering(GatheringKind.hunting);
    await showCamp(tester, game);
    await press(tester, 'gathering-start');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 450));
    await press(tester, 'gathering-pause', settle: true);
    final elapsed = game.gathering!.elapsed;
    await tester.pump(const Duration(seconds: 30));
    expect(game.gathering!.elapsed, elapsed);
    await press(tester, 'gathering-resume');
    await press(tester, 'gathering-strike');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(game.gathering, isNull);
    expect(game.state.resource('raw_meat'), inInclusiveRange(2, 3));
    expect(game.state.toolCondition('stone_spear'), 9);
    expect(find.byKey(const ValueKey('continue-outcome')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved active attempt opens paused and keeps selected plants', (
    tester,
  ) async {
    final game = gatheringGame();
    game.openGathering(GatheringKind.foraging);
    game.beginGathering();
    game.pickGatheringPlant('fiber');
    game.tickGathering(2);
    final restored = gatheringGame();
    expect(restored.restore(gatheringSave(game)), isTrue);
    await showCamp(tester, restored);
    expect(findUiText('Paused'), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));
    expect(restored.gathering!.elapsed, 2);
    expect(restored.gathering!.picked, {'fiber'});
    await press(tester, 'gathering-resume');
    await press(tester, 'gathering-finish', settle: true);
    expect(restored.state.resource('fiber'), 22);
    expect(restored.state.timeLeft, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('foraging timeout opens result and advances the final daylight', (
    tester,
  ) async {
    final game = gatheringGame(state: RunState(timeLeft: 1));
    game.openGathering(GatheringKind.foraging);
    await showCamp(tester, game);
    await press(tester, 'gathering-start');
    await tester.pump(const Duration(milliseconds: 100));
    await press(tester, 'plant-fiber');
    await tester.pump(const Duration(seconds: 9));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(game.gathering, isNull);
    expect(game.state.resource('fiber'), 2);
    await press(tester, 'continue-outcome', settle: true);
    expect(game.state.phase, RunPhase.night);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving an active attempt confirms and keeps completed plants', (
    tester,
  ) async {
    final game = gatheringGame();
    game.openGathering(GatheringKind.foraging);
    await showCamp(tester, game);
    await press(tester, 'gathering-start');
    await press(tester, 'plant-fiber');
    await press(tester, 'gathering-pause', settle: true);
    await press(tester, 'gathering-pause-leave', settle: true);
    expect(
      find.byKey(const ValueKey('gathering-confirm-leave')),
      findsOneWidget,
    );
    await press(tester, 'gathering-confirm-leave', settle: true);
    expect(game.gathering, isNull);
    expect(game.state.resource('fiber'), 22);
    expect(game.state.timeLeft, 5);
    expect(find.byKey(const ValueKey('continue-outcome')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app background freezes the timer until explicit resume', (
    tester,
  ) async {
    final game = gatheringGame();
    game.openGathering(GatheringKind.chopping);
    await showCamp(tester, game);
    await press(tester, 'gathering-start');
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final elapsed = game.gathering!.elapsed;
    await tester.pump(const Duration(seconds: 30));
    expect(game.gathering!.elapsed, elapsed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gathering-resume')), findsOneWidget);
    expect(game.gathering!.elapsed, elapsed);
    await press(tester, 'gathering-resume');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    expect(game.gathering!.elapsed, greaterThan(elapsed));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final kind in GatheringKind.values) {
    for (final layout in [
      (const Size(375, 812), 1.0),
      (const Size(844, 390), 1.0),
      (const Size(390, 844), 1.5),
    ]) {
      testWidgets(
        '${kind.name} ready and active controls fit ${layout.$1} text ${layout.$2}',
        (tester) async {
          final game = gatheringGame();
          game.openGathering(kind);
          await showCamp(tester, game, size: layout.$1, textScale: layout.$2);
          expect(tester.takeException(), isNull);
          final ready = [
            'gathering-start',
            'gathering-back',
          ].map((key) => tester.getSize(find.byKey(ValueKey(key)))).toList();
          if (kind == GatheringKind.foraging) {
            expect(ready[0], ready[1]);
            expect(ready[0].width, lessThanOrEqualTo(160));
          } else {
            expect(ready[0].height, greaterThanOrEqualTo(48));
            expect(ready[1].height, greaterThanOrEqualTo(48));
          }
          await press(tester, 'gathering-start');
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          if (kind == GatheringKind.foraging) {
            await press(tester, 'plants-next');
            await tester.pump(const Duration(milliseconds: 300));
            await press(tester, 'plant-herb');
            expect(game.gathering!.picked, contains('herb'));
          }
          await press(tester, 'gathering-pause', settle: true);
          expect(
            find.byKey(const ValueKey('gathering-resume')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
