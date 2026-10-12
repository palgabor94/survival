import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
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
    final recipes = RecipeCatalog.fromJson(
      File('assets/data/recipes.json').readAsStringSync(),
    );
    final engine = GameEngine(
      EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
      random: Random(42),
      world: WorldCatalog.fromJson(
        File('assets/data/locations.json').readAsStringSync(),
      ),
      recipes: recipes,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: LostCanopyApp(engine: engine),
      ),
    );
    await tester.pumpAndSettle();
    // Decode the real assets before capturing the first frame.
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold).first);
      await precacheImage(
        const AssetImage('assets/art/starter_camp.png'),
        context,
      );
      if (!context.mounted) return;
      await precacheImage(const AssetImage('assets/art/ui_atlas.png'), context);
      if (!context.mounted) return;
      await precacheImage(
        const AssetImage('assets/art/hud_atlas.png'),
        context,
      );
      if (!context.mounted) return;
      await precacheImage(
        const AssetImage('assets/art/starter_camp_night.png'),
        context,
      );
    });
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

    await capture('camp');
    await tester.tap(find.byKey(const ValueKey('open-inventory')));
    await tester.pumpAndSettle();
    await capture('inventory');
    await tester.tap(find.text('Back to camp'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('action-explore')));
    await tester.pumpAndSettle();
    await capture('explore-map');
    await tester.tap(find.byKey(const ValueKey('travel-destination')));
    await tester.pumpAndSettle();
    await capture('event');
    await tester.tap(
      find.byKey(
        ValueKey(
          'choice-${engine.pendingEvent!.choices.firstWhere(engine.canChoose).id}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('outcome');
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    // The trip waits for a decision; head home with the haul.
    await tester.tap(find.byKey(const ValueKey('expedition-return')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    while (engine.state.timeLeft > 0) {
      await tester.tap(find.byKey(const ValueKey('action-rest')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('continue-outcome')));
      await tester.pumpAndSettle();
    }
    await capture('night-event');
    await tester.tap(
      find.byKey(
        ValueKey(
          'choice-${engine.pendingEvent!.choices.firstWhere(engine.canChoose).id}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    await capture('night-camp');
    await tester.tap(find.byKey(const ValueKey('action-rest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    await capture('day-two');

    // Milestone 3: a stocked camp builds its first upgrade.
    await tester.pumpWidget(const SizedBox.shrink());
    final builder = GameEngine(
      engine.catalog,
      random: Random(7),
      world: engine.world,
      recipes: recipes,
      initialState: RunState(
        day: 3,
        tools: {'basic_rod', 'stone_knife'},
        resources: {'wood': 11, 'stone': 2, 'fiber': 8, 'herb': 2, 'bait': 1},
      ),
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: LostCanopyApp(engine: builder),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold).first);
      for (var tier = 1; tier <= 3; tier++) {
        await precacheImage(
          AssetImage('assets/art/camp_tier_$tier.png'),
          context,
        );
        if (!context.mounted) return;
      }
    });
    await tester.tap(find.byKey(const ValueKey('open-workshop')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-stone_axe')));
    await tester.pumpAndSettle();
    await capture('workshop');
    await tester.tap(find.byKey(const ValueKey('tab-camp')));
    await tester.pumpAndSettle();
    await capture('workshop-camp');
    await tester.tap(find.byKey(const ValueKey('craft-camp_tier_1')));
    await tester.pumpAndSettle();
    await capture('camp-upgraded');
    await tester.tap(find.byKey(const ValueKey('continue-outcome')));
    await tester.pumpAndSettle();
    await capture('camp-tier-1');

    // Card scene: four cards, one of them shown only because the survivor is hurt.
    await tester.pumpWidget(const SizedBox.shrink());
    final hurt = GameEngine(
      engine.catalog,
      random: _First(),
      world: engine.world,
      recipes: recipes,
      initialState: RunState(
        day: 2,
        resources: {'wood': 3, 'herb': 1},
        stats: {
          SurvivalStat.health: 48,
          SurvivalStat.water: 61,
          SurvivalStat.food: 44,
          SurvivalStat.sanity: 72,
        },
      ),
    )..startAction(CampAction.explore);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: LostCanopyApp(engine: hurt),
      ),
    );
    await tester.pumpAndSettle();
    await capture('event-cards');

    // Expedition: the decision after a stop, then an attack with gear.
    await tester.pumpWidget(const SizedBox.shrink());
    final trip = GameEngine(
      engine.catalog,
      random: _Roll(.99),
      world: engine.world,
      recipes: recipes,
      initialState: RunState(
        day: 3,
        campTier: 1,
        tools: {'torch', 'stone_knife', 'basic_rod'},
        resources: {'wood': 3, 'raw_meat': 1, 'herb': 1},
      ),
    )..travelTo('riverbank');
    trip.choose(trip.visibleChoices.first.id);
    trip.continueFromReport();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: LostCanopyApp(engine: trip),
      ),
    );
    await tester.pumpAndSettle();
    await capture('expedition-decision');
    await tester.tap(find.byKey(const ValueKey('expedition-deeper')));
    await tester.pumpAndSettle();
    await capture('expedition-step');
    await tester.pumpWidget(const SizedBox.shrink());
    final attack = GameEngine(
      engine.catalog,
      random: _Roll(0),
      world: engine.world,
      recipes: recipes,
      initialState: RunState(
        day: 4,
        campTier: 1,
        tools: {'torch', 'stone_knife'},
        resources: {'wood': 3, 'raw_meat': 1},
        stats: {
          SurvivalStat.health: 82,
          SurvivalStat.water: 58,
          SurvivalStat.food: 51,
          SurvivalStat.sanity: 66,
        },
      ),
    )..travelTo('riverbank');
    attack.choose(attack.visibleChoices.first.id);
    attack.continueFromReport();
    attack.goDeeper();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: LostCanopyApp(engine: attack),
      ),
    );
    await tester.pumpAndSettle();
    await capture('encounter');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  exit(0);
}

/// Always the first eligible event, so captures are reproducible.
class _First implements Random {
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

class _Roll implements Random {
  _Roll(this.roll);
  final double roll;
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => roll;
  @override
  int nextInt(int max) => 0;
}
