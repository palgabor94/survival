import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';
import 'package:survival_game/main.dart';

import 'capture_fonts.dart';

Future<void> main() async {
  final binding = LiveTestWidgetsFlutterBinding();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    await binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    final engine = GameEngine(
      EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
      world: WorldCatalog.fromJson(
        File('assets/data/locations.json').readAsStringSync(),
      ),
      random: Random(42),
      initialState: RunState(
        day: 2,
        tools: {'basic_rod'},
        resources: {'wood': 0, 'stone': 0, 'fiber': 0, 'bait': 1},
      ),
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: LostCanopyApp(engine: engine),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'screenshots/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.tap(find.byKey(const ValueKey('open-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fishing Pond'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go fishing · 2 time'));
    await tester.pumpAndSettle();
    await capture('fishing-ready');
    await tester.tap(find.byKey(const ValueKey('cast-line')));
    await tester.pump(const Duration(milliseconds: 250));
    await capture('fishing-waiting');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  exit(0);
}
