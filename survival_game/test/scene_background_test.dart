import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/camp_backdrop.dart';
import 'package:survival_game/ui/camp_character.dart';
import 'package:survival_game/ui/camp_widgets.dart';
import 'package:survival_game/ui/canopy_components.dart';
import 'package:survival_game/ui/gathering_screen.dart';
import 'package:survival_game/ui/scene_artwork.dart';

import 'game/gathering_test.dart' show gatheringGame;

Finder asset(String path) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == path,
);

Future<void> mount(
  WidgetTester tester,
  Size size,
  Widget body,
  String path,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  rootBundle.clear();
  PaintingBinding.instance.imageCache.clear();
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  var loaded = false;
  precacheImage(
    AssetImage(path),
    tester.element(find.byType(Scaffold).first),
  ).then((_) => loaded = true);
  for (var i = 0; !loaded && i < 200; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(loaded, isTrue);
  await tester.pump();
}

RenderImage rendered(WidgetTester tester, String path) =>
    tester.renderObject<RenderImage>(
      find.descendant(of: asset(path), matching: find.byType(RawImage)).first,
    );

void fullWidth(RenderImage image) {
  final source = Size(
    image.image!.width.toDouble(),
    image.image!.height.toDouble(),
  );
  final fitted = applyBoxFit(image.fit!, source, image.size);
  // Check actual decoded source and painted bounds, not just a BoxFit enum.
  expect(fitted.source.width, closeTo(source.width, .001));
  expect(fitted.destination.width, closeTo(image.size.width, .001));
  expect(
    fitted.destination.width / fitted.source.width,
    closeTo(fitted.destination.height / fitted.source.height, .00001),
  );
}

void main() {
  testWidgets(
    'exposed image edges fade to transparent while the center stays opaque',
    (tester) async {
      const size = Size(390, 844);
      final path = campArt(0);
      final boundaryKey = GlobalKey();
      await mount(
        tester,
        size,
        SizedBox.expand(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SceneArtwork(asset: path),
          ),
        ),
        path,
      );
      final decoded = rendered(tester, path).image!;
      final height = size.width * decoded.height / decoded.width;
      final top = (size.height - height) / 2;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final pixels = await boundary.toImage();
        final bytes = (await pixels.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        int alpha(int y) =>
            bytes.getUint8((y * pixels.width + pixels.width ~/ 2) * 4 + 3);
        expect(alpha(0), 0);
        expect(alpha(top.ceil() + 1), lessThan(30));
        expect(alpha(size.height ~/ 2), 255);
        expect(alpha((top + height).floor() - 2), lessThan(30));
        expect(alpha(size.height.toInt() - 1), 0);
        pixels.dispose();
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('night tint preserves transparent sprite margins', (
    tester,
  ) async {
    const size = Size(390, 844);
    final boundaryKey = GlobalKey();
    await mount(
      tester,
      size,
      SizedBox.expand(
        child: RepaintBoundary(
          key: boundaryKey,
          child: const CampCharacter(
            artworkRect: Rect.fromLTWH(0, 0, 390, 844),
            variant: 0,
            tint: campNightTint,
          ),
        ),
      ),
      starterCampCharacter(0),
    );
    final sprite = tester.getRect(
      find.byKey(const ValueKey('camp-character-sprite')),
    );
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final pixels = await boundary.toImage();
      final bytes = (await pixels.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int alpha(Offset point) => bytes.getUint8(
        (point.dy.floor() * pixels.width + point.dx.floor()) * 4 + 3,
      );
      expect(alpha(sprite.topLeft + const Offset(5, 5)), 0);
      expect(alpha(sprite.center), greaterThan(240));
      pixels.dispose();
    });
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
  ]) {
    testWidgets(
      'portrait backgrounds preserve both horizontal edges at $size',
      (tester) async {
        final path = campArt(0);
        await mount(
          tester,
          size,
          CampBackdrop(state: RunState(), busy: true),
          path,
        );
        fullWidth(rendered(tester, path));
        await tester.pumpWidget(const SizedBox.shrink());
        await mount(
          tester,
          size,
          CanopyBackdrop(
            background: path,
            alignment: const Alignment(-.2, -.15),
            child: const SizedBox.shrink(),
          ),
          path,
        );
        fullWidth(rendered(tester, path));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('landscape backgrounds still fill the viewport', (tester) async {
    final path = campArt(2);
    await mount(
      tester,
      const Size(844, 390),
      CanopyBackdrop(background: path, child: const SizedBox.shrink()),
      path,
    );
    final image = rendered(tester, path);
    final fitted = applyBoxFit(
      image.fit!,
      Size(image.image!.width.toDouble(), image.image!.height.toDouble()),
      image.size,
    );
    expect(fitted.destination, image.size);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(430, 932)]) {
    testWidgets(
      'hunting sprite and target follow the width-fitted scene at $size',
      (tester) async {
        final game = gatheringGame()..openGathering(GatheringKind.hunting);
        const path = 'assets/art/hunting_background_v1.png';
        await mount(tester, size, GatheringScreen(game: game), path);
        final start = find.byKey(const ValueKey('gathering-start'));
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pump();
        final image = rendered(tester, path);
        fullWidth(image);
        final height = size.width * image.image!.height / image.image!.width;
        final top = (size.height - height) / 2;
        final boar = tester.getRect(
          asset('assets/art/hunting_boar_sprite_v2.png'),
        );
        expect(boar.center.dy, closeTo(top + height * .4625, .01));
        final target = tester.getCenter(
          find.byKey(const ValueKey('hunting-scene-target')),
        );
        expect(target.dy, closeTo(boar.center.dy, .01));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
