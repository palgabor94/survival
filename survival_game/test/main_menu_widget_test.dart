import 'dart:ui' as ui;
import 'package:survival_game/game/run_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_game/game/run_storage.dart';
import 'package:survival_game/main.dart';
import 'package:survival_game/ui/main_menu_screen.dart';
import 'package:survival_game/ui/first_day_guide.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/scene_artwork.dart';
import 'package:survival_game/ui/progression_screens.dart';
import 'game/first_day_tutorial_test.dart';
import 'widget_test.dart' show testGame;
import 'scene_background_test.dart' as scenes;

Future<void> press(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> mountMenu(
  WidgetTester t, {
  bool fresh = true,
  int index = 0,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final game = fresh ? tutorialGame() : testGame();
  await t.pumpWidget(
    MaterialApp(
      theme: canopyTheme,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: MainMenuScreen(game: game, backgroundIndex: index),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  test(
    'main_menu background rotation persists A B C and wraps without touching run',
    () async {
      SharedPreferences.setMockInitialValues({});
      final r = MenuBackgroundRotation();
      expect(await r.next(), 0);
      expect(await MenuBackgroundRotation().next(), 1);
      expect(await r.next(), 2);
      expect(await r.next(), 0);
    },
  );
  test(
    'main_menu unstarted save and first-run tutorial persist without starting run',
    () {
      final g = tutorialGame();
      expect(g.journeyStarted, isFalse);
      final next = reloadGuide(g);
      expect(next.journeyStarted, isFalse);
      expect(next.tutorial.welcomePending, isTrue);
      next.beginJourney();
      expect(reloadGuide(next).journeyStarted, isTrue);
      expect(next.profile.journeys, 0);
      expect(next.profile.xp, 0);
    },
  );
  testWidgets(
    'main_menu begin enters real first-run tutorial and return rotates image',
    (t) async {
      await mountMenu(t);
      expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
      expect(find.byType(FirstDayWelcome), findsNothing);
      await press(t, 'menu-enter-journey');
      expect(find.byType(FirstDayWelcome), findsOneWidget);
      await press(t, 'skip-first-day');
      await press(t, 'camp-menu');
      await press(t, 'menu-main-menu');
      expect(find.text('CONTINUE JOURNEY'), findsOneWidget);
      expect(
        t.widget<MenuBackdrop>(find.byType(MenuBackdrop)).asset,
        menuBackgrounds[1],
      );
      await press(t, 'menu-enter-journey');
      expect(find.byType(FirstDayWelcome), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('main_menu new journey cancellation preserves save and profile', (
    t,
  ) async {
    final g = testGame();
    final id = g.metrics.id;
    await t.pumpWidget(
      MaterialApp(
        theme: canopyTheme,
        home: MainMenuScreen(game: g),
      ),
    );
    await press(t, 'main-menu-new-journey');
    expect(find.byType(NewJourneyScreen), findsOneWidget);
    await t.tap(find.text('Keep playing'));
    await t.pumpAndSettle();
    expect(g.metrics.id, id);
    expect(g.profile.journeys, 0);
    expect(find.byType(MainMenuScreen), findsOneWidget);
  });
  testWidgets(
    'main_menu profile first launch starts original tutorial without abandoning it',
    (t) async {
      await mountMenu(t);
      await press(t, 'main-menu-profile');
      await press(t, 'profile-new-run');
      await press(t, 'confirm-new-run');
      expect(find.byType(FirstDayWelcome), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('main_menu settings and guide open without starting journey', (
    t,
  ) async {
    await mountMenu(t);
    await press(t, 'main-menu-settings');
    expect(find.text('Music'), findsOneWidget);
    await t.tap(find.byTooltip('Close').last);
    await t.pumpAndSettle();
    await press(t, 'main-menu-guide');
    expect(find.text('6 time each day'), findsOneWidget);
    expect(find.byType(FirstDayWelcome), findsNothing);
    expect(t.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(390, 932),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    testWidgets('main_menu responsive menu and splash at $size', (t) async {
      await mountMenu(t, size: size, scale: size.width == 320 ? 2 : 1);
      expect(t.takeException(), isNull);
      await t.pumpWidget(
        MaterialApp(theme: canopyTheme, home: const SplashScreen(failed: true)),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'main_menu image edges blend into exact backing colour without a seam',
    (t) async {
      const size = Size(390, 932);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await scenes.mount(
        t,
        size,
        RepaintBoundary(
          key: key,
          child: MenuBackdrop(
            asset: menuBackgrounds[1],
            child: const SizedBox.expand(),
          ),
        ),
        menuBackgrounds[1],
      );
      final render = t.renderObject<RenderImage>(
        find.descendant(
          of: find.byType(SceneArtwork),
          matching: find.byType(RawImage),
        ),
      );
      final height = size.width * render.image!.height / render.image!.width;
      final top = (size.height - height) / 2, bottom = top + height;
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        for (final y in [
          top.floor() - 1,
          top.ceil(),
          bottom.floor() - 1,
          bottom.ceil(),
        ]) {
          final offset = (y * 390 + 195) * 4;
          expect((bytes.getUint8(offset) - 16).abs(), lessThanOrEqualTo(2));
          expect((bytes.getUint8(offset + 1) - 42).abs(), lessThanOrEqualTo(2));
          expect((bytes.getUint8(offset + 2) - 40).abs(), lessThanOrEqualTo(2));
        }
        image.dispose();
      });
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'main_menu actual application restores pending save only after continue',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final g = testGame();
      g.startAction(CampAction.forage);
      final storage = MemoryRunStorage(g.toJson());
      await t.pumpWidget(
        LostCanopyApp(
          storage: storage,
          enableAudio: false,
          enableHaptics: false,
        ),
      );
      for (
        var i = 0;
        i < 200 && find.byType(MainMenuScreen).evaluate().isEmpty;
        i++
      ) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await t.pump();
      }
      await t.pumpAndSettle();
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(storage.saved!['pendingEvent'], g.pendingEvent!.id);
      await press(t, 'menu-enter-journey');
      expect(find.byType(MainMenuScreen), findsNothing);
      expect(storage.saved!['pendingEvent'], g.pendingEvent!.id);
      expect(t.takeException(), isNull);
    },
  );
}
