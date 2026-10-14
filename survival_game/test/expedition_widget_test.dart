import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/fishing_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/craft_screen.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/explore_map_screen.dart';
import 'package:survival_game/ui/expedition_scene.dart';
import 'package:survival_game/ui/fishing_screen.dart';
import 'package:survival_game/ui/inventory_dialog.dart';

import 'widget_test.dart' show testGame, showCamp, findUiText;

const frame = Duration(milliseconds: 50);

RunState anglerState({int bait = 2, int fish = 0, int food = 75}) => RunState(
  tools: {'basic_rod'},
  resources: {'wood': 0, 'fiber': 0, 'bait': bait, 'small_fish': fish},
  stats: {
    SurvivalStat.health: 100,
    SurvivalStat.water: 80,
    SurvivalStat.food: food,
    SurvivalStat.sanity: 80,
  },
);

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> openMapAndSelect(WidgetTester tester, String id) async {
  await tapKey(tester, 'open-map');
  expect(find.byType(ExploreMapScreen), findsOneWidget);
  await tapKey(tester, 'map-node-$id');
}

Future<void> travelToPond(WidgetTester tester) async {
  await openMapAndSelect(tester, 'fishing_pond');
  await tapKey(tester, 'travel-destination');
  expect(find.byType(FishingScreen), findsOneWidget);
}

/// Pumps frames until [done] or the time budget runs out.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration budget = const Duration(seconds: 12),
  void Function()? eachFrame,
}) async {
  for (var t = Duration.zero; t < budget && !done(); t += frame) {
    eachFrame?.call();
    await tester.pump(frame);
  }
}

/// Uses the rendered marker and real touch events, including pointer release.
/// Never mutates the fishing model to pretend that the control is working.
Future<void> reelWithTouch(WidgetTester tester, bool Function() done) async {
  TestGesture? finger;
  for (var i = 0; i < 220 && !done(); i++) {
    final player = tester.getCenter(
      find.byKey(const ValueKey('fishing-player-marker')),
    );
    final fish = tester.getCenter(
      find.byKey(const ValueKey('fishing-fish-zone')),
    );
    if (player.dx < fish.dx && finger == null) {
      finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('reel-control'))),
      );
    } else if (player.dx >= fish.dx && finger != null) {
      await finger.up();
      finger = null;
    }
    await tester.pump(frame);
  }
  await finger?.up();
  await tester.pump();
}

