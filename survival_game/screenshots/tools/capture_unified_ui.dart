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
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
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

import 'capture_fonts.dart';

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
  final directory = Directory(
    encounterStyle
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
        : 'screenshots/unified-ui-v1',
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
        for (final file in Directory(
          'assets/art',
        ).listSync().whereType<File>()) {
          if (!file.path.endsWith('.png') || !context.mounted) continue;
          await precacheImage(AssetImage(file.path), context);
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
    }

    if (encounterStyle) {
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
                      'Kártyaillusztrációk · ${start ~/ 12 + 1}/3',
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
      await tap('close-scene-details');
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
    await tap('close-inventory');
    await mount(ExploreMapScreen(game: camp));
    await shot('05-explore-map');
    await tester.tap(find.text('Ancient Ruins'));
    await tester.pumpAndSettle();
    await shot('06-explore-locked');
    await mount(CraftScreen(game: camp));
    await shot('07-craft');
    await tap('recipe-rain_collector');
    await shot('08-craft-locked');
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
    final attack = game(roll: 0)..travelTo('riverbank');
    attack.choose(attack.visibleChoices.firstWhere(attack.canChoose).id);
    attack.continueFromReport();
    attack.goDeeper();
    await mount(EventScene(game: attack));
    await shot('14-encounter');
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
    await tap('close-journal');
    await tap('camp-menu');
    await tap('menu-guide');
    await shot('26-guide');
    await tap('close-guide');
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
