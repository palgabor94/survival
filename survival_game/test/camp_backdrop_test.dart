import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/rescue_progress.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/camp_backdrop.dart';
import 'package:survival_game/ui/camp_widgets.dart';
import 'package:survival_game/ui/camp_character.dart';
import 'package:survival_game/ui/scene_artwork.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    RunState state, {
    bool busy = false,
    bool reduced = false,
    int? initial,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Other widget suites can leave asset futures in their expired fake clock.
    rootBundle.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: SizedBox.expand(
              child: CampBackdrop(
                state: state,
                busy: busy,
                initialVariant: initial,
              ),
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(CampBackdrop));
    var loaded = false;
    Future.wait([
      precacheImage(AssetImage(campArt(state.campTier)), context),
      for (var i = 0; i < campActivities.length; i++)
        precacheImage(AssetImage(campCharacterArt(state.campTier, i)), context),
    ]).then((_) => loaded = true);
    for (var attempt = 0; !loaded && attempt < 200; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(
      loaded,
      isTrue,
      reason: 'Camp variants must decode before timing checks',
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  String current(WidgetTester tester) => tester
      .widget<SceneArtwork>(
        find
            .descendant(
              of: find.byType(CampBackdrop),
              matching: find.byType(SceneArtwork),
            )
            .last,
      )
      .asset;

  String character(WidgetTester tester) =>
      (tester
                  .widgetList<Image>(
                    find.descendant(
                      of: find.byType(CampCharacter),
                      matching: find.byType(Image),
                    ),
                  )
                  .last
                  .image
              as AssetImage)
          .assetName;

  Future<void> tick(WidgetTester tester) async {
    await tester.pump(CampBackdrop.interval);
    await tester.pumpAndSettle();
  }

  test(
    'four distinct empty camp backgrounds and six genuine alpha sprites',
    () async {
      final bytes = <String>{};
      for (var tier = 0; tier <= 3; tier++) {
        for (var variant = 0; variant < campActivities.length; variant++) {
          final data = File(campArt(tier, variant: variant)).readAsBytesSync();
          final codec = await ui.instantiateImageCodec(data);
          final image = (await codec.getNextFrame()).image;
          expect(image.width / image.height, closeTo(9 / 16, .005));
          image.dispose();
          codec.dispose();
          bytes.add(base64Encode(data));
        }
      }
      expect(bytes.length, 4);
      expect(campArt(0, variant: 2), starterCampBackground);
      final sprites = <String>{};
      for (final asset in {...starterCampSprites, campSeatedRight}) {
        final data = File(asset).readAsBytesSync();
        sprites.add(base64Encode(data));
        final codec = await ui.instantiateImageCodec(data);
        final image = (await codec.getNextFrame()).image;
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var transparent = 0;
        var opaque = 0;
        for (var i = 3; i < pixels.lengthInBytes; i += 4) {
          if (pixels.getUint8(i) == 0) transparent++;
          if (pixels.getUint8(i) >= 250) opaque++;
        }
        expect(transparent, greaterThan(image.width * image.height * .5));
        expect(opaque, greaterThan(image.width * image.height * .1));
        image.dispose();
        codec.dispose();
      }
      expect(sprites.length, 6);
    },
  );

  testWidgets(
    'ambient camp cycles all five poses at every tier without changing run state',
    (tester) async {
      for (final tier in [0, 1, 2, 3]) {
        final state = RunState(campTier: tier);
        final before = jsonEncode(state.toJson());
        await mount(tester, state);
        expect(current(tester), campArt(tier));
        for (final next in [1, 2, 3, 4, 0]) {
          await tick(tester);
          expect(current(tester), campArt(tier, variant: next));
          expect(character(tester), campCharacterArt(tier, next));
          expect(jsonEncode(state.toJson()), before);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('starter pose fades without fading or replacing the background', (
    tester,
  ) async {
    await mount(tester, RunState());
    final background = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image == const AssetImage(starterCampBackground),
    );
    final element = tester.element(background);
    await tester.pump(CampBackdrop.interval);
    await tester.pump(const Duration(milliseconds: 100));
    expect(identical(tester.element(background), element), isTrue);
    expect(
      find.descendant(
        of: find.byType(CampBackdrop),
        matching: find.ancestor(
          of: background,
          matching: find.byType(FadeTransition),
        ),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('camp-character-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('camp-character-0-1')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(character(tester), starterCampCharacter(1));
    expect(find.byKey(const ValueKey('camp-character-0-0')), findsNothing);
  });

  testWidgets(
    'starter sprite stays registered to decoded art on phones and landscape',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final size in [
        const Size(390, 844),
        const Size(430, 932),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(const SizedBox.shrink());
        await mount(tester, RunState(), reduced: true, initial: 2);
        final raw = tester.widget<RawImage>(
          find
              .descendant(
                of: find.byWidgetPredicate(
                  (widget) =>
                      widget is Image &&
                      widget.image == const AssetImage(starterCampBackground),
                ),
                matching: find.byType(RawImage),
              )
              .first,
        );
        final source = Size(
          raw.image!.width.toDouble(),
          raw.image!.height.toDouble(),
        );
        final scale = size.width <= size.height
            ? size.width / source.width
            : (size.width / source.width > size.height / source.height
                  ? size.width / source.width
                  : size.height / source.height);
        final art = const Alignment(
          0,
          .18,
        ).inscribe(source * scale, Offset.zero & size);
        final characterWidget = tester.widget<CampCharacter>(
          find.byType(CampCharacter),
        );
        expect(characterWidget.artworkRect, art);
        final sprite = tester.getRect(
          find.byKey(const ValueKey('camp-character-sprite')),
        );
        expect(sprite.width, closeTo(art.width * .22, .001));
        expect(sprite.height, closeTo(sprite.width, .001));
        expect(
          sprite.left + sprite.width * .5,
          closeTo(art.left + art.width * .47, .001),
        );
        expect(
          sprite.top + sprite.height * .88,
          closeTo(art.top + art.height * .72, .001),
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new days vary the pose without idle time or animation', (
    tester,
  ) async {
    for (final day in [1, 2, 3, 4, 5, 6]) {
      await mount(
        tester,
        RunState(campTier: 2, day: day),
        reduced: true,
        busy: true,
      );
      expect(current(tester), campArt(2));
      expect(character(tester), campCharacterArt(2, (day - 1) % 5));
    }
    // Reopening on day three also selects a different pose immediately.
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, RunState(campTier: 3, day: 3));
    expect(current(tester), campArt(3));
    expect(character(tester), campCharacterArt(3, 2));
  });

  testWidgets('busy camp and reduced motion keep the artwork still', (
    tester,
  ) async {
    await mount(tester, RunState(campTier: 1), busy: true);
    await tick(tester);
    expect(current(tester), campArt(1));
    expect(character(tester), campCharacterArt(1, 0));
    await mount(tester, RunState(campTier: 1), reduced: true);
    await tick(tester);
    expect(current(tester), campArt(1));
    expect(character(tester), campCharacterArt(1, 0));
  });

  testWidgets('starter night keeps its own new pose with night tint', (
    tester,
  ) async {
    await mount(
      tester,
      RunState(campTier: 0, phase: RunPhase.night),
      initial: 1,
    );
    await tick(tester);
    expect(current(tester), starterCampBackground);
    expect(character(tester), starterCampCharacter(1));
    final image = tester.widgetList<Image>(find.byType(Image)).last;
    expect(
      tester.widget<SceneArtwork>(find.byType(SceneArtwork)).tint,
      campNightTint,
    );
    expect(image.color, campNightTint);
    expect(image.colorBlendMode, BlendMode.modulate);
  });

  testWidgets('popup and paused app suspend changes then resume the cycle', (
    tester,
  ) async {
    await mount(tester, RunState(campTier: 3));
    final context = tester.element(find.byType(CampBackdrop));
    final dialog = showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(title: Text('Inventory')),
    );
    await tester.pumpAndSettle();
    await tick(tester);
    expect(current(tester), campArt(3));
    expect(character(tester), campCharacterArt(3, 0));
    Navigator.of(context).pop();
    await dialog;
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tick(tester);
    expect(current(tester), campArt(3));
    expect(character(tester), campCharacterArt(3, 0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tick(tester);
    expect(current(tester), campArt(3));
    expect(character(tester), campCharacterArt(3, 1));
  });

  testWidgets(
    'night and rescue storm preserve their scene and tier upgrade resets pose',
    (tester) async {
      await mount(
        tester,
        RunState(campTier: 2, phase: RunPhase.night),
        initial: 1,
      );
      await tick(tester);
      expect(current(tester), campArt(2));
      expect(character(tester), campCharacterArt(2, 1));
      expect(
        tester.widgetList<Image>(find.byType(Image)).last.colorBlendMode,
        BlendMode.modulate,
      );
      await mount(
        tester,
        RunState(campTier: 3, rescueStage: RescueStage.storm),
      );
      await tick(tester);
      expect(current(tester), 'assets/art/rescue_storm_camp_style_v1.png');
      expect(find.byType(CampCharacter), findsNothing);
      await mount(tester, RunState(campTier: 2));
      await tick(tester);
      expect(current(tester), campArt(2));
      expect(character(tester), campCharacterArt(2, 1));
      await mount(tester, RunState(campTier: 3));
      expect(current(tester), campArt(3));
      expect(character(tester), campCharacterArt(3, 0));
    },
  );
}
