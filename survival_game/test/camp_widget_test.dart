import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/run_storage.dart';
import 'package:survival_game/main.dart';
import 'package:survival_game/ui/craft_screen.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/event_scene.dart';
import 'package:survival_game/ui/inventory_dialog.dart';

import 'expedition_widget_test.dart' show tapKey, confirmCard;
import 'game/game_engine_test.dart' show FixedRandom;
import 'widget_test.dart' show testGame, showCamp, findUiText;

RunState stocked({int campTier = 0, Set<String> tools = const {}}) => RunState(
  campTier: campTier,
  tools: tools,
  resources: {'wood': 12, 'stone': 3, 'fiber': 10, 'herb': 1},
  stats: {
    SurvivalStat.health: 60,
    SurvivalStat.water: 80,
    SurvivalStat.food: 75,
    SurvivalStat.sanity: 60,
  },
);

Future<void> pumpApp(WidgetTester tester, RunStorage storage) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Cached asset futures from an earlier test never resolve on this clock.
  rootBundle.clear();
  await tester.pumpWidget(LostCanopyApp(storage: storage, enableAudio: false));
  // Real asset and storage loading happens outside the fake clock.
  for (var i = 0; i < 200; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('four material cards keep the same size in the last row', (
    tester,
  ) async {
    await showCamp(
      tester,
      testGame(
        state: RunState(
          resources: {'wood': 3, 'stone': 3, 'fiber': 6, 'bait': 2},
        ),
      ),
    );
    await tapKey(tester, 'open-inventory');
    final sizes = [
      for (final id in ['wood', 'stone', 'fiber', 'bait'])
        tester.getSize(
          find.descendant(
            of: find.byKey(ValueKey('inventory-$id')),
            matching: find.byType(Material),
          ),
        ),
    ];
    for (final size in sizes) {
      expect(size.width, closeTo(sizes.first.width, .01));
      expect(size.height, closeTo(sizes.first.height, .01));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('items close stays visible while long contents scroll', (
    tester,
  ) async {
    final game = testGame(state: stocked());
    final before = game.state.toJson();
    await showCamp(tester, game, size: const Size(320, 568));
    await tapKey(tester, 'open-inventory');
    final close = find.byKey(const ValueKey('close-dialog'));
    final header = find.descendant(
      of: find.byType(InventoryDialog),
      matching: findUiText('ITEMS'),
    );
    final headerBounds = tester.getRect(header);
    expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(48));
    await tester.drag(
      find.byKey(const ValueKey('dialog-content-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(header), headerBounds);
    expect(close.hitTestable(), findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(InventoryDialog), findsNothing);
    expect(game.state.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('craft a tool in the workshop and see it in the inventory', (
    tester,
  ) async {
    final game = testGame(state: stocked());
    await showCamp(tester, game);
    await tapKey(tester, 'open-workshop');
    expect(find.byType(CraftScreen), findsOneWidget);
    expect(find.text('STONE KNIFE'), findsWidgets);

    await tapKey(tester, 'recipe-stone_knife');
    await tapKey(tester, 'craft-stone_knife');
    expect(find.byType(CraftScreen), findsNothing);
    expect(findUiText('Crafted: Stone Knife'), findsOneWidget);
    expect(game.state.tools, contains('stone_knife'));
    expect(game.state.timeLeft, 5);
    await tapKey(tester, 'continue-outcome');

    await tapKey(tester, 'open-inventory');
    await tapKey(tester, 'inventory-tab-2');
    await tapKey(tester, 'inventory-stone_knife');
    expect(findUiText('Cut herbs and roots while foraging.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tier-locked recipes explain what they need', (tester) async {
    final game = testGame(state: stocked());
    await showCamp(tester, game);
    await tapKey(tester, 'open-workshop');
    await tapKey(tester, 'recipe-drying_rack');
    final craft = tester.widget<FilledButton>(
      find.byKey(const ValueKey('craft-drying_rack')),
    );
    expect(craft.onPressed, isNull);
    expect(findUiText('Needs Basic Refuge'), findsWidgets);
  });

  testWidgets('building Basic Refuge changes the camp and the next goal', (
    tester,
  ) async {
    final game = testGame(state: stocked());
    await showCamp(tester, game);
    expect(find.byKey(const ValueKey('camp-art-0')), findsOneWidget);
    expect(findUiText('Build Basic Refuge'), findsOneWidget);
    expect(find.textContaining('Wood 8/8'), findsOneWidget);

    await tapKey(tester, 'camp-objective');
    expect(find.byType(CraftScreen), findsOneWidget);
    await tapKey(tester, 'tab-camp');
    expect(game.state.campTier, 0);
    await tapKey(tester, 'recipe-camp_tier_1');
    await tapKey(tester, 'craft-camp_tier_1');
    expect(findUiText('Camp upgraded: Basic Refuge'), findsOneWidget);
    await tapKey(tester, 'continue-outcome');

    expect(game.state.campTier, 1);
    expect(find.byKey(const ValueKey('camp-art-1')), findsOneWidget);
    expect(findUiText('Build Established Camp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('herbs are brewed from the inventory', (tester) async {
    final game = testGame(state: stocked());
    await showCamp(tester, game);
    await tapKey(tester, 'open-inventory');
    await tapKey(tester, 'inventory-tab-1');
    await tapKey(tester, 'inventory-herb');
    await tapKey(tester, 'consume-herb');
    expect(findUiText('Herbal tea'), findsOneWidget);
    expect(game.state.value(SurvivalStat.health), 75);
    expect(game.state.resource('herb'), 0);
  });

  testWidgets('tool choices show what they need and unlock with the tool', (
    tester,
  ) async {
    Future<ActionCard> rootsChoice(Set<String> tools) async {
      await tester.pumpWidget(const SizedBox.shrink());
      // FixedRandom always picks the first forage event: the berry patch.
      final game = GameEngine(
        testGame().catalog,
        recipes: testGame().recipes,
        random: FixedRandom(),
        initialState: stocked(tools: tools),
      );
      await showCamp(tester, game);
      await tester.tap(find.byKey(const ValueKey('action-forage')));
      await tester.pumpAndSettle();
      expect(game.pendingEvent!.id, 'berry_patch');
      final button = find.byKey(const ValueKey('choice-roots'));
      await tester.ensureVisible(button);
      return tester.widget<ActionCard>(button);
    }

    expect((await rootsChoice({})).onTap, isNull);
    await tester.tap(find.byKey(const ValueKey('choice-roots')));
    await tester.pumpAndSettle();
    expect(findUiText('Needs Stone Knife'), findsOneWidget);
    expect((await rootsChoice({'stone_knife'})).onTap, isNotNull);
  });

  testWidgets('upgraded camps get a moonlit night', (tester) async {
    final game = testGame(state: RunState(campTier: 2, timeLeft: 1));
    await showCamp(tester, game);
    await tapKey(tester, 'action-rest');
    await tapKey(tester, 'continue-outcome');
    expect(find.byType(EventScene), findsOneWidget);
    expect(game.state.phase, RunPhase.night);
    // The scene behind the night event is the upgraded camp, not the starter.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/art/camp_tier_2_empty_v1.jpg',
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('starting a new run asks first', (tester) async {
    final game = testGame(state: stocked(campTier: 1));
    await showCamp(tester, game);
    await tester.tap(find.byKey(const ValueKey('camp-menu')));
    await tester.pumpAndSettle();
    await tester.tap(findUiText('Start a new run'));
    await tester.pumpAndSettle();
    await tester.tap(findUiText('Keep playing'));
    await tester.pumpAndSettle();
    expect(game.state.campTier, 1);

    await tester.tap(find.byKey(const ValueKey('camp-menu')));
    await tester.pumpAndSettle();
    await tester.tap(findUiText('Start a new run'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'confirm-new-run');
    expect(game.state.campTier, 0);
    expect(game.state.resource('wood'), 2);
  });

  testWidgets('the app autosaves and resumes a run mid-event', (tester) async {
    final storage = MemoryRunStorage();
    await pumpApp(tester, storage);
    expect(findUiText('DAY 1'), findsOneWidget);
    await tapKey(tester, 'action-forage');
    expect(find.byType(EventScene), findsOneWidget);
    final pending = storage.saved!['pendingEvent'] as String;

    // A new app instance reopens straight into the same event.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, storage);
    expect(find.byType(EventScene), findsOneWidget);
    expect(storage.saved!['pendingEvent'], pending);
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
    await tapKey(tester, 'continue-outcome');
    final state = RunState.fromJson(
      storage.saved!['state'] as Map<String, dynamic>,
    );
    expect(state.timeLeft, 5);
    expect(storage.saved!['pendingEvent'], isNull);
  });

  testWidgets('a corrupt save falls back to a fresh run', (tester) async {
    final storage = MemoryRunStorage({'version': 1, 'state': 'oops'});
    await pumpApp(tester, storage);
    expect(findUiText('DAY 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (size, textScale) in [
    (const Size(320, 568), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets('workshop and camp fit at $size, text x$textScale', (
      tester,
    ) async {
      final game = testGame(state: stocked(campTier: 1, tools: {'leaf_bed'}));
      await showCamp(tester, game, size: size, textScale: textScale);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'open-workshop');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('tab-camp')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'craft-back');
      await tester.pumpAndSettle();
      await tapKey(tester, 'open-inventory');
      expect(tester.takeException(), isNull);
    });
  }
}
