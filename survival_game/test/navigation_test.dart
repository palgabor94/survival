import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/beacon_screen.dart';
import 'package:survival_game/ui/camp_backdrop.dart';
import 'package:survival_game/ui/camp_widgets.dart';
import 'package:survival_game/ui/camp_character.dart';
import 'package:survival_game/ui/scene_artwork.dart';
import 'package:survival_game/ui/canopy_components.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/event_scene.dart';

import 'expedition_widget_test.dart' show tapKey;
import 'widget_test.dart' show testGame, showCamp, tapAction;

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final reduced in [false, true]) {
      testWidgets(
        '$platform push/pop fades in place; reduced motion $reduced',
        (tester) async {
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final navigator = GlobalKey<NavigatorState>();
          const destination = ValueKey('destination');
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              theme: canopyTheme.copyWith(platform: platform),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
                child: child!,
              ),
              home: const Scaffold(body: Text('Camp')),
            ),
          );
          final result = navigator.currentState!.push<String>(
            MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(key: destination, body: Text('Scene')),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));
          expect(
            tester.getRect(find.byKey(destination)),
            const Rect.fromLTWH(0, 0, 375, 812),
          );
          final fades = find.ancestor(
            of: find.byKey(destination),
            matching: find.byType(FadeTransition),
          );
          if (reduced) {
            expect(fades, findsNothing);
          } else {
            expect(fades, findsOneWidget);
            expect(
              tester.widget<FadeTransition>(fades).opacity.value,
              inExclusiveRange(0, 1),
            );
          }
          expect(
            find.ancestor(
              of: find.byKey(destination),
              matching: find.byType(SlideTransition),
            ),
            findsNothing,
          );
          await tester.pumpAndSettle();
          navigator.currentState!.pop('done');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          expect(
            tester.getRect(find.byKey(destination)),
            const Rect.fromLTWH(0, 0, 375, 812),
          );
          await tester.pumpAndSettle();
          expect(await result, 'done');
          expect(find.text('Camp'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'production app uses five separate character poses at all four camp tiers',
    (tester) async {
      rootBundle.clear();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      for (final tier in [0, 1, 2, 3]) {
        for (final day in [1, 2, 3, 4, 5]) {
          final path = campArt(tier, variant: day - 1);
          final bytes = await tester.runAsync(() => rootBundle.load(path));
          expect(bytes!.lengthInBytes, greaterThan(0));
          await showCamp(
            tester,
            testGame(
              state: RunState(campTier: tier, day: day),
            ),
          );
          final artwork = tester.widget<SceneArtwork>(
            find
                .descendant(
                  of: find.byType(CampBackdrop),
                  matching: find.byType(SceneArtwork),
                )
                .last,
          );
          expect(artwork.asset, path);
          {
            // The overlay is registered only after the JPEG actually decodes.
            for (
              var i = 0;
              find.byType(CampCharacter).evaluate().isEmpty && i < 200;
              i++
            ) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
              await tester.pump();
            }
            final pose = tester.widget<CampCharacter>(
              find.byType(CampCharacter),
            );
            expect(pose.variant, day - 1);
            expect(pose.tier, tier);
          }
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('camp event and beacon retain the current camp pose', (
    tester,
  ) async {
    rootBundle.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    final game = testGame(state: RunState(campTier: 2, day: 2));
    await showCamp(tester, game);
    final context = tester.element(find.byType(CampBackdrop));
    var loaded = false;
    Future.wait([
      precacheImage(AssetImage(campArt(2)), context),
      precacheImage(AssetImage(campCharacterArt(2, 1)), context),
    ]).then((_) => loaded = true);
    for (var i = 0; !loaded && i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(loaded, isTrue);
    await tester.pumpAndSettle();
    await tapKey(tester, 'camp-menu');
    await tapKey(tester, 'menu-beacon');
    expect(find.byType(BeaconScreen), findsOneWidget);
    expect(tester.widget<CampCharacter>(find.byType(CampCharacter)).variant, 1);
    expect(
      tester
          .widget<CanopyBackdrop>(
            find.descendant(
              of: find.byType(BeaconScreen),
              matching: find.byType(CanopyBackdrop),
            ),
          )
          .background,
      campArt(2, variant: 1),
    );
    await tapKey(tester, 'beacon-back');
    await tapAction(tester, 'forage');
    expect(find.byType(EventScene), findsOneWidget);
    expect(tester.widget<CampCharacter>(find.byType(CampCharacter)).variant, 1);
    expect(
      tester
          .widget<CanopyBackdrop>(
            find.descendant(
              of: find.byType(EventScene),
              matching: find.byType(CanopyBackdrop),
            ),
          )
          .background,
      campArt(2, variant: 1),
    );
    final choice = game.visibleChoices.firstWhere(game.canChoose);
    await tapKey(tester, 'choice-${choice.id}');
    await tapKey(tester, 'continue-outcome');
    final image = tester
        .widgetList<Image>(
          find.descendant(
            of: find.byType(CampBackdrop),
            matching: find.byType(Image),
          ),
        )
        .last;
    expect((image.image as AssetImage).assetName, campCharacterArt(2, 1));
    expect(tester.takeException(), isNull);
  });
}
