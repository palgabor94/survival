import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/inventory_panels.dart';
import 'package:survival_game/ui/inventory_dialog.dart';
import 'package:survival_game/ui/event_dialog.dart';
import 'package:survival_game/ui/event_scene.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'game/inventory_test.dart';
import 'game/gathering_test.dart' show gatheringSave;
import 'widget_test.dart' show showCamp;

Future<void> press(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key)).last;
  await tester.ensureVisible(f);
  if (tester.widget(f) is ParchmentCard) {
    await tester.tapAt(tester.getTopLeft(f) + const Offset(20, 16));
  } else {
    await tester.tap(f);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'packing edits a saved draft and X cancels without moving items',
    (tester) async {
      final g = inventoryGame();
      g.beginPacking('riverbank');
      await showCamp(tester, g);
      expect(find.byType(PackingScreen), findsOneWidget);
      await press(tester, 'packing-tab-0');
      await press(tester, 'packing-item-wood');
      await press(tester, 'quantity-5');
      await press(tester, 'confirm-item-quantity');
      expect(g.packingDraft!.items['wood'], 5);
      expect(g.state.resource('wood'), 50);
      expect(g.state.packResources, isEmpty);
      await press(tester, 'cancel-packing');
      expect(g.packingDraft, isNull);
      expect(g.state.locationId, 'camp');
      expect(g.state.timeLeft, 6);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'departure commits the draft then opens the actual destination event',
    (tester) async {
      final g = inventoryGame();
      g.beginPacking('riverbank');
      g.updatePacking({'prepared_small_fish': 2}, {'stone_axe'});
      await showCamp(tester, g);
      await press(tester, 'confirm-departure');
      expect(find.byType(EventScene), findsOneWidget);
      expect(g.state.packResources, {'prepared_small_fish': 2});
      expect(g.state.storedResources['prepared_small_fish'], 4);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'overflow minimizes, resumes and requires explicit loss confirmation',
    (tester) async {
      final g = fullHaul();
      await showCamp(tester, g);
      expect(find.byType(HaulResolutionScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(g.hasPendingHaul, isTrue);
      await press(tester, 'resume-haul');
      await press(tester, 'haul-item-wood');
      for (var i = 0; i < 3; i++) {
        await press(tester, 'quantity--1');
      }
      await press(tester, 'confirm-item-quantity');
      await press(tester, 'haul-item-stone');
      await press(tester, 'quantity--1');
      await press(tester, 'confirm-item-quantity');
      final saved = gatheringSave(g);
      expect((saved['haulSelection'] as Map)['stone'], 5);
      await press(tester, 'confirm-haul');
      expect(find.byKey(const ValueKey('confirm-discard')), findsOneWidget);
      expect(g.hasPendingHaul, isTrue);
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(g.hasPendingHaul, isTrue);
      await press(tester, 'confirm-haul');
      await press(tester, 'confirm-discard');
      expect(g.hasPendingHaul, isFalse);
      expect(find.byType(OutcomeDialog), findsOneWidget);
      expect(g.state.resource('stone'), 49);
      expect(tester.takeException(), isNull);
    },
  );
  for (final layout in [
    (const Size(320, 568), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets(
      'packing, quantity and overflow fit ${layout.$1} text ${layout.$2}',
      (tester) async {
        final g = inventoryGame();
        g.beginPacking('riverbank');
        await showCamp(tester, g, size: layout.$1, textScale: layout.$2);
        expect(tester.takeException(), isNull);
        await press(tester, 'packing-tab-0');
        await press(tester, 'packing-item-wood');
        expect(find.byType(ItemQuantityDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        final haul = fullHaul();
        await showCamp(tester, haul, size: layout.$1, textScale: layout.$2);
        expect(tester.takeException(), isNull);
        await press(tester, 'haul-item-stone');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'field inventory disables storage and shows only actual carried items',
    (tester) async {
      final g = inventoryGame();
      g.travelTo('riverbank', pack: {'herb': 2});
      await tester.pumpWidget(
        MaterialApp(
          theme: canopyTheme,
          home: Scaffold(body: InventoryDialog(game: g)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('inventory-tab-0')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const ValueKey('inventory-herb')), findsOneWidget);
      expect(find.byKey(const ValueKey('inventory-wood')), findsNothing);
      expect(find.byType(PackCapacity), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
