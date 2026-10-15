import 'dart:convert';
import 'package:survival_game/game/run_progression.dart';
import 'package:survival_game/ui/progression_screens.dart' as progression;
import 'package:survival_game/game/tool_catalog.dart';
import 'package:survival_game/ui/tool_panels.dart';
import 'package:survival_game/ui/inventory_panels.dart';
import 'package:survival_game/ui/inventory_dialog.dart';
import 'package:survival_game/audio/music_controller.dart';
import 'package:survival_game/audio/sounds_controller.dart';
import 'package:survival_game/feedback/haptics_controller.dart';
import '../../test/music_test.dart' show FakeMusicPlayer;
import '../../test/sounds_test.dart' show FakeSoundPlayer;
import '../../test/haptics_test.dart' show FakeHapticDevice;
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/fishing_session.dart';
import 'package:survival_game/ui/fishing_panels.dart';
import '../../test/game/fishing_session_test.dart'
    show waitForBite, reelByTracking;
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/rescue_progress.dart';
import 'package:survival_game/game/world_catalog.dart';
import 'package:survival_game/main.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/card_illustration.dart';
import 'package:survival_game/ui/craft_screen.dart';
import 'package:survival_game/ui/event_scene.dart';
import 'package:survival_game/ui/expedition_scene.dart';
import 'package:survival_game/ui/explore_map_screen.dart';
import 'package:survival_game/ui/fishing_screen.dart';
import 'package:survival_game/ui/gathering_screen.dart';
import 'package:survival_game/ui/camp_screen.dart';
import 'package:survival_game/ui/camp_widgets.dart';
import 'package:survival_game/ui/camp_character.dart';

import 'capture_fonts.dart';
import 'package:survival_game/ui/day_end_screen.dart';
import 'package:survival_game/ui/event_dialog.dart';

