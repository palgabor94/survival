import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/craft_screen.dart';
import 'package:survival_game/ui/camp_screen.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import '../tools/capture_fonts.dart';

Future<void> main() async {
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final game = GameEngine(
      EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
      recipes: RecipeCatalog.fromJson(
        File('assets/data/recipes.json').readAsStringSync(),
      ),
      initialState: RunState(
        day: 3,
        tools: {'basic_rod'},
        resources: {
          'wood': 12,
          'stone': 4,
          'fiber': 8,
          'bait': 2,
          'herb': 2,
          'small_fish': 1,
        },
      ),
    );
    final boundary = GlobalKey();
    String? result;
    Future<void> settle() async {
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      final providers = find
          .byType(Image)
          .evaluate()
          .map((e) => (e.widget as Image).image)
          .toSet();
      await tester.runAsync(
        () => Future.wait(
          [
            ...providers,
            const AssetImage('assets/art/ui_parchment_texture.png'),
          ].map((p) => precacheImage(p, context)),
        ),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$error');
    }

    Future<void> shot(String name) async {
      await settle();
      final b =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final im = await b.toImage(pixelRatio: 3);
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      File(
        'screenshots/parchment-craft-v1/$name.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      im.dispose();
      stdout.writeln('CAPTURED $name');
    }

    await binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: canopyTheme,
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => CraftScreen(game: game)),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await shot('01-craft');
    await tester.tap(find.byKey(const ValueKey('recipe-stone_axe')));
    await shot('02-stone-axe-details');
    if (game.state.resource('wood') != 12) {
      throw StateError('Selection spent resources');
    }
    await tester.tap(find.byTooltip('Close').last);
    await settle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('recipe-drying_rack')),
    );
    await tester.tap(find.byKey(const ValueKey('recipe-drying_rack')));
    await settle();
    final disabled = tester.widget<FilledButton>(
      find.byKey(const ValueKey('craft-drying_rack')),
    );
    if (disabled.onPressed != null) throw StateError('Locked recipe enabled');
    await tester.tap(find.byTooltip('Close').last);
    await settle();
    await tester.ensureVisible(find.byKey(const ValueKey('recipe-stone_axe')));
    await tester.tap(find.byKey(const ValueKey('recipe-stone_axe')));
    await settle();
    await tester.tap(find.byKey(const ValueKey('craft-stone_axe')));
    await settle();
    if (result != 'stone_axe') {
      throw StateError('Confirmation did not return recipe');
    }
    if (game.state.resource('wood') != 12) {
      throw StateError('Craft screen bypassed camp transaction');
    }
    stdout.writeln(
      'PASS: selection, close, locked recipe, confirmation and transaction ownership',
    );
    await tester.tap(find.text('OPEN'));
    await settle();
    await tester.tap(find.byKey(const ValueKey('tab-camp')));
    await shot('03-camp-upgrades');
    await tester.tap(find.byKey(const ValueKey('recipe-camp_tier_1')));
    await shot('04-basic-refuge-details');
    await tester.tap(find.byTooltip('Close').last);
    await settle();
    await tester.tap(find.byKey(const ValueKey('craft-back')));
    await settle();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: canopyTheme,
          debugShowCheckedModeBanner: false,
          home: CampScreen(engine: game, initialCampVariant: 0),
        ),
      ),
    );
    await settle();
    await tester.tap(find.byKey(const ValueKey('open-inventory')));
    await shot('05-items-materials');
    final sizes = ['wood', 'stone', 'fiber', 'bait']
        .map((id) => tester.getSize(find.byKey(ValueKey('inventory-$id'))))
        .toList();
    if (sizes.any((size) => size != sizes.first)) {
      throw StateError('Item card sizes differ');
    }
    await tester.tap(find.byKey(const ValueKey('inventory-bait')));
    await shot('06-bait-details');
    await tester.tap(find.byTooltip('Close').last);
    await settle();
    await tester.tap(find.byKey(const ValueKey('inventory-tab-1')));
    await shot('07-items-food');
    await tester.tap(find.byKey(const ValueKey('inventory-herb')));
    await shot('08-herb-details');
    if (game.state.resource('herb') != 2) {
      throw StateError('Opening item used it');
    }
    await tester.tap(find.byKey(const ValueKey('consume-herb')));
    await settle();
    if (game.state.resource('herb') != 1) {
      throw StateError('Camp did not consume exactly one herb');
    }
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await settle();
    await tester.tap(find.byKey(const ValueKey('open-inventory')));
    await settle();
    await tester.tap(find.byKey(const ValueKey('inventory-tab-2')));
    await shot('09-items-gear');
    await tester.tap(find.byKey(const ValueKey('inventory-basic_rod')));
    await shot('10-rod-details');
    await tester.tap(find.byTooltip('Close').last);
    await settle();
    await tester.tap(find.byKey(const ValueKey('close-dialog')));
    await settle();
    stdout.writeln(
      'PASS: camp tab, uniform item cards, material/food/gear details and consume confirmation',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  timer.cancel();
  exit(0);
}
