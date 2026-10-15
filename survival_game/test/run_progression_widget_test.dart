import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/run_progression.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/ui/progression_screens.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'game/inventory_test.dart' show inventoryGame;
import 'game/run_progression_test.dart' show sampleMetrics;
import 'widget_test.dart' show showCamp;

Future<void> press(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key)).last;
  await t.ensureVisible(f);
  if (t.widget(f) is ParchmentCard) {
    await t.tapAt(t.getTopLeft(f) + const Offset(20, 16));
  } else {
    await t.tap(f);
  }
  await t.pumpAndSettle();
}

Future<void> mount(
  WidgetTester t,
  Widget screen, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
    MaterialApp(
      theme: canopyTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: screen,
    ),
  );
  await t.pumpAndSettle();
}

GameEngine ended() {
  final g = inventoryGame();
  g.metrics = sampleMetrics();
  g.profile.xp = 420;
  g.abandonJourney();
  return g;
}

void main() {
  testWidgets(
    'camp menu opens persistent survivor profile and no perk is silently applied',
    (t) async {
      final g = inventoryGame();
      await showCamp(t, g);
      await press(t, 'camp-menu');
      await press(t, 'menu-profile');
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(
        find.text('Finish a journey to start your record.'),
        findsOneWidget,
      );
      expect(g.state.resource('wood'), 50);
      expect(g.profile.nextOption, 'none');
    },
  );
  testWidgets(
    'locked options reveal requirements, unlocked choice affects only next run',
    (t) async {
      final g = inventoryGame();
      g.profile.xp = 500;
      await mount(t, ProfileScreen(game: g));
      await press(t, 'profile-options');
      await press(t, 'option-medic');
      expect(find.byType(OptionDetailsScreen), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const ValueKey('select-next-option')),
            )
            .onPressed,
        isNull,
      );
      await t.tap(find.byTooltip('Close').last);
      await t.pumpAndSettle();
      await press(t, 'option-scavenger');
      await press(t, 'select-next-option');
      expect(g.profile.nextOption, 'scavenger');
      expect(g.state.resource('wood'), 50);
      await t.tap(find.byTooltip('Close').last);
      await t.pumpAndSettle();
      await press(t, 'profile-new-run');
      await press(t, 'confirm-new-run');
      expect(g.state.resource('wood'), 0);
      expect(g.state.resource('stone'), 2);
      expect(g.profile.journeys, 1);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'rank notice is acknowledged once and archive preserves recorded XP',
    (t) async {
      final g = ended();
      expect(g.rankNoticePending, true);
      await mount(t, RunResultScreen(game: g));
      await press(t, 'view-profile');
      expect(find.byType(RankUnlockedScreen), findsOneWidget);
      await t.tap(find.byTooltip('Close').last);
      await t.pumpAndSettle();
      expect(g.rankNoticePending, false);
      expect(find.byType(ProfileScreen), findsOneWidget);
      await press(t, 'profile-archive');
      await press(t, 'archive-${g.metrics.id}');
      expect(find.byType(RunResultScreen), findsOneWidget);
      expect(t.widget<RunResultScreen>(find.byType(RunResultScreen)).historical, isTrue);
      expect(g.profile.xp, 666);
      expect(g.profile.journeys, 1);
    },
  );
  testWidgets(
    'save failure blocks replacement and retry preserves a single abandoned result',
    (t) async {
      final g = inventoryGame();
      var writes = 0;
      g.persistSnapshot = (j) async {
        writes++;
        if (writes == 2) throw StateError('Disk full');
      };
      await mount(t, ProfileScreen(game: g));
      await press(t, 'profile-new-run');
      await press(t, 'confirm-new-run');
      await t.pumpAndSettle();
      expect(g.saveFailed, true);
      expect(g.profile.journeys, 1);
      final id = g.metrics.id;
      expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('confirm-new-run')))
            .onPressed,
        isNull,
      );
      await press(t, 'retry-record-save');
      await press(t, 'confirm-new-run');
      expect(g.metrics.id, id);
      expect(g.profile.journeys, 1);
      expect(g.saveFailed, false);
      expect(find.byType(NewJourneyScreen), findsNothing);
    },
  );
  for (final spec in [
    (const Size(320, 568), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets(
      'profile, result and starting options fit ${spec.$1} text ${spec.$2}',
      (t) async {
        final g = ended();
        for (final screen in [
          RunResultScreen(game: g),
          ProfileScreen(game: g),
          XpScreen(game: g, summary: g.completedRun!),
          ArchiveScreen(game: g),
          JourneyDetailsScreen(game: g, summary: g.completedRun!),
          StartingOptionsScreen(game: g),
          OptionDetailsScreen(game: g, option: startingOptions[1]),
          NewJourneyScreen(game: g),
          RankUnlockedScreen(game: g, summary: g.completedRun!),
        ]) {
          await mount(t, screen, size: spec.$1, scale: spec.$2);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }
}
