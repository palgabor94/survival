import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/fishing_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/fishing_screen.dart';
import 'package:survival_game/ui/fishing_panels.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'game/fishing_progression_test.dart' show fishingGame, landFish;
import 'game/gathering_test.dart' show gatheringSave;
import 'widget_test.dart' show showCamp;
import 'gathering_widget_test.dart' show press;

void main() {
  testWidgets(
    'bait selection shows details, changes only selection, and charges on cast',
    (tester) async {
      final game = fishingGame();
      game.travelTo('fishing_pond');
      await showCamp(tester, game);
      final before = game.state.toJson();
      await press(tester, 'fishing-bait-insect_bait', settle: true);
      expect(game.state.toJson(), before);
      await press(tester, 'select-bait-insect_bait', settle: true);
      expect(game.fishing!.baitId, 'insect_bait');
      expect(game.state.resource('insect_bait'), 3);
      await press(tester, 'cast-line');
      expect(game.state.resource('insect_bait'), 2);
      expect(game.state.resource('bait'), 4);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('closing the catch preserves it; release grants no fish', (
    tester,
  ) async {
    final game = fishingGame();
    game.travelTo('fishing_pond');
    game.castLine();
    landFish(game);
    final id = game.fishing!.catchRecord!.speciesId,
        before = game.state.resource(game.fishing!.catchRecord!.speciesId);
    await showCamp(tester, game);
    expect(find.byType(FishingCatchDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(FishingCatchDialog),
        matching: find.byType(ParchmentClose),
      ),
    );
    await tester.pumpAndSettle();
    expect(game.state.resource(id), before);
    expect(game.fishing!.stage, FishingStage.caught);
    await press(tester, 'fishing-return', settle: true);
    await press(tester, 'release-fish-catch', settle: true);
    expect(game.fishing, isNull);
    expect(game.state.resource(id), before);
    expect(game.state.knownFish, contains(id));
    expect(game.report!.title, 'Catch released');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'unsafe fish requires explicit confirmation; cancelling preserves it',
    (tester) async {
      final game = fishingGame();
      await showCamp(tester, game);
      await press(tester, 'open-inventory', settle: true);
      await press(tester, 'inventory-tab-0', settle: true);
      await press(tester, 'inventory-spiny_sunlurker', settle: true);
      await press(tester, 'consume-spiny_sunlurker', settle: true);
      expect(game.state.conditions, isEmpty);
      expect(game.state.resource('spiny_sunlurker'), 1);
      await press(tester, 'confirm-unsafe-fish', settle: true);
      expect(game.state.hasCondition(ConditionKind.poisoned), isTrue);
      expect(game.state.resource('spiny_sunlurker'), 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'fish preparation preview is free and confirmation creates safe stored food',
    (tester) async {
      final game = fishingGame();
      await showCamp(tester, game);
      await press(tester, 'open-inventory', settle: true);
      await press(tester, 'inventory-tab-0', settle: true);
      await press(tester, 'inventory-spiny_sunlurker', settle: true);
      await tester.tap(find.text('PREPARE SAFELY · 1 WOOD · 1 TIME'));
      await tester.pumpAndSettle();
      expect(game.state.timeLeft, 6);
      expect(find.byType(FishPreparationDialog), findsOneWidget);
      await press(tester, 'confirm-prepare-fish', settle: true);
      expect(game.state.timeLeft, 5);
      expect(game.state.resource('prepared_spiny_sunlurker'), 1);
      expect(game.state.conditions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final layout in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets(
      'catch details and saved pause fit ${layout.$1} text ${layout.$2}',
      (tester) async {
        final game = fishingGame();
        game.travelTo('fishing_pond');
        game.castLine();
        landFish(game);
        await showCamp(tester, game, size: layout.$1, textScale: layout.$2);
        expect(find.byType(FishingCatchDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        final waiting = fishingGame();
        waiting.travelTo('fishing_pond');
        waiting.castLine();
        final copy = fishingGame();
        expect(copy.restore(gatheringSave(waiting)), isTrue);
        await showCamp(tester, copy, size: layout.$1, textScale: layout.$2);
        expect(find.byType(FishingScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('fishing-resume')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