void main() {
  testWidgets('riverbank trip: map, event, outcome and back to camp', (
    tester,
  ) async {
    final game = testGame();
    await showCamp(tester, game);
    await openMapAndSelect(tester, 'riverbank');
    expect(findUiText('2 time · −8 Water · −6 Food'), findsOneWidget);
    await tapKey(tester, 'travel-destination');

    expect(find.byType(ExploreMapScreen), findsNothing);
    expect(game.pendingEvent!.locations, contains('riverbank'));
    final choice = find.byKey(
      ValueKey('choice-${game.pendingEvent!.choices.first.id}'),
    );
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(game.state.timeLeft, 4);
    expect(game.state.resource('bait'), greaterThan(0));

    await tapKey(tester, 'continue-outcome');
    // Daylight is left: carry on, or head home with the haul.
    expect(find.byType(ExpeditionScene), findsOneWidget);
    final returnSurface = find.descendant(
      of: find.byKey(const ValueKey('expedition-return')),
      matching: find.byType(Material),
    );
    final deeperSurface = find.descendant(
      of: find.byKey(const ValueKey('expedition-deeper')),
      matching: find.byType(Material),
    );
    final returnBounds = tester.getRect(returnSurface);
    final deeperBounds = tester.getRect(deeperSurface);
    expect(returnBounds.size, deeperBounds.size);
    expect(returnBounds.top, deeperBounds.top);
    expect(returnBounds.bottom, deeperBounds.bottom);
    await tapKey(tester, 'expedition-return');
    await tapKey(tester, 'continue-outcome');
    expect(game.isBusy, isFalse);
    expect(game.state.locationId, 'camp');
    expect(findUiText('DAY 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked destinations explain why and cannot be travelled to', (
    tester,
  ) async {
    final game = testGame();
    await showCamp(tester, game);
    await openMapAndSelect(tester, 'plane_wreck');
    expect(find.textContaining('Requires Camp Tier 1'), findsWidgets);
    expect(findUiText('3 time · −12 Water · −9 Food'), findsOneWidget);
    final travel = tester.widget<ActionCard>(
      find.byKey(const ValueKey('travel-destination')),
    );
    expect(travel.onTap, isNull);

    await tapKey(tester, 'map-node-fishing_pond');
    expect(
      findUiText('Discover on day 2 or craft a Basic Rod.'),
      findsOneWidget,
    );
    await tapKey(tester, 'map-node-camp');
    await tapKey(tester, 'travel-destination');
    expect(find.byType(ExploreMapScreen), findsNothing);
    expect(game.state.timeLeft, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crafting the rod from the map shortcut unlocks the pond', (
    tester,
  ) async {
    final game = testGame(
      state: RunState(resources: {'wood': 2, 'fiber': 3, 'bait': 1}),
    );
    await showCamp(tester, game);
    await openMapAndSelect(tester, 'fishing_pond');
    await tester.tap(findUiText('Craft a Basic Rod'));
    await tester.pumpAndSettle();
    expect(find.byType(CraftScreen), findsOneWidget);

    await tapKey(tester, 'recipe-basic_rod');
    await tapKey(tester, 'craft-basic_rod');
    expect(findUiText('Crafted: Basic Rod'), findsOneWidget);
    expect(game.state.tools, contains('basic_rod'));
    expect(game.state.resource('wood'), 0);
    expect(game.state.resource('fiber'), 0);
    expect(game.state.timeLeft, 5);
    await tapKey(tester, 'continue-outcome');

    await openMapAndSelect(tester, 'fishing_pond');
    expect(findUiText('Craft a Basic Rod'), findsNothing);
    final travel = tester.widget<ActionCard>(
      find.byKey(const ValueKey('travel-destination')),
    );
    expect(travel.onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full fishing loop: cast, hook, reel, return and eat', (
    tester,
  ) async {
    final game = testGame(state: anglerState(food: 50));
    await showCamp(tester, game);
    await travelToPond(tester);
    expect(game.state.timeLeft, 4);

    await tester.tap(find.byKey(const ValueKey('cast-line')));
    await tester.pump();
    expect(game.state.resource('bait'), 1);
    expect(findUiText('Waiting for a bite…'), findsOneWidget);

    final session = game.fishing!;
    await pumpUntil(tester, () => session.stage == FishingStage.bite);
    expect(findUiText('A bite! Hook it now!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hook-fish')));
    await tester.pump();
    expect(session.stage, FishingStage.reeling);

    // The reel control is held while pressed and released on lift.
    final reel = await tester.startGesture(
      tester.getCenter(findUiText('HOLD TO REEL')),
    );
    await tester.pump();
    expect(session.holding, isTrue);
    await reel.up();
    await tester.pump();
    expect(session.holding, isFalse);

    await reelWithTouch(tester, () => session.complete);
    expect(session.stage, FishingStage.caught);
    final caught = session.quality == CatchQuality.perfect ? 2 : 1;
    expect(find.textContaining('+$caught Small Fish'), findsOneWidget);

    await tester.tap(findUiText('RETURN TO CAMP'));
    await tester.pumpAndSettle();
    expect(find.byType(FishingScreen), findsNothing);
    expect(game.state.resource('small_fish'), caught);
    await tapKey(tester, 'continue-outcome');
    expect(game.state.locationId, 'camp');

    await tapKey(tester, 'open-inventory');
    await tapKey(tester, 'inventory-tab-1');
    await tapKey(tester, 'inventory-small_fish');
    await tapKey(tester, 'consume-small_fish');
    expect(findUiText('A meal by the fire'), findsOneWidget);
    expect(game.state.value(SurvivalStat.food), 50 - 6 + 25);
    expect(game.state.resource('small_fish'), caught - 1);
    expect(game.state.timeLeft, 4);
    await tapKey(tester, 'continue-outcome');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fishing tutorial teaches a complete catch without spending resources',
    (tester) async {
      final game = testGame(state: anglerState());
      await showCamp(tester, game);
      await travelToPond(tester);
      expect(find.textContaining('White bar = you.'), findsOneWidget);
      final before = game.toJson();
      await tapKey(tester, 'fishing-practice');
      expect(findUiText('HOW TO FISH'), findsOneWidget);
      await tapKey(tester, 'practice-cast');
      await pumpUntil(
        tester,
        () => find.byKey(const ValueKey('practice-hook')).evaluate().isNotEmpty,
      );
      // Practice never wastes a bite while the player is reading.
      await tester.pump(const Duration(seconds: 4));
      expect(find.byKey(const ValueKey('practice-hook')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('practice-hook')));
      await tester.tap(find.byKey(const ValueKey('practice-hook')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('reel-control')));
      await reelWithTouch(
        tester,
        () => find
            .text('You caught it! You are ready for the pond.')
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text('You caught it! You are ready for the pond.'),
        findsOneWidget,
      );
      await tapKey(tester, 'close-dialog');
      expect(game.toJson(), before);
      expect(game.fishing!.stage, FishingStage.ready);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fishing reel reacts immediately and keeps holding during finger movement',
    (tester) async {
      final game = testGame(state: anglerState());
      await showCamp(tester, game);
      await travelToPond(tester);
      await tester.tap(find.byKey(const ValueKey('cast-line')));
      await tester.pump();
      await pumpUntil(tester, () => game.fishing!.stage == FishingStage.bite);
      await tester.tap(find.byKey(const ValueKey('hook-fish')));
      await tester.pump();
      final position = tester.getCenter(
        find.byKey(const ValueKey('reel-control')),
      );
      final finger = await tester.startGesture(position);
      expect(game.fishing!.holding, isTrue);
      await finger.moveTo(position + const Offset(30, 0));
      await tester.pump(frame);
      expect(game.fishing!.holding, isTrue);
      await finger.cancel();
      expect(game.fishing!.holding, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a late hook lets the fish escape and the bait is spent', (
    tester,
  ) async {
    final game = testGame(state: anglerState());
    await showCamp(tester, game);
    await travelToPond(tester);
    await tester.tap(find.byKey(const ValueKey('cast-line')));
    await tester.pump();
    await pumpUntil(tester, () => game.fishing!.complete);
    expect(findUiText('The fish got away'), findsOneWidget);
    await tester.tap(findUiText('RETURN TO CAMP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('slipped away'), findsOneWidget);
    expect(game.state.resource('bait'), 1);
    expect(game.state.resource('small_fish'), 0);
  });

  testWidgets('leaving before the cast keeps the bait', (tester) async {
    final game = testGame(state: anglerState());
    await showCamp(tester, game);
    await travelToPond(tester);
    await tester.tap(find.byKey(const ValueKey('fishing-return')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your bait will be kept'), findsOneWidget);
    await tester.tap(findUiText('Return'));
    await tester.pumpAndSettle();
    expect(find.byType(FishingScreen), findsNothing);
    expect(findUiText('Back from the pond'), findsOneWidget);
    expect(game.state.resource('bait'), 2);
    expect(game.state.timeLeft, 4);
  });

  testWidgets('the leave dialog pauses the clock; staying resumes it', (
    tester,
  ) async {
    final game = testGame(state: anglerState());
    await showCamp(tester, game);
    await travelToPond(tester);
    await tester.tap(find.byKey(const ValueKey('cast-line')));
    await tester.pump();
    await tester.pump(frame);

    await tester.tap(find.byKey(const ValueKey('fishing-return')));
    await tester.pump();
    for (var i = 0; i < 100; i++) {
      await tester.pump(frame);
    }
    expect(game.fishing!.stage, FishingStage.waiting);

    await tester.tap(findUiText('Stay'));
    await pumpUntil(tester, () => game.fishing!.stage != FishingStage.waiting);
    expect(game.fishing!.stage, FishingStage.bite);

    // The ticker keeps scheduling frames, so pump instead of settling.
    await tester.tap(find.byKey(const ValueKey('fishing-return')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('without a catch'), findsOneWidget);
    await tester.tap(findUiText('Return'));
    await tester.pumpAndSettle();
    expect(find.byType(FishingScreen), findsNothing);
    expect(game.fishing, isNull);
    expect(game.state.resource('bait'), 1);
    expect(game.state.resource('small_fish'), 0);
  });

  testWidgets('system back asks before leaving an active cast', (tester) async {
    final game = testGame(state: anglerState());
    await showCamp(tester, game);
    await travelToPond(tester);
    await tester.tap(find.byKey(const ValueKey('cast-line')));
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.maybePop();
    await tester.pump();
    await tester.pump();
    expect(findUiText('Return to camp?'), findsOneWidget);
    expect(find.byType(FishingScreen), findsOneWidget);
    await tester.tap(findUiText('Stay'));
    await tester.pump();
    expect(findUiText('Return to camp?'), findsNothing);
    expect(game.fishing, isNotNull);
  });

  testWidgets('backgrounding the app pauses the fishing clock', (tester) async {
    final game = testGame(state: anglerState());
    await showCamp(tester, game);
    await travelToPond(tester);
    await tester.tap(find.byKey(const ValueKey('cast-line')));
    await tester.pump();
    await tester.pump(frame);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    for (var i = 0; i < 100; i++) {
      await tester.pump(frame);
    }
    expect(game.fishing!.stage, FishingStage.waiting);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpUntil(tester, () => game.fishing!.stage != FishingStage.waiting);
    expect(game.fishing!.stage, FishingStage.bite);
  });

  for (final (size, textScale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets('map, inventory and fishing fit at $size, text x$textScale', (
      tester,
    ) async {
      final game = testGame(state: anglerState(fish: 1, food: 40));
      await showCamp(tester, game, size: size, textScale: textScale);
      await openMapAndSelect(tester, 'riverbank');
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'map-node-ancient_ruins');
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'map-node-camp');
      await tapKey(tester, 'travel-destination');

      await tapKey(tester, 'open-inventory');
      expect(find.byType(InventoryDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      await travelToPond(tester);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'fishing-help');
      expect(findUiText('HOW TO FISH'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'close-dialog');
      final cast = find.byKey(const ValueKey('cast-line'));
      await tester.ensureVisible(cast);
      await tester.pump();
      await tester.tap(cast);
      await tester.pump();
      final session = game.fishing!;
      await pumpUntil(tester, () => session.stage == FishingStage.bite);
      final hook = find.byKey(const ValueKey('hook-fish'));
      await tester.ensureVisible(hook);
      await tester.pump();
      await tester.tap(hook);
      await tester.pump(frame);
      expect(session.stage, FishingStage.reeling);
      expect(tester.takeException(), isNull);
    });
  }
}
