import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/ui/gathering_screen.dart';
import 'package:survival_game/ui/parchment_craft_screen.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/tool_panels.dart';
import 'package:survival_game/ui/event_dialog.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'game/tool_progression_test.dart' show toolGame;
import 'game/gathering_test.dart' show finishPerfectChopping;

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key)).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'tool filter shows all three equal cards and opens crafting details',
    (tester) async {
      final g = toolGame(tools: {'stone_axe', 'stone_spear'});
      await tester.pumpWidget(
        MaterialApp(
          theme: canopyTheme,
          home: ParchmentCraftScreen(game: g, onCamp: () {}, onCraft: () {}),
        ),
      );
      await tapKey(tester, 'tools-filter-AXES');
      final cards = find.byType(ParchmentCard);
      expect(cards, findsNWidgets(3));
      final first = tester.getSize(cards.at(0));
      for (var i = 1; i < 3; i++) {
        expect(tester.getSize(cards.at(i)), first);
      }
      await tapKey(tester, 'recipe-reinforced_axe');
      expect(find.byType(FieldToolSummary), findsOneWidget);
      expect(find.text('CRAFT · 1 TIME'), findsOneWidget);
      expect(g.state.tools, {'stone_axe', 'stone_spear'});
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'gathering equipment selection changes tool without spending time',
    (tester) async {
      final g = toolGame();
      g.openGathering(GatheringKind.chopping);
      await tester.pumpWidget(
        MaterialApp(
          theme: canopyTheme,
          home: GatheringScreen(game: g),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHANGE'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'select-salvage_axe');
      expect(g.state.equippedAxe, 'salvage_axe');
      expect(g.state.timeLeft, 6);
      expect(g.state.toolCondition('salvage_axe'), 24);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final layout in [
    (const Size(320, 568), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets('repair and clear outcome fit ${layout.$1} text ${layout.$2}', (
      tester,
    ) async {
      tester.view.physicalSize = layout.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final g = toolGame(durability: {'salvage_spear': 3});
      Widget app(Widget child) => MaterialApp(
        theme: canopyTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(layout.$2)),
          child: child!,
        ),
        home: Scaffold(body: child),
      );
      await tester.pumpWidget(
        app(ToolRepairDialog(game: g, id: 'salvage_spear')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('confirm-repair-salvage_spear')),
      );
      expect(tester.takeException(), isNull);
      g.openGathering(GatheringKind.chopping);
      g.beginGathering();
      finishPerfectChopping(g);
      await tester.pumpWidget(
        app(OutcomeDialog(report: g.report!, nightNext: false, state: g.state)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remaining: 76 / 100'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
