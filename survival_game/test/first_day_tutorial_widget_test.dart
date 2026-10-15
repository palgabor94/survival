import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/main.dart';
import 'package:survival_game/ui/first_day_guide.dart';
import 'package:survival_game/ui/inventory_panels.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/parchment_craft_screen.dart';
import 'game/first_day_tutorial_test.dart';
import 'widget_test.dart' show showCamp;

void main() {
  testWidgets(
    'first-day tutorial welcome choice and collapse survive UI reload',
    (tester) async {
      final g = tutorialGame();
      await showCamp(tester, g);
      expect(find.byType(FirstDayWelcome), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('accept-first-day')));
      await tester.pumpAndSettle();
      expect(find.text('Gather something to eat'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(g.tutorial.collapsed, isTrue);
      expect(find.text('Gather something to eat'), findsNothing);
      final next = reloadGuide(g);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(LostCanopyApp(engine: next));
      await tester.pumpAndSettle();
      expect(find.byType(FirstDayWelcome), findsNothing);
      expect(find.text('Show'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('first-day tutorial skip stays dismissed on next journey', (
    tester,
  ) async {
    final g = tutorialGame();
    await showCamp(tester, g);
    await tester.tap(find.byKey(const ValueKey('skip-first-day')));
    await tester.pumpAndSettle();
    expect(find.byType(FirstDayWelcome), findsNothing);
    expect(find.byKey(const ValueKey('first-day-coach')), findsNothing);
    g.restart();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(LostCanopyApp(engine: g));
    await tester.pumpAndSettle();
    expect(find.byType(FirstDayWelcome), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'first-day tutorial completion is shown once after loading a calm dawn',
    (tester) async {
      final g = guidedGather();
      g.tutorial.completed.addAll(['eat', 'craft', 'pack', 'return', 'night']);
      await showCamp(tester, g);
      expect(find.byType(FirstDayComplete), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('finish-first-day')));
      await tester.pumpAndSettle();
      final next = reloadGuide(g);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(LostCanopyApp(engine: next));
      await tester.pumpAndSettle();
      expect(find.byType(FirstDayComplete), findsNothing);
      expect(next.profile.completedFirstDay, isTrue);
    },
  );
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets(
      'first-day tutorial responsive camp craft packing $size scale $scale',
      (tester) async {
        final g = guidedGather();
        await showCamp(tester, g, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        for (final page in [
          ParchmentCraftScreen(game: g, onCamp: () {}, onCraft: () {}),
          Builder(
            builder: (_) {
              g.beginPacking('riverbank');
              return PackingScreen(game: g);
            },
          ),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: canopyTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: page,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