/// Actual Flutter screens rendered at phone size. This is an image exporter,
/// not the gameplay test suite. Seeded states make the gallery reproducible.
Future<void> main() async {
  stdout.writeln('EXPORT START');
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  // A gallery visits many large backgrounds; retain only a small warm cache.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 24;
  final runProgression =
      Platform.environment['LOST_CANOPY_CAPTURE_PROGRESSION'] == '1';
  final inventoryProgression =
      Platform.environment['LOST_CANOPY_CAPTURE_INVENTORY'] == '1';
  final toolProgression =
      Platform.environment['LOST_CANOPY_CAPTURE_TOOLS'] == '1';
  final sceneRevision =
      Platform.environment['LOST_CANOPY_CAPTURE_SCENES'] == '1';
  final eventRevision =
      Platform.environment['LOST_CANOPY_CAPTURE_EVENT_CHOICES'] == '1';
  final artReview =
      Platform.environment['LOST_CANOPY_CAPTURE_ART_REVIEW'] == '1';
  final cardExample =
      Platform.environment['LOST_CANOPY_CAPTURE_CARD_EXAMPLE'] == '1';
  final fiveCardExamples =
      Platform.environment['LOST_CANOPY_CAPTURE_FIVE_CARDS'] == '1';
  final cardSet = Platform.environment['LOST_CANOPY_CAPTURE_CARD_SET'] == '1';
  final expansion =
      Platform.environment['LOST_CANOPY_CAPTURE_EXPANSION'] == '1';
  final encounterStyle =
      Platform.environment['LOST_CANOPY_CAPTURE_ENCOUNTER_STYLE'] == '1';
  final styleRefresh =
      Platform.environment['LOST_CANOPY_CAPTURE_STYLE_REFRESH'] == '1';
  final rescue = Platform.environment['LOST_CANOPY_CAPTURE_RESCUE'] == '1';
  final campVariants =
      Platform.environment['LOST_CANOPY_CAPTURE_CAMP_VARIANTS'] == '1';
  final starterVariants =
      Platform.environment['LOST_CANOPY_CAPTURE_STARTER_VARIANTS'] == '1';
  final minigames =
      Platform.environment['LOST_CANOPY_CAPTURE_MINIGAMES'] == '1';
  final fishingTutorial =
      Platform.environment['LOST_CANOPY_CAPTURE_FISHING_TUTORIAL'] == '1';
  final allCampLayers =
      Platform.environment['LOST_CANOPY_CAPTURE_ALL_CAMP_LAYERS'] == '1';
  final campLayers =
      Platform.environment['LOST_CANOPY_CAPTURE_CAMP_LAYERS'] == '1';
  final sceneWidth =
      Platform.environment['LOST_CANOPY_CAPTURE_SCENE_WIDTH'] == '1';
  final itemsRefresh =
      Platform.environment['LOST_CANOPY_CAPTURE_ITEMS_REFRESH'] == '1';
  final directory = Directory(
    Platform.environment['LOST_CANOPY_CAPTURE_OUTPUT'] ??
        (itemsRefresh
            ? 'screenshots/items-popup-v2'
            : allCampLayers
            ? 'screenshots/camp-layers-all-tiers-v1'
            : campLayers
            ? 'screenshots/camp-layers-tier0-v1'
            : sceneWidth
            ? 'screenshots/scene-width-v1'
            : fishingTutorial
            ? 'screenshots/fishing-tutorial-v1'
            : minigames
            ? 'screenshots/minigames-v1'
            : starterVariants
            ? 'screenshots/starter-camp-variants-v1'
            : styleRefresh
            ? 'screenshots/camp-style-refresh-v1'
            : campVariants
            ? 'screenshots/camp-variants-v2'
            : rescue
            ? 'screenshots/rescue-milestone-v1'
            : encounterStyle
            ? 'screenshots/encounter-style-v2'
            : expansion
            ? 'screenshots/expansion-v1'
            : cardSet
            ? 'screenshots/card-illustrations-v1'
            : fiveCardExamples
            ? 'screenshots/card-illustration-five-v1'
            : cardExample
            ? 'screenshots/card-illustration-example-v1'
            : artReview
            ? 'screenshots/card-art-v4'
            : eventRevision
            ? 'screenshots/event-choices-v3'
            : sceneRevision
            ? 'screenshots/scene-revision-v2'
            : 'screenshots/unified-ui-v1'),
  )..createSync(recursive: true);
  final catalog = EventCatalog.fromJson(
    File('assets/data/events.json').readAsStringSync(),
  );
  final world = WorldCatalog.fromJson(
    File('assets/data/locations.json').readAsStringSync(),
  );
  final recipes = RecipeCatalog.fromJson(
    File('assets/data/recipes.json').readAsStringSync(),
  );
  GameEngine game({RunState? state, double roll = .99}) => GameEngine(
    catalog,
    world: world,
    recipes: recipes,
    random: _Roll(roll),
    initialState:
        state ??
        RunState(
          day: 3,
          tools: {'basic_rod', 'stone_knife'},
          resources: {
            'wood': 11,
            'stone': 2,
            'fiber': 8,
            'bait': 2,
            'herb': 2,
            'small_fish': 2,
            'raw_meat': 1,
            'hardwood': 4,
            'metal_scrap': 5,
          },
          stats: {
            SurvivalStat.health: 100,
            SurvivalStat.water: 72,
            SurvivalStat.food: 69,
            SurvivalStat.sanity: 80,
          },
        ),
  );
  await benchmarkWidgets((tester) async {
    stdout.writeln('LOADING FONTS');
    await tester.runAsync(loadCaptureFonts);
    stdout.writeln('FONTS READY');
    await binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final boundaryKey = GlobalKey();
    final files = <String>[];
    Future<void> mount(
      Widget screen, {
      bool app = false,
      bool settle = true,
    }) async {
      await tester.pumpWidget(const SizedBox.shrink());
      if (screen is LostCanopyApp && app) {
        final music = MusicController(
          player: FakeMusicPlayer(),
          fadeStep: Duration.zero,
        )..volume = .65;
        final sounds = SoundsController(
          ambience: FakeSoundPlayer(),
          fire: FakeSoundPlayer(),
          steps: FakeSoundPlayer(),
          chopping: FakeSoundPlayer(),
          fadeStep: Duration.zero,
        )..volume = .8;
        screen = LostCanopyApp(
          engine: screen.engine,
          music: music,
          sounds: sounds,
          haptics: HapticsController(device: FakeHapticDevice()),
        );
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: app
              ? screen
              : MaterialApp(
                  theme: canopyTheme,
                  debugShowCheckedModeBanner: false,
                  home: screen,
                ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        if (campLayers || allCampLayers || itemsRefresh) {
          // Foreground sprites enter the widget tree after the background
          // decodes, so they may be absent from the initial Image traversal.
          for (final asset in {...starterCampSprites, campSeatedRight}) {
            await precacheImage(AssetImage(asset), context);
          }
        }
        if (runProgression ||
            inventoryProgression ||
            toolProgression ||
            minigames ||
            fishingTutorial ||
            sceneWidth ||
            itemsRefresh ||
            campLayers ||
            allCampLayers) {
          // Cache the rendered screen only: loading every unrelated scene can
          // consume a live attempt's entire timer before the first screenshot.
          final pictures = find
              .byType(Image)
              .evaluate()
              .map((e) => (e.widget as Image).image)
              .toSet();
          for (final picture in pictures) {
            if (context.mounted) await precacheImage(picture, context);
          }
          for (final file in [
            'mushroom_card_scene_v1',
            'unknown_plant_card_scene_v1',
          ]) {
            if (context.mounted) {
              await precacheImage(AssetImage('assets/art/$file.png'), context);
            }
          }
        } else {
          for (final file in Directory(
            'assets/art',
          ).listSync().whereType<File>()) {
            if (!file.path.endsWith('.png') || !context.mounted) continue;
            await precacheImage(AssetImage(file.path), context);
          }
        }
      });
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shot(String name) async {
      await tester.pump();
      final error = tester.takeException();
      if (error != null) throw StateError('Cannot capture $name: $error');
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final picture = await boundary.toImage(pixelRatio: 2);
        try {
          final data = await picture.toByteData(format: ui.ImageByteFormat.png);
          final temporary = File('${directory.path}/$name.png.tmp');
          temporary.writeAsBytesSync(data!.buffer.asUint8List());
          temporary.renameSync('${directory.path}/$name.png');
        } finally {
          picture.dispose();
        }
      });
      final exportError = tester.takeException();
      if (exportError != null) {
        throw StateError('Cannot write $name: $exportError');
      }
      files.add('$name.png');
      stdout.writeln('CAPTURED $name.png');
    }

    Future<void> tap(String key) async {
      final finder = find.byKey(ValueKey(key)).last;
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('confirm-card-action'));
      if (confirm.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(confirm).onPressed != null) {
        await tester.tap(confirm);
        await tester.pumpAndSettle();
      }
    }

    if (runProgression) {
      final g = game(
        state: RunState(
          day: 8,
          campTier: 2,
          tools: {'stone_axe', 'machete', 'torch'},
          resources: {'wood': 12, 'stone': 4, 'fiber': 8, 'herb': 2},
          conditions: [
            const SurvivalCondition(ConditionKind.poisoned, 1, severity: 2),
          ],
          stats: {
            SurvivalStat.health: 2,
            SurvivalStat.water: 55,
            SurvivalStat.food: 63,
            SurvivalStat.sanity: 72,
          },
        ),
      );
      g.profile.xp = 420;
      g.metrics.nights = 7;
      g.metrics.crafted = 9;
      g.metrics.fishCaught = 5;
      g.metrics.fishKept = 3;
      g.metrics.locations.addAll(['riverbank', 'plane_wreck', 'bamboo_grove']);
      g.metrics.fishSpecies.addAll(['small_fish', 'mud_whisker']);
      g.metrics.recipes.addAll([
        'stone_knife',
        'stone_axe',
        'torch',
        'bandage',
        'leaf_bed',
        'water_filter',
      ]);
      g.metrics.encounterTypes.addAll(['jaguar_trail', 'snake_thicket']);
      g.metrics.components.add('battery');
      g.metrics.note(2, 'camp', 'Built the first camp upgrade', 'shelter');
      g.metrics.note(
        3,
        'fishing_pond',
        'Caught a Stream Silverfish',
        'small_fish',
      );
      g.metrics.note(5, 'camp', 'Built Camp Tier 2', 'shelter');
      g.metrics.note(6, 'camp', 'Brought Battery home', 'battery');
      if (!g.travelTo('riverbank', pack: {}, gear: {})) {
        throw StateError('Cannot enter final trip');
      }
      final choice = g.visibleChoices.firstWhere(
        (c) => c.minigame == null && g.canChoose(c),
      );
      if (!g.choose(choice.id) || g.completedRun?.earned != 246) {
        throw StateError('Expected real poison defeat with 246 XP');
      }
      g.continueFromReport();
      final save = jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>;
      final restored = game();
      if (!restored.restore(save) || restored.profile.xp != 666) {
        throw StateError('Profile round trip failed');
      }
      final summary = restored.completedRun!;
      await mount(progression.RunResultScreen(game: restored));
      await shot('01-defeat-summary');
      await mount(progression.XpScreen(game: restored, summary: summary));
      await shot('02-xp-breakdown');
      await mount(
        progression.RankUnlockedScreen(game: restored, summary: summary),
      );
      await shot('03-rank-unlocked');
      await mount(progression.ProfileScreen(game: restored));
      await shot('04-player-profile');
      await mount(progression.ArchiveScreen(game: restored));
      await shot('05-journey-archive');
      await mount(
        progression.JourneyDetailsScreen(game: restored, summary: summary),
      );
      await shot('06-journey-details');
      await mount(progression.StartingOptionsScreen(game: restored));
      await shot('07-starting-options');
      await mount(
        progression.OptionDetailsScreen(
          game: restored,
          option: startingOptions[3],
        ),
      );
      await shot('08-locked-option');
      await mount(
        progression.OptionDetailsScreen(
          game: restored,
          option: startingOptions[1],
        ),
      );
      await shot('09-scavenger-details');
      restored.selectStartingOption('scavenger');
      await mount(progression.StartingOptionsScreen(game: restored));
      await shot('10-selected-option');
      await mount(progression.NewJourneyScreen(game: restored));
      await shot('11-new-journey-review');
      restored.restart();
      await mount(CampScreen(engine: restored));
      await shot('12-new-starting-supplies');
      final rescued = game(
        state: RunState(
          day: 11,
          campTier: 3,
          rescueStage: RescueStage.storm,
          tools: {'machete', 'torch'},
          resources: {'wood': 12, 'fiber': 12, 'metal_scrap': 8},
          stats: {
            SurvivalStat.health: 100,
            SurvivalStat.water: 100,
            SurvivalStat.food: 100,
            SurvivalStat.sanity: 80,
          },
        ),
      );
      rescued.profile.xp = 420;
      rescued.metrics.nights = 10;
      rescued.metrics.crafted = 16;
      rescued.metrics.fishCaught = 12;
      rescued.metrics.locations.addAll(
        world.locations.where((l) => l.id != 'camp').map((l) => l.id),
      );
      rescued.metrics.fishSpecies.addAll([
        'small_fish',
        'redfin_perch',
        'mud_whisker',
        'spiny_sunlurker',
        'goldspot_riverfish',
      ]);
      rescued.metrics.recipes.addAll(recipes.crafts.take(10).map((r) => r.id));
      rescued.metrics.encounterTypes.addAll(
        catalog.events.where((e) => e.trigger == 'encounter').map((e) => e.id),
      );
      rescued.metrics.components.addAll(beaconComponents.keys);
      if (!rescued.restore(
        jsonDecode(jsonEncode(rescued.toJson())) as Map<String, dynamic>,
      )) {
        throw StateError('Cannot reopen storm');
      }
      for (final choice in ['raise', 'cut', 'torch']) {
        if (!rescued.choose(choice)) throw StateError('Storm choice blocked');
        rescued.continueFromReport();
      }
      if (!rescued.state.rescued || rescued.completedRun?.earned != 720) {
        throw StateError(
          'Rescue record failed: ${rescued.completedRun?.earned}',
        );
      }
      await mount(progression.RunResultScreen(game: rescued));
      await shot('13-rescued-summary');
      await mount(progression.ProfileScreen(game: rescued));
      await shot('14-rescued-profile');
      final failure = game();
      failure.abandonJourney();
      failure.saveFailed = true;
      await mount(progression.RunResultScreen(game: failure));
      await tester.ensureVisible(
        find.byKey(const ValueKey('retry-record-save')),
      );
      await tester.pumpAndSettle();
      await shot('15-save-retry');
      final legacy = game();
      final old = legacy.toJson()
        ..remove('metrics')
        ..remove('profile')
        ..remove('completedRun')
        ..['version'] = 2;
      if (!legacy.restore(old)) throw StateError('Legacy migration failed');
      legacy.abandonJourney();
      await mount(progression.RunResultScreen(game: legacy));
      await shot('16-partial-legacy-record');
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (inventoryProgression) {
      const full = {
        'prepared_small_fish': 2,
        'herb': 3,
        'bandage': 1,
        'bait': 4,
        'wood': 10,
        'fiber': 8,
        'stone': 6,
      };
      final g = game(
        state: RunState(
          day: 5,
          campTier: 2,
          tools: {
            'stone_axe',
            'salvage_axe',
            'stone_spear',
            'basic_rod',
            'machete',
            'torch',
            'leaf_rain_cape',
          },
          resources: {
            'wood': 50,
            'stone': 50,
            'fiber': 50,
            'hardwood': 10,
            'metal_scrap': 10,
            'prepared_small_fish': 6,
            'herb': 8,
            'bandage': 3,
            'bait': 12,
          },
        ),
      );
      await mount(Scaffold(body: InventoryDialog(game: g)));
      await shot('01-camp-storage');
      if (!g.beginPacking('plane_wreck')) throw StateError('Cannot pack');
      g.updatePacking(full, g.suggestedGear);
      await mount(PackingScreen(game: g));
      await tap('packing-tab-1');
      await shot('02-packed-supplies');
      await tap('packing-item-stone');
      await shot('03-quantity');
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      await tap('packing-tab-2');
      await shot('04-equipped-gear');
      await tester.tap(find.textContaining('AXE:').last);
      await tester.pumpAndSettle();
      await shot('05-choose-axe');
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      g.updatePacking({'stone': 50}, g.suggestedGear);
      await mount(PackingScreen(game: g));
      await shot('06-over-capacity-departure');
      g.updatePacking(full, g.suggestedGear);
      if (!g.leaveCamp()) throw StateError('Cannot depart');
      await mount(Scaffold(body: InventoryDialog(game: g)));
      await shot('07-field-backpack');
      if (g.pendingEvent?.id != 'wreck_battery') {
        throw StateError(
          'Expected real wreck battery event: ${g.pendingEvent?.id}',
        );
      }
      await mount(EventScene(game: g));
      await shot('08-wreck-discovery');
      if (!g.choose('recover') || !g.hasPendingHaul) {
        throw StateError('Expected overflow from real battery salvage');
      }
      await mount(HaulResolutionScreen(game: g));
      await shot('09-full-backpack');
      await tester.ensureVisible(
        find.byKey(const ValueKey('haul-item-battery')),
      );
      await tester.pumpAndSettle();
      await shot('09b-new-battery');
      final keep = {...g.haulCandidate, 'stone': 5, 'metal_scrap': 0};
      g.updateHaulSelection(keep);
      await mount(HaulResolutionScreen(game: g));
      await tester.ensureVisible(
        find.byKey(const ValueKey('haul-item-battery')),
      );
      await tester.pumpAndSettle();
      await shot('10-final-selection');
      await tap('confirm-haul');
      await shot('11-confirm-left-items');
      await tap('confirm-discard');
      await mount(
        Scaffold(
          body: OutcomeDialog(
            report: g.report!,
            nightNext: false,
            state: g.state,
          ),
        ),
      );
      await shot('12-retained-result');
      g.continueFromReport();
      if (!g.returnHome()) throw StateError('Cannot return home');
      await mount(
        Scaffold(
          body: OutcomeDialog(
            report: g.report!,
            nightNext: false,
            state: g.state,
          ),
        ),
      );
      await shot('13-return-and-unload');
      g.continueFromReport();
      await mount(Scaffold(body: InventoryDialog(game: g)));
      await shot('14-stored-after-return');
      await mount(CraftScreen(game: g));
      await tap('recipe-trail_backpack');
      await shot('15-backpack-upgrade');
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (toolProgression) {
      RunState toolState({
        Set<String>? tools,
        Map<String, int> durability = const {},
        List<SurvivalCondition> conditions = const [],
      }) => RunState(
        day: 5,
        campTier: 2,
        tools: tools ?? fieldTools.keys.toSet(),
        durability: durability,
        conditions: conditions,
        equippedAxe: 'reinforced_axe',
        equippedSpear: 'hunting_spear',
        resources: {
          'wood': 12,
          'stone': 4,
          'fiber': 12,
          'hardwood': 4,
          'metal_scrap': 4,
          'raw_meat': 1,
        },
        stats: {
          SurvivalStat.health: 88,
          SurvivalStat.water: 62,
          SurvivalStat.food: 57,
          SurvivalStat.sanity: 76,
        },
      );
      final craft = game(state: toolState(tools: {'stone_axe', 'stone_spear'}));
      await mount(CraftScreen(game: craft));
      await tap('tools-filter-AXES');
      await shot('01-workshop-axes');
      await tap('recipe-reinforced_axe');
      await shot('02-axe-details');
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      await tap('tools-filter-SPEARS');
      await shot('03-workshop-spears');
      final gear = game(
        state: toolState(durability: {'salvage_spear': 3, 'hunting_spear': 12}),
      );
      await mount(Scaffold(body: InventoryDialog(game: gear)));
      await tester.tap(find.text('GEAR'));
      await tester.pumpAndSettle();
      await shot('04-items-gear');
      await mount(
        Scaffold(
          body: ToolRepairDialog(game: gear, id: 'salvage_spear'),
        ),
      );
      await shot('05-repair-confirmation');
      if (!gear.craft('salvage_spear')) throw StateError('Repair was blocked');
      await mount(
        Scaffold(
          body: OutcomeDialog(
            report: gear.report!,
            nightNext: false,
            state: gear.state,
          ),
        ),
      );
      await shot('06-repaired-outcome');
      final chop = game(state: toolState(durability: {'reinforced_axe': 14}));
      chop.openGathering(GatheringKind.chopping);
      await mount(GatheringScreen(game: chop));
      await shot('07-chopping-loadout');
      await tester.tap(find.text('CHANGE'));
      await tester.pumpAndSettle();
      await shot('08-axe-selection');
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      // Drive the actual session, not the live ticker, to export its committed result.
      await tester.pumpWidget(const SizedBox.shrink());
      if (!chop.beginGathering()) throw StateError('Chopping was blocked');
      for (var i = 0; i < 3; i++) {
        chop.tickGathering(i == 0 ? .4 : .8);
        chop.strikeGathering();
      }
      if (!chop.finishGathering()) throw StateError('Chopping did not finish');
      await mount(
        Scaffold(
          body: OutcomeDialog(
            report: chop.report!,
            nightNext: false,
            state: chop.state,
          ),
        ),
      );
      await shot('09-chopping-outcome');
      final fight = game(
        state: toolState(
          conditions: [const SurvivalCondition(ConditionKind.injured, 3)],
        ),
      );
      final save = fight.toJson()
        ..['state'] = fight.state.copyWith(locationId: 'riverbank').toJson()
        ..['pendingEvent'] = 'jaguar_trail'
        ..['pendingCost'] = 0;
      if (!fight.restore(save)) throw StateError('Encounter fixture invalid');
      await mount(EventScene(game: fight));
      await shot('10-jaguar-choices');
      final spear = find.byKey(const ValueKey('choice-spear'));
      await tester.ensureVisible(spear);
      await tester.tap(spear);
      await tester.pumpAndSettle();
      await shot('11-spear-decision');
      await tester.pumpWidget(const SizedBox.shrink());
      final boar = game(state: toolState());
      final boarSave = boar.toJson()
        ..['state'] = boar.state.copyWith(locationId: 'riverbank').toJson()
        ..['pendingEvent'] = 'boar_charge'
        ..['pendingCost'] = 0;
      if (!boar.restore(boarSave)) throw StateError('Boar fixture invalid');
      await mount(EventScene(game: boar));
      await tester.ensureVisible(
        find.byKey(const ValueKey('choice-brace_spear')),
      );
      await tester.pumpAndSettle();
      await shot('12-boar-spear-choice');
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (Platform.environment['LOST_CANOPY_CAPTURE_FISHING_PROGRESSION'] ==
        '1') {
      RunState fishingState({String rod = 'river_rod'}) => RunState(
        day: 5,
        campTier: 2,
        equippedRod: rod,
        knownFish: {'small_fish', 'redfin_perch', 'spiny_sunlurker'},
        tools: {'basic_rod', 'reinforced_rod', 'river_rod', 'stone_knife'},
        resources: {
          'wood': 14,
          'stone': 4,
          'fiber': 12,
          'bait': 4,
          'insect_bait': 2,
          'fruit_bait': 3,
          'antidote': 1,
          'spiny_sunlurker': 1,
        },
        stats: {
          SurvivalStat.health: 88,
          SurvivalStat.water: 72,
          SurvivalStat.food: 57,
          SurvivalStat.sanity: 76,
        },
      );
      GameEngine fishingGame({int seed = 42, String rod = 'river_rod'}) =>
          GameEngine(
            catalog,
            world: world,
            recipes: recipes,
            random: Random(seed),
            initialState: fishingState(rod: rod),
          );
      GameEngine catchGame(String species) {
        for (var seed = 0; seed < 1000; seed++) {
          final g = fishingGame(seed: seed);
          g.travelTo('fishing_pond');
          g.selectFishingBait('fruit_bait');
          g.castLine();
          if (g.fishing!.catchRecord!.speciesId != species) continue;
          waitForBite(g.fishing!);
          g.fishing!.hook();
          reelByTracking(g.fishing!);
          if (g.fishing!.stage != FishingStage.caught) continue;
          g.saveFishingProgress();
          return g;
        }
        throw StateError('No seeded catch for $species');
      }

      final ready = fishingGame();
      ready.travelTo('fishing_pond');
      await mount(CampScreen(engine: ready));
      await shot('01-loadout');
      await tap('fishing-bait-insect_bait');
      await shot('02-insect-bait-details');
      await mount(CampScreen(engine: fishingGame()..travelTo('fishing_pond')));
      await tester.tap(find.text('CHANGE'));
      await tester.pumpAndSettle();
      await shot('03-rod-selection');
      final reeling = fishingGame();
      reeling.travelTo('fishing_pond');
      reeling.castLine();
      waitForBite(reeling.fishing!);
      reeling.fishing!.hook();
      reeling.fishing!.update(.5);
      await mount(FishingScreen(game: reeling), settle: false);
      await shot('04-reeling');
      for (final item in [
        ('small_fish', '05-stream-silverfish'),
        ('goldspot_riverfish', '06-first-rare-catch'),
        ('spiny_sunlurker', '07-dangerous-catch'),
      ]) {
        await mount(CampScreen(engine: catchGame(item.$1)));
        await shot(item.$2);
      }
      final food = fishingGame();
      await mount(CampScreen(engine: food));
      await tap('open-inventory');
      await tap('inventory-tab-1');
      await tap('inventory-spiny_sunlurker');
      await shot('08-fish-item-details');
      await tester.tap(find.text('PREPARE SAFELY · 1 WOOD · 1 TIME'));
      await tester.pumpAndSettle();
      await shot('09-prepare-confirmation');
      await tap('confirm-prepare-fish');
      await shot('10-prepared-outcome');
      final unsafe = fishingGame();
      await mount(CampScreen(engine: unsafe));
      await tap('open-inventory');
      await tap('inventory-tab-1');
      await tap('inventory-spiny_sunlurker');
      await tap('consume-spiny_sunlurker');
      await shot('11-unsafe-confirmation');
      await tap('confirm-unsafe-fish');
      await shot('12-poison-outcome');
      await mount(Scaffold(body: FishJournalDialog(game: unsafe)));
      await shot('13-fish-journal');
      final paused = fishingGame();
      paused.travelTo('fishing_pond');
      paused.castLine();
      paused.pauseFishing(true);
      await mount(CampScreen(engine: paused));
      await shot('14-paused-cast');
      final craft = fishingGame();
      await mount(CraftScreen(game: craft));
      await tester.ensureVisible(
        find.byKey(const ValueKey('recipe-river_rod')),
      );
      await tester.pumpAndSettle();
      await shot('15-new-gear-recipes');
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (Platform.environment['LOST_CANOPY_CAPTURE_ECOLOGY'] == '1') {
      final state = RunState(
        day: 5,
        campTier: 1,
        weather: 'Light rain',
        conditions: [
          const SurvivalCondition(ConditionKind.poisoned, 4),
          const SurvivalCondition(ConditionKind.injured, 6),
          const SurvivalCondition(ConditionKind.wet, 3),
          const SurvivalCondition(ConditionKind.exhausted, 4),
        ],
        tools: {'stone_knife', 'stone_axe', 'stone_spear'},
        resources: {
          'wood': 14,
          'stone': 4,
          'fiber': 12,
          'herb': 3,
          'charcoal': 2,
          'antidote': 1,
          'bandage': 2,
          'ember_berries': 3,
          'dew_fruit': 2,
          'ribbon_root': 3,
          'mooncap': 1,
        },
        stats: {
          SurvivalStat.health: 72,
          SurvivalStat.water: 56,
          SurvivalStat.food: 61,
          SurvivalStat.sanity: 68,
        },
      );
      await mount(CampScreen(engine: game(state: state)));
      await shot('01-camp-conditions');
      await tester.tap(find.byKey(const ValueKey('condition-poisoned')));
      await tester.pumpAndSettle();
      await shot('02-poison-details');
      await mount(CampScreen(engine: game(state: state)));
      await tap('open-inventory');
      await tap('inventory-tab-1');
      await shot('03-food-and-treatment-items');
      await tap('inventory-dew_fruit');
      await shot('04-species-details');
      await mount(CraftScreen(game: game(state: state)));
      await shot('05-survival-workshop');
      await tester.ensureVisible(find.byKey(const ValueKey('recipe-antidote')));
      await tester.pumpAndSettle();
      await shot('05b-survival-recipes');
      await tap('recipe-antidote');
      await shot('05c-antidote-recipe-details');
      final encounter = game(state: state);
      final save = encounter.toJson()
        ..['pendingEvent'] = 'ecology_frog'
        ..['pendingCost'] = 0;
      encounter.restore(save);
      await mount(EventScene(game: encounter));
      await shot('06-frog-encounter');
      final treated = game(state: state);
      treated.consume('antidote');
      await mount(
        Scaffold(
          body: OutcomeDialog(
            report: treated.report!,
            state: treated.state,
            nightNext: false,
          ),
        ),
      );
      await shot('07-antidote-outcome');
      final forage = game(state: state);
      forage.openGathering(GatheringKind.foraging);
      await mount(GatheringScreen(game: forage), settle: false);
      await shot('08-foraging-ready');
      final night = game(
        state: state.copyWith(phase: RunPhase.night, timeLeft: 0),
      );
      final nightSave = night.toJson()
        ..['nightResolved'] = true
        ..['dayHighlights'] = [
          'Explored Riverbank',
          'Crafted: Antidote',
          'Gathered from the grove',
        ];
      night.restore(nightSave);
      night.sleep();
      await mount(
        DayEndScreen(game: night, summary: night.report!.daySummary!),
      );
      await shot('09-day-end-conditions');
      await mount(CampScreen(engine: game(state: state)));
      await tap('camp-menu');
      await tap('menu-journal');
      await shot('10-jungle-knowledge');
      await mount(CampScreen(engine: game(state: state)));
      await tap('open-inventory');
      await tester.tap(find.text('DRY BY FIRE · 1 WOOD · 1 TIME'));
      await tester.pumpAndSettle();
      await shot('11-dry-by-fire-confirmation');
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (itemsRefresh) {
      for (final size in [const Size(390, 844), const Size(430, 932)]) {
        await binding.setSurfaceSize(size);
        tester.view.physicalSize = size;
        await mount(
          CampScreen(
            engine: game(
              state: RunState(
                resources: {'wood': 3, 'stone': 3, 'fiber': 6, 'bait': 2},
              ),
            ),
          ),
        );
        await tap('open-inventory');
        await shot(
          'items-materials-${size.width.toInt()}x${size.height.toInt()}',
        );
        await tap('close-dialog');
        await tap('camp-menu');
        await shot('menu-${size.width.toInt()}x${size.height.toInt()}');
      }
      await binding.setSurfaceSize(const Size(320, 568));
      tester.view.physicalSize = const Size(320, 568);
      await mount(CampScreen(engine: game()));
      await tap('open-inventory');
      await shot('items-materials-320x568');
      await tester.drag(
        find.byKey(const ValueKey('dialog-content-scroll')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await shot('items-scrolled-320x568');
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (allCampLayers) {
      for (final size in [const Size(390, 844), const Size(430, 932)]) {
        await binding.setSurfaceSize(size);
        tester.view.physicalSize = size;
        for (var tier = 0; tier <= 3; tier++) {
          for (var variant = 0; variant < campActivities.length; variant++) {
            await mount(
              CampScreen(
                engine: game(state: RunState(campTier: tier)),
                initialCampVariant: variant,
              ),
            );
            final number = (files.length + 1).toString().padLeft(2, '0');
            await shot(
              '$number-tier-$tier-${campActivities[variant]}-${size.width.toInt()}x${size.height.toInt()}',
            );
          }
          await mount(
            CampScreen(
              engine: game(
                state: RunState(
                  campTier: tier,
                  phase: RunPhase.night,
                  timeLeft: 0,
                ),
              ),
              initialCampVariant: 0,
            ),
          );
          final number = (files.length + 1).toString().padLeft(2, '0');
          await shot(
            '$number-tier-$tier-night-${size.width.toInt()}x${size.height.toInt()}',
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (campLayers) {
      for (final size in [const Size(390, 844), const Size(430, 932)]) {
        await binding.setSurfaceSize(size);
        tester.view.physicalSize = size;
        for (var variant = 0; variant < 3; variant++) {
          await mount(
            CampScreen(
              engine: game(state: RunState()),
              initialCampVariant: variant,
            ),
          );
          final number = (files.length + 1).toString().padLeft(2, '0');
          await shot(
            '$number-tier-0-${starterCampActivities[variant]}-${size.width.toInt()}x${size.height.toInt()}',
          );
        }
      }
      await binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(390, 844);
      await mount(
        CampScreen(
          engine: game(state: RunState(phase: RunPhase.night, timeLeft: 0)),
          initialCampVariant: 0,
        ),
      );
      await shot('07-tier-0-night');
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (sceneWidth) {
      for (final tier in [0, 2]) {
        final camp = game(state: RunState(campTier: tier));
        await mount(CampScreen(engine: camp));
        await shot('0${tier == 0 ? 1 : 2}-camp-tier-$tier-390x844');
      }
      await binding.setSurfaceSize(const Size(430, 932));
      tester.view.physicalSize = const Size(430, 932);
      await mount(CampScreen(engine: game(state: RunState(campTier: 3))));
      await shot('03-camp-tier-3-430x932');
      await binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(390, 844);
      final river = game()..travelTo('riverbank');
      await mount(EventScene(game: river));
      await shot('04-riverbank-390x844');
      final pond = game()..travelTo('fishing_pond');
      await mount(FishingScreen(game: pond));
      await shot('05-fishing-390x844');
      final hunt = game(
        state: RunState(
          tools: {'stone_spear'},
          resources: {'wood': 20, 'fiber': 20},
        ),
      );
      hunt.openGathering(GatheringKind.hunting);
      await mount(GatheringScreen(game: hunt));
      await tester.tap(find.byKey(const ValueKey('gathering-start')));
      await tester.pump();
      await shot('06-hunting-390x844');
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (Platform.environment['LOST_CANOPY_CAPTURE_DAY_END'] == '1') {
      final engine = game();
      if (!engine.craft('stone_axe')) {
        throw StateError('Could not craft demo axe');
      }
      engine.continueFromReport();
      if (!engine.travelTo('riverbank')) {
        throw StateError('Could not reach river');
      }
      engine.choose(
        engine.pendingEvent!.choices
            .firstWhere((c) => engine.canChoose(c) && c.minigame == null)
            .id,
      );
      engine.continueFromReport();
      if (engine.awaitingExpeditionDecision) {
        engine.returnHome();
        engine.continueFromReport();
      }
      while (engine.canAct(CampAction.rest)) {
        engine.startAction(CampAction.rest);
        engine.continueFromReport();
      }
      if (engine.pendingEvent != null) {
        engine.choose(
          engine.pendingEvent!.choices.firstWhere(engine.canChoose).id,
        );
        engine.continueFromReport();
      }
      if (!engine.sleep() || engine.report?.daySummary == null) {
        throw StateError('The demo day did not reach a saved summary');
      }
      final snapshot = engine.toJson();
      await mount(LostCanopyApp(engine: engine), app: true);
      await shot('01-day-3-survived-390x844');
      await tap('continue-outcome');
      await shot('02-next-day-4-camp');
      final restored = game();
      if (!restored.restore(snapshot)) {
        throw StateError('Day end restore failed');
      }
      await binding.setSurfaceSize(const Size(320, 568));
      tester.view.physicalSize = const Size(320, 568);
      await mount(LostCanopyApp(engine: restored), app: true);
      await shot('03-restored-day-end-320x568');
      await tester.ensureVisible(
        find.byKey(const ValueKey('continue-outcome')),
      );
      await shot('04-restored-day-end-scrolled-320x568');
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (Platform.environment['LOST_CANOPY_CAPTURE_GUIDE'] == '1') {
      final engine = game();
      final before = engine.state.toJson().toString();
      await mount(LostCanopyApp(engine: engine), app: true);
      await tap('camp-menu');
      await tap('menu-guide');
      await shot('01-guide');
      var n = 2;
      for (final kind in [
        'chopping',
        'plants',
        'hunting',
        'ruins',
        'fishing',
      ]) {
        await tap('guide-$kind');
        await shot('${n.toString().padLeft(2, '0')}-$kind-tutorial');
        await tap('close-dialog');
        n++;
      }
      if (engine.state.toJson().toString() != before) {
        throw StateError('Tutorial browsing spent resources');
      }
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (fishingTutorial) {
      final pond = game()..travelTo('fishing_pond');
      await mount(FishingScreen(game: pond));
      await shot('01-ready-instructions');
      await tap('fishing-practice');
      await shot('02-how-to-fish');
      await tap('practice-cast');
      for (
        var i = 0;
        i < 100 &&
            find.byKey(const ValueKey('practice-hook')).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await shot('03-practice-bite');
      await tester.tap(find.byKey(const ValueKey('practice-hook')));
      await tester.pump();
      await shot('04-practice-reeling');
      await tap('close-dialog');
      await tester.tap(find.byKey(const ValueKey('cast-line')));
      await tester.pump();
      for (
        var i = 0;
        i < 100 && pond.fishing!.stage == FishingStage.waiting;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await shot('05-real-bite');
      await tester.tap(find.byKey(const ValueKey('hook-fish')));
      await tester.pump();
      await shot('06-real-reeling');
      TestGesture? finger;
      for (var i = 0; i < 220 && !pond.fishing!.complete; i++) {
        final session = pond.fishing!;
        if (session.cursor < session.target && finger == null) {
          finger = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('reel-control'))),
          );
        } else if (session.cursor >= session.target && finger != null) {
          await finger.up();
          finger = null;
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
      await finger?.up();
      await tester.pump();
      if (pond.fishing!.stage != FishingStage.caught) {
        throw StateError('Capture touch fishing failed');
      }
      await shot('07-caught-with-touch');
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (minigames) {
      GameEngine attempt(
        GatheringKind kind, {
        bool active = false,
        RunState? state,
      }) {
        final engine = game(
          state:
              state ??
              RunState(
                day: 4,
                campTier: 1,
                tools: {'stone_axe', 'stone_spear', 'stone_knife', 'machete'},
                resources: {'wood': 20, 'stone': 8, 'fiber': 20},
                stats: {
                  SurvivalStat.health: 100,
                  SurvivalStat.water: 72,
                  SurvivalStat.food: 69,
                  SurvivalStat.sanity: 80,
                },
              ),
        );
        engine.openGathering(kind);
        if (active) engine.beginGathering();
        return engine;
      }

      Future<void> capture(
        String name,
        GameEngine engine, {
        bool settle = false,
      }) async {
        if (engine.gathering != null) {
          await mount(GatheringScreen(game: engine), settle: settle);
        } else {
          await mount(LostCanopyApp(engine: engine), app: true, settle: settle);
        }
        await shot(name);
      }

      final camp = game();
      await mount(LostCanopyApp(engine: camp), app: true);
      await tap('camp-menu');
      await tap('menu-gather');
      await shot('01-camp-gather-menu');
      for (final kind in GatheringKind.values) {
        final prefix = kind.name;
        final start = kind == GatheringKind.chopping
            ? 2
            : kind == GatheringKind.foraging
            ? 6
            : 12;
        String name(int offset, String suffix) =>
            '${(start + offset).toString().padLeft(2, '0')}-$prefix-$suffix';
        await capture(name(0, 'ready'), attempt(kind), settle: true);
        final playing = attempt(kind, active: true);
        playing.tickGathering(kind == GatheringKind.hunting ? .45 : .4);
        await capture(name(1, 'active'), playing);
        if (kind == GatheringKind.foraging) {
          playing.pickGatheringPlant('berries');
          playing.pickGatheringPlant('fiber');
          await tester.pump();
          await shot(name(2, 'selected'));
          final scroll = find.byKey(const ValueKey('plants-next'));
          await tester.tap(scroll);
          await tester.pump(const Duration(milliseconds: 250));
          await shot(name(3, 'more-plants'));
          final paused = attempt(kind, active: true);
          paused.pickGatheringPlant('fiber');
          paused.pauseGathering(true);
          await capture(name(4, 'paused'), paused, settle: true);
        } else {
          final hit = attempt(kind);
          await mount(GatheringScreen(game: hit));
          await tester.tap(find.byKey(const ValueKey('gathering-start')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          final period = kind == GatheringKind.hunting ? 1.8 : 1.6;
          hit.tickGathering(
            (period * .25 - hit.gathering!.elapsed) % (period * .5),
          );
          await tester.tap(find.byKey(const ValueKey('gathering-strike')));
          await tester.pump();
          await shot(name(2, 'perfect'));
        }
        final result = attempt(kind, active: true);
        if (kind == GatheringKind.foraging) {
          for (final plant in ['berries', 'fiber', 'herb']) {
            result.pickGatheringPlant(plant);
          }
        } else {
          for (var i = 0; i < (kind == GatheringKind.chopping ? 3 : 1); i++) {
            result.tickGathering(
              i == 0 ? (kind == GatheringKind.hunting ? .45 : .4) : .8,
            );
            result.strikeGathering();
          }
        }
        result.finishGathering();
        await capture(
          name(kind == GatheringKind.foraging ? 5 : 3, 'outcome'),
          result,
          settle: true,
        );
      }
      await capture(
        '16-chopping-tool-required',
        attempt(GatheringKind.chopping, state: RunState(day: 4)),
        settle: true,
      );
      final repair = game(
        state: RunState(
          day: 4,
          tools: {'stone_axe'},
          durability: {'stone_axe': 0},
          resources: {'wood': 20, 'stone': 8, 'fiber': 20},
        ),
      );
      await mount(CraftScreen(game: repair));
      await tap('recipe-stone_axe');
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      await shot('17-workshop-repair-axe');
      for (final kind in GatheringKind.values) {
        await binding.setSurfaceSize(const Size(844, 390));
        tester.view.physicalSize = const Size(844, 390);
        await capture('18-${kind.name}-landscape', attempt(kind, active: true));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (campVariants || starterVariants) {
      for (
        var tier = starterVariants ? 0 : 1;
        tier <= (starterVariants ? 0 : 3);
        tier++
      ) {
        final activities = tier == 0 ? starterCampActivities : campActivities;
        for (var variant = 0; variant < campActivities.length; variant++) {
          final engine = game(
            state: starterVariants
                ? RunState()
                : RunState(
                    day: 3 + tier,
                    campTier: tier,
                    tools: {'stone_knife', 'basic_rod'},
                    resources: {'wood': 11, 'stone': 4, 'fiber': 8},
                  ),
          );
          await mount(CampScreen(engine: engine, initialCampVariant: variant));
          final number = (files.length + 1).toString().padLeft(2, '0');
          await shot('$number-tier-$tier-${activities[variant]}');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      return;
    }

    if (rescue) {
      final survivor = game(
        state: RunState(
          day: 8,
          campTier: 3,
          tools: {'machete', 'torch', 'stone_knife', 'stone_axe'},
          resources: {'wood': 24, 'fiber': 24, 'metal_scrap': 8, 'herb': 4},
          stats: {for (final stat in SurvivalStat.values) stat: 100},
        ),
      );
      await mount(LostCanopyApp(engine: survivor), app: true);
      await tap('camp-objective');
      await shot('01-beacon-missing-components');
      await tap('beacon-back');
      final workshop = game(
        state: survivor.state.copyWith(
          tools: {'torch', 'stone_knife', 'stone_axe'},
        ),
      );
      await mount(CraftScreen(game: workshop));
      await tap('recipe-machete');
      await shot('02-machete-workshop');
      await mount(ExploreMapScreen(game: survivor));
      await tap('map-node-ancient_ruins');
      await tester.pumpAndSettle();
      await shot('03-ancient-ruins-map');
      survivor.travelTo('plane_wreck');
      await mount(LostCanopyApp(engine: survivor), app: true);
      const parts = ['battery', 'wire', 'metal_parts', 'radio_module'];
      for (var i = 0; i < parts.length; i++) {
        final number = 4 + i * 2;
        await shot('${number.toString().padLeft(2, '0')}-wreck-${parts[i]}');
        await tap('choice-recover');
        await shot(
          '${(number + 1).toString().padLeft(2, '0')}-${parts[i]}-outcome',
        );
        await tap('continue-outcome');
        if (i < parts.length - 1) await tap('expedition-deeper');
      }
      Future<void> sleepAndContinue() async {
        await tap(
          'choice-${survivor.visibleChoices.firstWhere(survivor.canChoose).id}',
        );
        await tap('continue-outcome');
        await tap('action-rest');
        await tap('continue-outcome');
      }

      await sleepAndContinue();
      survivor.travelTo('ancient_ruins');
      await mount(LostCanopyApp(engine: survivor), app: true);
      await shot('12-ruins-sealed-altar');
      await tap('choice-align');
      await shot('13-ruins-stone-puzzle');
      final puzzle = survivor.ruinsPuzzle!;
      for (var i = 0; i < 3; i++) {
        while (puzzle.tiles[i] != puzzle.pattern[i]) {
          await tap('ruins-disc-$i');
        }
      }
      await shot('14-ruins-aligned-discs');
      await tap('ruins-submit');
      await shot('15-beacon-core-outcome');
      await tap('continue-outcome');
      await shot('16-core-in-expedition-pack');
      await tap('expedition-return');
      await shot('17-core-returned-to-camp');
      await tap('continue-outcome');
      await tap('camp-objective');
      await shot('18-beacon-complete-components');
      await tap('beacon-primary');
      await shot('19-beacon-crafted-outcome');
      await tap('continue-outcome');
      await sleepAndContinue();
      await tap('camp-objective');
      await shot('20-beacon-ready-to-send');
      await tap('beacon-primary');
      await shot('21-signal-received-outcome');
      await tap('continue-outcome');
      await shot('22-camp-preparing-for-rescue');
      // Decisions advance the same engine. Refill supplies before the storm.
      while (survivor.state.phase == RunPhase.day &&
          survivor.state.timeLeft > 0) {
        await tap('action-forage');
        final best = survivor.visibleChoices.where(survivor.canChoose).toList()
          ..sort((a, b) {
            num score(choice) =>
                (choice.isRisky ? -100 : 0) +
                (choice.effect.stats[SurvivalStat.water] ?? 0) *
                    (survivor.state.value(SurvivalStat.water) < 65 ? 2 : 1) +
                (choice.effect.stats[SurvivalStat.food] ?? 0) *
                    (survivor.state.value(SurvivalStat.food) < 65 ? 2 : 1);
            return score(b).compareTo(score(a));
          });
        await tap('choice-${best.first.id}');
        await tap('continue-outcome');
      }
      await tap(
        'choice-${survivor.visibleChoices.firstWhere(survivor.canChoose).id}',
      );
      await tap('continue-outcome');
      await tap('action-rest');
      await shot('23-rescue-storm-dawn-outcome');
      await tap('continue-outcome');
      const choices = ['raise', 'cut', 'torch'];
      const storms = ['rising-water', 'falling-branches', 'last-signal'];
      for (var i = 0; i < choices.length; i++) {
        final number = 24 + i * 2;
        await shot('${number.toString().padLeft(2, '0')}-storm-${storms[i]}');
        await tap('choice-${choices[i]}');
        await shot(
          '${(number + 1).toString().padLeft(2, '0')}-storm-${storms[i]}-outcome',
        );
        await tap('continue-outcome');
      }
      if (!survivor.state.rescued) {
        throw StateError('Capture did not reach rescue');
      }
      await shot('30-rescued-run-summary');
      await tap('rescue-new-run');
      await shot('31-new-run-confirmation');
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.data?.toLowerCase() == 'keep summary',
        ),
      );
      await tester.pumpAndSettle();
      final restored = game();
      if (!restored.restore(survivor.toJson())) {
        throw StateError('Rescue restore failed');
      }
      await mount(LostCanopyApp(engine: restored), app: true);
      await shot('32-restored-rescued-summary');
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (encounterStyle || styleRefresh) {
      const encounters = [
        'jaguar_trail',
        'snake_thicket',
        'boar_charge',
        'crocodile_shallows',
        'hornet_nest',
        'monkey_raiders',
      ];
      final stockedState = game().state.copyWith(
        campTier: 1,
        tools: {
          'basic_rod',
          'stone_knife',
          'stone_axe',
          'stone_spear',
          'torch',
        },
        stats: {for (final stat in SurvivalStat.values) stat: 80},
      );
      for (var i = 0; i < encounters.length; i++) {
        final id = encounters[i];
        final event = catalog.events.firstWhere((event) => event.id == id);
        final explorer = GameEngine(
          EventCatalog(
            catalog.events
                .where(
                  (event) => event.trigger != 'encounter' || event.id == id,
                )
                .toList(),
          ),
          world: world,
          recipes: recipes,
          initialState: stockedState,
          random: _Roll(0),
        );
        explorer.travelTo(event.locations.first);
        explorer.choose(
          explorer.visibleChoices
              .firstWhere(
                (choice) =>
                    explorer.canChoose(choice) && !choice.effect.endsExpedition,
              )
              .id,
        );
        explorer.continueFromReport();
        explorer.goDeeper();
        if (explorer.pendingEvent?.id != id) {
          throw StateError('Expected encounter $id');
        }
        await mount(LostCanopyApp(engine: explorer), app: true);
        await shot('${(i + 1).toString().padLeft(2, '0')}-$id');
      }
      if (styleRefresh) {
        final prepared = stockedState.copyWith(
          day: 8,
          campTier: 3,
          tools: {...stockedState.tools, 'machete'},
        );
        for (final route in [
          'ancient_ruins',
          'bamboo_grove',
          'plane_wreck',
          'riverbank',
        ]) {
          final explorer = game(state: prepared)..travelTo(route);
          await mount(LostCanopyApp(engine: explorer), app: true);
          final number = (files.length + 1).toString().padLeft(2, '0');
          await shot('$number-$route');
          if (route == 'ancient_ruins') {
            await tap('choice-align');
            await shot('08-ruins-puzzle');
          }
          if (route == 'bamboo_grove') {
            await tap(
              'choice-${explorer.visibleChoices.firstWhere(explorer.canChoose).id}',
            );
            await tap('continue-outcome');
            await shot('10-bamboo-expedition');
          }
        }
        await mount(CraftScreen(game: game(state: prepared)));
        await shot('13-workshop');
        final storm = game(
          state: prepared.copyWith(
            weather: 'Storm',
            tools: {...prepared.tools, 'emergency_beacon'},
            rescueStage: RescueStage.storm,
            signalDay: 7,
            foundComponents: beaconComponents.keys.toSet(),
          ),
        );
        await mount(CampScreen(engine: storm));
        await shot('14-storm-camp');
        if (!storm.restore(storm.toJson())) {
          throw StateError('Could not restore the storm capture');
        }
        await mount(LostCanopyApp(engine: storm), app: true);
        await shot('15-storm-event');
        final rescued = game(
          state: prepared.copyWith(
            phase: RunPhase.rescued,
            tools: {...prepared.tools, 'emergency_beacon'},
            rescueStage: RescueStage.storm,
            rescueStep: 3,
            signalDay: 7,
            foundComponents: beaconComponents.keys.toSet(),
          ),
        );
        await mount(LostCanopyApp(engine: rescued), app: true);
        await shot('16-rescue-arrival');
        final angler = game(state: prepared)..travelTo('fishing_pond');
        await mount(FishingScreen(game: angler), settle: false);
        await shot('17-fishing-unchanged');
      }
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (expansion) {
      final stockedState = game().state.copyWith(
        campTier: 1,
        tools: {
          'basic_rod',
          'stone_knife',
          'stone_axe',
          'stone_spear',
          'torch',
        },
      );
      for (final route in ['bamboo_grove', 'mangrove_shallows']) {
        final explorer = game(state: stockedState)..travelTo(route);
        await mount(LostCanopyApp(engine: explorer), app: true);
        await shot(
          route == 'bamboo_grove' ? '01-bamboo-event' : '03-mangrove-event',
        );
        await tap(
          'choice-${explorer.visibleChoices.firstWhere(explorer.canChoose).id}',
        );
        await tap('continue-outcome');
        await shot(
          route == 'bamboo_grove'
              ? '02-bamboo-expedition'
              : '04-mangrove-expedition',
        );
      }
      const encounters = [
        'crocodile_shallows',
        'hornet_nest',
        'monkey_raiders',
      ];
      for (var i = 0; i < encounters.length; i++) {
        final id = encounters[i];
        final event = catalog.events.firstWhere((event) => event.id == id);
        final explorer = GameEngine(
          EventCatalog(
            catalog.events
                .where(
                  (event) => event.trigger != 'encounter' || event.id == id,
                )
                .toList(),
          ),
          world: world,
          recipes: recipes,
          initialState: stockedState,
          random: _Roll(0),
        );
        explorer.travelTo(event.locations.first);
        explorer.choose(
          explorer.visibleChoices
              .firstWhere(
                (choice) =>
                    explorer.canChoose(choice) && !choice.effect.endsExpedition,
              )
              .id,
        );
        explorer.continueFromReport();
        explorer.goDeeper();
        if (explorer.pendingEvent?.id != id) {
          throw StateError('Expected encounter $id');
        }
        await mount(LostCanopyApp(engine: explorer), app: true);
        await shot('${(5 + i * 2).toString().padLeft(2, '0')}-$id-choices');
        await tap(
          'choice-${explorer.visibleChoices.firstWhere(explorer.canChoose).id}',
        );
        await shot('${(6 + i * 2).toString().padLeft(2, '0')}-$id-result');
      }
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (cardSet) {
      for (
        var start = 0;
        start < cardIllustrationSubjects.length;
        start += 12
      ) {
        final subjects = cardIllustrationSubjects.skip(start).take(12).toList();
        final cards = <Widget>[
          for (final subject in subjects)
            ActionCard(
              title: subject.replaceAll('_', ' '),
              art: subject,
              compact: true,
              fixedHeight: 152,
              titleMaxLines: 2,
              showStatus: false,
              onTap: () {},
            ),
        ];
        while (cards.length % 3 != 0) {
          cards.add(const SizedBox.shrink());
        }
        await mount(
          Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      'Kártyaillusztrációk · ${start ~/ 12 + 1}/${(cardIllustrationSubjects.length / 12).ceil()}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saját hátterek · 3:2 · középre helyezett tárgyak',
                      style: TextStyle(fontSize: 12, color: CanopyColors.muted),
                    ),
                    const SizedBox(height: 20),
                    CardDeck(cards: cards, columns: 3),
                  ],
                ),
              ),
            ),
          ),
        );
        await shot('0${start ~/ 12 + 1}-card-set');
      }
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (fiveCardExamples) {
      const examples = [
        (
          id: 'stone_spear',
          label: 'Lándzsa',
          title: 'Use spear',
          description: 'Needs Stone Spear',
        ),
        (id: 'forage', label: 'Bogyók', title: 'Forage', description: '1 time'),
        (
          id: 'firewood',
          label: 'Farönkök',
          title: 'Add wood',
          description: 'Needs 2 Wood',
        ),
        (
          id: 'small_fish',
          label: 'Hal',
          title: 'Catch fish',
          description: 'Needs Basic Rod',
        ),
        (
          id: 'back',
          label: 'Visszavonulás',
          title: 'Retreat',
          description: null,
        ),
      ];
      for (var i = 0; i < examples.length; i++) {
        final example = examples[i];
        await mount(
          Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      '${example.label} · kártyaminta',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Saját háttér · egységes 3:2 képarány',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: CanopyColors.muted),
                    ),
                    Expanded(
                      child: Center(
                        child: Transform.scale(
                          scale: 2.4,
                          child: SizedBox(
                            width: 114,
                            child: ActionCard(
                              title: example.title,
                              compact: true,
                              image:
                                  'assets/art/card_${example.id}_scene_preview_v1.png',
                              fixedHeight: 152,
                              titleMaxLines: 2,
                              description: example.description,
                              descriptionMaxLines: 2,
                              showStatus: false,
                              onTap: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Nagyított előnézet. A játékban a kártyák legfeljebb 160 px szélesek. A különálló ikonok megmaradnak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: CanopyColors.muted),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
        await shot(
          '${(i + 1).toString().padLeft(2, '0')}-${example.id}-card-example',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (cardExample) {
      // A production-sized 114 × 152 card has a 114 × 76 image window:
      // exactly 3:2. Enlarge it for review without changing its proportions.
      await mount(
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'Fáklya · kártyaillusztráció',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Saját sötét dzsungelháttér · 3:2 képarány',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: CanopyColors.muted),
                  ),
                  Expanded(
                    child: Center(
                      child: Transform.scale(
                        scale: 2.4,
                        child: SizedBox(
                          width: 114,
                          child: ActionCard(
                            title: 'Use torch',
                            compact: true,
                            image: 'assets/art/card_torch_scene_preview_v1.png',
                            fixedHeight: 152,
                            titleMaxLines: 2,
                            description: 'Needs Torch',
                            descriptionMaxLines: 2,
                            showStatus: false,
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'A különálló fáklyaikon megmarad a HUD-hoz és a kis UI-elemekhez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: CanopyColors.muted),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      );
      await shot('01-torch-card-example');
      await mount(
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'Egyetlen kártya · valós méret',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '390 px-es kijelző · legfeljebb 160 px széles kártya',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: CanopyColors.muted),
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        children: [
                          Expanded(
                            child: ActionCard(
                              title: 'Use torch',
                              image:
                                  'assets/art/card_torch_scene_preview_v1.png',
                              description: 'Needs Torch',
                              showStatus: false,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'A kép aránya itt is 3:2. A kártya teljes szélességű helyen sem nyúlik szét.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: CanopyColors.muted),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      );
      final nativeCard = find.byType(ActionCard);
      final surfaceSize = tester.getSize(
        find.descendant(of: nativeCard, matching: find.byType(Material)),
      );
      final imageSize = tester.getSize(
        find.descendant(of: nativeCard, matching: find.byType(AspectRatio)),
      );
      if ((surfaceSize.width - ActionCard.maxPortraitWidth).abs() > .01 ||
          (imageSize.aspectRatio - ActionCard.illustrationAspectRatio).abs() >
              .01) {
        throw StateError(
          'Card preview geometry: $surfaceSize, image $imageSize',
        );
      }
      await shot('02-single-card-max-width');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (artReview) {
      const subjects = [
        'health',
        'water',
        'food',
        'sanity',
        'wood',
        'stone',
        'fiber',
        'sun',
        'shelter',
        'inventory',
        'map',
        'moon',
        'forage',
        'stone_axe',
        'basic_rod',
        'torch',
        'stone_knife',
        'stone_spear',
        'back',
        'trail',
        'small_fish',
        'bait',
        'herb',
        'raw_meat',
        'water_filter',
        'rain_collector',
        'drying_rack',
        'journal',
        'hardwood',
        'metal_scrap',
        'leaf_bed',
        'firewood',
      ];
      await mount(
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text(
                    '32 ikon · teljes tárgyrajz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: .96,
                      children: [
                        for (final id in subjects)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: CanopyColors.panelLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CardArt(id, size: 50),
                                  const SizedBox(height: 4),
                                  Text(
                                    id.replaceAll('_', ' '),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      height: 1.1,
                                      color: CanopyColors.cream,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await shot('11-all-icons');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (eventRevision) {
      final attack = game(roll: 0)..travelTo('riverbank');
      attack.choose(attack.visibleChoices.firstWhere(attack.canChoose).id);
      attack.continueFromReport();
      attack.goDeeper();
      await mount(LostCanopyApp(engine: attack), app: true);
      await shot('01-encounter-choices');
      await tap('encounter-next');
      await shot('02-encounter-swiped');
      await tap('choice-meat');
      await shot('03-encounter-result');

      final forage = game()..startAction(CampAction.forage);
      await mount(LostCanopyApp(engine: forage), app: true);
      await shot('04-forage-choices');
      await tap('choice-gather');
      await shot('05-forage-result');

      final dusk = game(state: game().state.copyWith(timeLeft: 1));
      dusk.startAction(CampAction.rest);
      dusk.continueFromReport();
      await mount(LostCanopyApp(engine: dusk), app: true);
      await shot('06-night-choices');
      await tap('choice-wood');
      await shot('07-night-result');

      final fatal = game(
        roll: .99,
        state: RunState(
          stats: {
            SurvivalStat.health: 5,
            SurvivalStat.water: 80,
            SurvivalStat.food: 70,
            SurvivalStat.sanity: 80,
          },
        ),
      )..startAction(CampAction.forage);
      await mount(LostCanopyApp(engine: fatal), app: true);
      await tap('choice-risk');
      await shot('08-fatal-result');
      await tap('continue-outcome');
      await shot('09-game-over-after-result');
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    if (sceneRevision) {
      final trip = game()..travelTo('riverbank');
      trip.choose(trip.visibleChoices.firstWhere(trip.canChoose).id);
      trip.continueFromReport();
      await mount(ExpeditionScene(game: trip));
      await shot('01-expedition');
      final attack = game(roll: 0)..travelTo('riverbank');
      attack.choose(attack.visibleChoices.firstWhere(attack.canChoose).id);
      attack.continueFromReport();
      attack.goDeeper();
      await mount(EventScene(game: attack));
      await shot('02-encounter');
      await tap('encounter-next');
      await shot('03-encounter-next');
      await binding.setSurfaceSize(const Size(520, 844));
      tester.view.physicalSize = const Size(520, 844);
      await tester.pumpAndSettle();
      await shot('04-encounter-wide');
      await binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await tap('scene-details');
      await shot('05-encounter-details');
      await tap('close-dialog');
      await tap('encounter-next');
      await tester.drag(
        find.byKey(const ValueKey('encounter-card-rail')),
        const Offset(240, 0),
      );
      await tester.pumpAndSettle();
      await shot('06-encounter-swipe-back');
      File(
        '${directory.path}/manifest.txt',
      ).writeAsStringSync('${files.join('\n')}\n');
      await tester.pumpWidget(const SizedBox.shrink());
      return;
    }

    final camp = game();
    await mount(LostCanopyApp(engine: camp), app: true);
    await shot('01-camp-day');
    await tap('open-inventory');
    await shot('02-inventory-materials');
    await tap('inventory-tab-1');
    await shot('03-inventory-food');
    await tap('inventory-tab-2');
    await shot('04-inventory-gear');
    await tap('close-dialog');
    await mount(ExploreMapScreen(game: camp));
    await shot('05-explore-map');
    await tap('map-node-riverbank');
    await tester.pumpAndSettle();
    await shot('05b-explore-riverbank-selected');
    await tap('map-node-ancient_ruins');
    await tester.pumpAndSettle();
    await shot('06-explore-locked');
    await mount(CraftScreen(game: camp));
    await shot('07-craft');
    await tap('recipe-rain_collector');
    await shot('08-craft-locked');
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    await tap('tab-camp');
    await shot('09-camp-upgrade');
    await tap('recipe-camp_tier_2');
    await shot('10-camp-upgrade-locked');
    await mount(
      LostCanopyApp(engine: game(state: camp.state.copyWith(campTier: 1))),
      app: true,
    );
    await shot('11-camp-tier-1');

    final trip = game()..travelTo('riverbank');
    await mount(EventScene(game: trip));
    await shot('12-riverbank-event');
    trip.choose(trip.visibleChoices.firstWhere(trip.canChoose).id);
    trip.continueFromReport();
    await mount(ExpeditionScene(game: trip));
    await shot('13-expedition');
    await tester.tap(find.byKey(const ValueKey('expedition-deeper')));
    await tester.pumpAndSettle();
    await shot('13b-expedition-details');
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    final attack = game(roll: 0)..travelTo('riverbank');
    attack.choose(attack.visibleChoices.firstWhere(attack.canChoose).id);
    attack.continueFromReport();
    attack.goDeeper();
    await mount(EventScene(game: attack));
    await shot('14-encounter');
    await tester.tap(find.byKey(const ValueKey('choice-torch')));
    await tester.pumpAndSettle();
    await shot('14b-encounter-details');
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    final night = game(
      state: camp.state.copyWith(phase: RunPhase.night, timeLeft: 0),
    );
    await mount(LostCanopyApp(engine: night), app: true);
    await shot('15-camp-night');
    final dusk = game(state: camp.state.copyWith(timeLeft: 1));
    dusk.startAction(CampAction.rest);
    dusk.continueFromReport();
    await mount(EventScene(game: dusk));
    await shot('16-night-event');

    final pond = game()..travelTo('fishing_pond');
    await mount(FishingScreen(game: pond));
    await shot('17-fishing-ready');
    await tester.tap(find.byKey(const ValueKey('cast-line')));
    await tester.pump(const Duration(milliseconds: 100));
    await shot('18-fishing-waiting');
    for (
      var i = 0;
      i < 100 && pond.fishing!.stage == FishingStage.waiting;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shot('19-fishing-bite');
    await tester.tap(find.byKey(const ValueKey('hook-fish')));
    await tester.pump();
    await shot('20-fishing-reeling');
    await tester.tap(find.byKey(const ValueKey('fishing-return')));
    await tester.pumpAndSettle();
    await shot('21-fishing-exit');
    // Use a fresh fishing session for the completion state, leaving the popup alone.
    final catchGame = game()..travelTo('fishing_pond');
    catchGame.castLine();
    for (
      var i = 0;
      i < 100 && catchGame.fishing!.stage == FishingStage.waiting;
      i++
    ) {
      catchGame.fishing!.update(.05);
    }
    catchGame.fishing!.hook();
    for (var i = 0; i < 500 && !catchGame.fishing!.complete; i++) {
      final session = catchGame.fishing!;
      session.holding = session.cursor < session.target;
      session.update(.02);
    }
    await mount(FishingScreen(game: catchGame));
    await shot('22-fishing-result');
    final result = game()..craft('stone_axe');
    await mount(LostCanopyApp(engine: result), app: true);
    await shot('23-outcome');

    await mount(LostCanopyApp(engine: camp), app: true);
    await tap('camp-menu');
    await shot('24-camp-menu');
    await tap('menu-journal');
    await shot('25-journal');
    await tap('close-dialog');
    await tap('camp-menu');
    await tap('menu-guide');
    await shot('26-guide');
    await tap('close-dialog');
    await tap('camp-menu');
    await tap('menu-new-run');
    await shot('27-restart-confirmation');
    final ended = game(
      state: camp.state.copyWith(
        phase: RunPhase.gameOver,
        stats: {...camp.state.stats, SurvivalStat.health: 0},
      ),
    );
    await mount(LostCanopyApp(engine: ended), app: true);
    await shot('28-game-over');
    await mount(const RunLoadingScreen(), settle: false);
    await shot('29-loading');
    await mount(RunLoadingScreen(failed: true, onRetry: () {}));
    await shot('30-loading-error');
    File(
      '${directory.path}/manifest.txt',
    ).writeAsStringSync('${files.join('\n')}\n');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
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
