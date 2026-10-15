import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/camp_backdrop.dart';
import 'package:survival_game/ui/canopy_components.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/scene_artwork.dart';

import '../../../screenshots/tools/capture_fonts.dart';

const folder = 'design/survival-ecology-v1/ui';
late ui.Image plants, supplies, icons;
const ink = ParchmentColors.ink;
const muted = ParchmentColors.muted;
const cream = ParchmentColors.cream;
const leaf = ParchmentColors.leaf;
const rust = ParchmentColors.rust;
void noop() {}

final sample = RunState(
  day: 5,
  timeLeft: 3,
  weather: 'Light rain',
  campTier: 1,
  resources: {'wood': 9, 'stone': 3, 'fiber': 8, 'hardwood': 2, 'herb': 2},
  tools: {'stone_axe', 'stone_knife', 'basic_rod'},
  stats: {
    SurvivalStat.health: 72,
    SurvivalStat.water: 56,
    SurvivalStat.food: 61,
    SurvivalStat.sanity: 68,
  },
);

enum Condition { poison, injury, wet, exhausted }

extension ConditionStyle on Condition {
  String get title => switch (this) {
    Condition.poison => 'Poisoned II',
    Condition.injury => 'Injured',
    Condition.wet => 'Wet',
    Condition.exhausted => 'Exhausted',
  };
  Color get color => switch (this) {
    Condition.poison => const Color(0xFF617D35),
    Condition.injury => rust,
    Condition.wet => const Color(0xFF287E90),
    Condition.exhausted => const Color(0xFF9C733B),
  };
}

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    for (final entry in [
      ('plants-atlas-v1.png', 0),
      ('survival-supplies-atlas-v1.png', 1),
      ('inventory-status-icons-v1.png', 2),
    ]) {
      final codec = await tester.runAsync(
        () => ui.instantiateImageCodec(
          File('$folder/assets/${entry.$1}').readAsBytesSync(),
        ),
      );
      final frame = await tester.runAsync(() => codec!.getNextFrame());
      if (entry.$2 == 0) {
        plants = frame!.image;
      } else if (entry.$2 == 1) {
        supplies = frame!.image;
      } else {
        icons = frame!.image;
      }
      codec!.dispose();
    }
    await binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final boundary = GlobalKey();
    final manifest = <String>[];
    for (final entry in concepts.entries) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            theme: canopyTheme,
            debugShowCheckedModeBanner: false,
            home: entry.value(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var pass = 0; pass < 2; pass++) {
        final context = tester.element(find.byType(Scaffold).first);
        final images = find
            .byType(Image)
            .evaluate()
            .map((e) => (e.widget as Image).image)
            .toSet();
        await tester.runAsync(
          () =>
              Future.wait(images.map((image) => precacheImage(image, context))),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/art/ui_parchment_texture.png'),
            context,
          ),
        );
        await tester.pumpAndSettle();
      }
      final error = tester.takeException();
      if (error != null) throw StateError('${entry.key}: $error');
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '$folder/${entry.key}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      manifest.add('${entry.key}.png');
      stdout.writeln('RENDERED ${entry.key}');
    }
    const boards = [
      (
        '00a-status-and-foraging-overview',
        'Állapotok és növényismeret',
        [1, 2, 3, 4, 5, 6],
      ),
      (
        '00b-preparation-and-recovery-overview',
        'Felkészülés és kezelés',
        [7, 8, 9, 14, 15, 16],
      ),
      (
        '00c-encounters-and-consequences-overview',
        'Veszélyek és következmények',
        [10, 11, 12, 13, 17],
      ),
    ];
    await binding.setSurfaceSize(const Size(720, 1120));
    tester.view.physicalSize = const Size(720, 1120);
    for (final board in boards) {
      final names = [
        for (final i in board.$3)
          manifest.firstWhere(
            (name) => name.startsWith(i.toString().padLeft(2, '0')),
          ),
      ];
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            theme: canopyTheme,
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF102A28),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'LOST CANOPY · ${board.$2}',
                      style: const TextStyle(
                        color: cream,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'UI LÁTVÁNYTERVEK · 390 × 844 · nem bekötött játékmenet',
                      style: TextStyle(color: cream, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 18,
                      children: [
                        for (final name in names)
                          SizedBox(
                            width: 216,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: Text(
                                    name
                                        .replaceAll('.png', '')
                                        .replaceAll('-', ' '),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: cream,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Image.file(
                                  File('$folder/$name'),
                                  width: 216,
                                  height: 216 * 844 / 390,
                                  fit: BoxFit.contain,
                                  cacheWidth: 432,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold));
      final providers = find
          .byType(Image)
          .evaluate()
          .map((e) => (e.widget as Image).image)
          .toSet();
      await tester.runAsync(
        () => Future.wait(providers.map((p) => precacheImage(p, context))),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('${board.$1}: $error');
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '$folder/${board.$1}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      stdout.writeln('RENDERED ${board.$1}');
    }
    File('$folder/manifest.txt').writeAsStringSync('${manifest.join('\n')}\n');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  plants.dispose();
  supplies.dispose();
  icons.dispose();
  keepAlive.cancel();
  exit(0);
}

final concepts = <String, Widget Function()>{
  '01-camp-rain-and-statuses': () => scene(
    camp: true,
    rain: true,
    conditions: [(Condition.poison, 3), (Condition.wet, 2)],
    heading: paperNote(
      'CAMP GOAL',
      'Build Established Camp',
      'Your clothes are soaked. Rest or dry by the fire.',
    ),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Tap a condition for help',
            style: TextStyle(color: cream, fontSize: 10),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final p in [
              ('inventory', 'ITEMS'),
              ('craft', 'CRAFT'),
              ('journal', 'MENU'),
              ('map', 'MAP'),
            ]) ...[
              PaperSurface(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      CardArt(p.$1, size: 22),
                      ParchmentLabel(p.$2, size: 9),
                    ],
                  ),
                ),
              ),
              if (p.$2 != 'MAP') const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        cards([
          action('Forage', 'forage', '1 time', 'SURVIVAL'),
          action('Explore', 'map', '2 time', 'TRAVEL'),
          action('Rest', 'shelter', '1 time', 'RECOVER'),
        ]),
      ],
    ),
  ),
  '02-poison-condition-details': () => modal(
    'POISONED II',
    glyph: ConditionSymbol(Condition.poison, size: 35),
    subtitle: '3 time remaining',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        body(
          'The toxin weakens you when time passes. Reading and opening menus are safe.',
        ),
        const SizedBox(height: 14),
        rowLine(
          const CardArt('health', size: 24),
          'Health lost each time',
          '−4',
          color: rust,
        ),
        rowLine(
          const CardArt('water', size: 24),
          'Extra water each time',
          '−2',
          color: rust,
        ),
        rowLine(
          const Icon(Icons.shield_outlined, color: ink, size: 24),
          'Physical encounters',
          'WEAKENED',
          color: rust,
        ),
        const Divider(height: 22),
        body('Healing will not restore health until the poison is gone.'),
        const SizedBox(height: 14),
        itemRow(
          const AtlasIcon(8, size: 40),
          'Antidote',
          'Removes poison · 1 owned',
        ),
        const SizedBox(height: 10),
        button('USE ANTIDOTE'),
        const SizedBox(height: 8),
        secondary('Other option: bitter leaves'),
      ],
    ),
  ),
  '03-foraging-new-species': () => scene(
    background: 'assets/art/foraging_background_v1.png',
    heading: paperNote(
      'GATHERING · 8 SECONDS',
      'Choose up to 3 plants',
      'Recognise the leaves, shape and markings.',
    ),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PaperSurface(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: ParchmentLabel('6.4 s', size: 14)),
                const ParchmentLabel('1 / 3 PICKED', size: 11),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        cards([
          plantCard(0, 'Ember berries', 'Familiar', 'PICKED'),
          plantCard(6, 'Wax berries', 'Unidentified', 'PICK'),
          plantCard(8, 'Medicinal herb', 'Knife required', 'PICK'),
        ]),
      ],
    ),
  ),
  '04-items-food-variety': () => modal(
    'CAMP ITEMS',
    art: 'inventory',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tabs(['MATERIALS', 'FOOD', 'GEAR'], 1),
        const SizedBox(height: 12),
        cards([
          plantCard(0, 'Ember berries', 'Familiar', '× 3'),
          plantCard(1, 'Dew fruit', 'Familiar', '× 1'),
          plantCard(3, 'Iron nuts', 'Knife required', '× 2'),
          plantCard(4, 'Wild honey', 'Familiar', '× 1'),
          plantCard(5, 'Ribbon roots', 'Prepare at camp', '× 3'),
          plantCard(6, 'Wax berries', 'Known toxic', '× 2'),
        ]),
        const SizedBox(height: 12),
        const ParchmentLabel(
          'Tap an item to inspect or use it.',
          size: 11,
          color: muted,
        ),
      ],
    ),
  ),
  '05-unidentified-species-details': () => modal(
    'WAX BERRIES',
    glyph: const Icon(Icons.search_rounded, size: 30, color: ink),
    subtitle: 'UNIDENTIFIED SPECIES',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        photo(SheetArt(6)),
        const SizedBox(height: 12),
        body(
          'Two blue berries, pale dots and thick round leaves. You have not studied this plant.',
        ),
        const SizedBox(height: 12),
        iconNote(
          Icons.visibility_outlined,
          'Look for the dotted skin and rounded leaves.',
        ),
        const SizedBox(height: 12),
        costs([('sun', '1', 'TIME'), ('wax_berries', '1', 'SAMPLE')]),
        const SizedBox(height: 12),
        button('EXAMINE SAMPLE'),
        const SizedBox(height: 8),
        secondary('Eat anyway · unknown risk'),
      ],
    ),
  ),
  '06-journal-known-toxic-plant': () => modal(
    'JUNGLE KNOWLEDGE',
    art: 'journal',
    subtitle: 'WAX BERRIES · IDENTIFIED',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        photo(SheetArt(6)),
        const SizedBox(height: 12),
        Row(
          children: [
            ConditionSymbol(Condition.poison, size: 26),
            const SizedBox(width: 8),
            const ParchmentLabel('TOXIC', size: 15, color: rust),
          ],
        ),
        const SizedBox(height: 8),
        body(
          'Eating these berries causes poisoning. Their blue pigment can be used to mark your trail.',
        ),
        const SizedBox(height: 14),
        section('RECOGNISE IT'),
        body('White dots · paired berries · round leaves'),
        const SizedBox(height: 14),
        section('USEFUL FOR'),
        itemRow(
          const CardArt('map', size: 34),
          'Trail marker',
          'Helps you recognise a safe way back',
        ),
        const SizedBox(height: 10),
        button('VIEW TRAIL MARKER'),
      ],
    ),
  ),
  '07-workshop-survival-recipes': () => scene(
    camp: true,
    conditions: [(Condition.poison, 3)],
    heading: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        paperNote(
          'WORKSHOP',
          'Prepare for the jungle',
          'Craft protection before heading out.',
        ),
        const SizedBox(height: 8),
        tabs(['TOOLS', 'SURVIVAL', 'CAMP'], 1),
      ],
    ),
    footer: cards([
      medicalCard(0, 'Antidote', '1 time', 'CRAFT'),
      medicalCard(1, 'Bandage', '1 time', 'CRAFT'),
      medicalCard(3, 'Leaf rain cape', 'Tier 1', 'CRAFT'),
      medicalCard(2, 'Charcoal', '1 time', 'CRAFT'),
      medicalCard(6, 'Trail marker', 'Use in the field', 'DETAILS'),
      medicalCard(5, 'Prepare roots', '1 time', 'PREPARE'),
    ]),
  ),
  '08-antidote-craft-details': () => modal(
    'CRAFT ANTIDOTE',
    glyph: const AtlasIcon(8, size: 34),
    subtitle: 'PREPARE ONE DOSE',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        photo(SheetArt(0, medical: true)),
        const SizedBox(height: 12),
        body('Removes poisoning. It does not restore health already lost.'),
        const SizedBox(height: 14),
        section('REQUIRED'),
        costs([
          ('herb', '1', 'HERB'),
          ('charcoal', '1', 'CHARCOAL'),
          ('water', '6', 'WATER'),
          ('sun', '1', 'TIME'),
        ]),
        const SizedBox(height: 12),
        iconNote(
          Icons.schedule,
          'Time passes while crafting. Your poison remains active.',
        ),
        const SizedBox(height: 14),
        button('CRAFT 1 ANTIDOTE'),
      ],
    ),
  ),
  '09-use-antidote-confirmation': () => modal(
    'USE ANTIDOTE',
    glyph: const AtlasIcon(8, size: 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        photo(SheetArt(0, medical: true)),
        const SizedBox(height: 12),
        statusBanner(Condition.poison, 3),
        const SizedBox(height: 12),
        body('Remove Poisoned II now. Lost health will not be restored.'),
        const SizedBox(height: 14),
        rowLine(
          const Icon(Icons.inventory_2_outlined, size: 22, color: ink),
          'Antidote',
          '1 → 0',
        ),
        rowLine(const CardArt('sun', size: 22), 'Time cost', 'NONE'),
        const SizedBox(height: 14),
        button('DRINK ANTIDOTE'),
      ],
    ),
  ),
  '10-frog-herb-encounter': () => scene(
    fileBackground: '$folder/assets/frog-herb-encounter-v1.png',
    conditions: [(Condition.wet, 2)],
    heading: paperNote(
      'MANGROVE · ENCOUNTER',
      'The leaves have a guardian',
      'A patterned frog sits among the silver-veined herbs.',
    ),
    footer: cards([
      action('Leave it alone', 'back', 'No extra cost', 'SAFE'),
      action('Cut the stems', 'stone_knife', 'Knife required', 'CAREFUL'),
      action('Reach in', 'herb', 'Bare hands', 'RISKY'),
    ]),
  ),
  '11-rain-slippery-crossing': () => scene(
    background: 'assets/art/riverbank_camp_style_v2.png',
    rain: true,
    conditions: [(Condition.injury, 4), (Condition.exhausted, 3)],
    heading: paperNote(
      'RIVERBANK · STORM',
      'The bank gives way',
      'Rain has turned the crossing into slippery mud.',
    ),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        darkNote('Injured and exhausted · physical actions are harder'),
        const SizedBox(height: 8),
        cards([
          action('Make a handline', 'fiber', '2 Fiber', 'SAFE'),
          action('Take the detour', 'trail', '1 extra time', 'SAFE'),
          action('Jump across', 'back', 'Slippery ground', 'RISKY'),
        ]),
      ],
    ),
  ),
  '12-outcome-poison-acquired': () => modal(
    'A PAINFUL DISCOVERY',
    glyph: ConditionSymbol(Condition.poison, size: 34),
    subtitle: 'WHAT HAPPENED',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        body(
          'Your hand brushes the frog as you reach for the herbs. A numb sting spreads through your arm.',
        ),
        const SizedBox(height: 14),
        statusBanner(Condition.poison, 4),
        const SizedBox(height: 12),
        body(
          'Poison will damage your health when time passes. An antidote removes it.',
        ),
        const Divider(height: 24),
        rowLine(const CardArt('health', size: 26), 'Health', '−4', color: rust),
        const Align(
          alignment: Alignment.centerRight,
          child: ParchmentLabel('72 left', size: 10, color: muted),
        ),
        const SizedBox(height: 10),
        iconNote(
          Icons.menu_book_outlined,
          'Poisonous frog added to jungle knowledge.',
        ),
        const SizedBox(height: 16),
        button('CONTINUE'),
      ],
    ),
    backgroundFile: '$folder/assets/frog-herb-encounter-v1.png',
  ),
  '13-day-end-with-conditions': dayEnd,
  '14-dry-by-fire-details': () => modal(
    'DRY BY THE FIRE',
    art: 'shelter',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        photo(SheetArt(4, medical: true)),
        const SizedBox(height: 12),
        statusBanner(Condition.wet, 2),
        const SizedBox(height: 12),
        body(
          'Dry your clothes under the shelter. Other active conditions still affect the time spent.',
        ),
        const SizedBox(height: 14),
        costs([('wood', '1', 'WOOD'), ('sun', '1', 'TIME')]),
        const SizedBox(height: 14),
        button('DRY YOUR CLOTHES'),
      ],
    ),
  ),
  '15-hunting-while-exhausted': () => scene(
    background: 'assets/art/hunting_background_v1.png',
    conditions: [(Condition.exhausted, 3)],
    heading: paperNote(
      'HUNTING',
      'Wait for a clear shot',
      'Tap THROW as the marker crosses the target zone.',
    ),
    footer: PaperSurface(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ConditionSymbol(Condition.exhausted, size: 24),
                const SizedBox(width: 8),
                const Expanded(child: ParchmentLabel('EXHAUSTED', size: 12)),
                const ParchmentLabel('NARROWER ZONE', size: 9, color: rust),
              ],
            ),
            const SizedBox(height: 8),
            body(
              'Your timing window is smaller. There is no extra hidden success roll.',
            ),
            const SizedBox(height: 14),
            SizedBox(height: 32, child: CustomPaint(painter: TimingPainter())),
            const SizedBox(height: 14),
            button('THROW'),
          ],
        ),
      ),
    ),
  ),
  '16-prepare-ribbon-roots': () => modal(
    'PREPARE RIBBON ROOTS',
    glyph: const AtlasIcon(5, size: 34),
    subtitle: 'COOK AT CAMP',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: AspectRatio(aspectRatio: 1.5, child: SheetArt(5))),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_forward, color: ink),
            ),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5,
                child: SheetArt(5, medical: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        body(
          'Raw ribbon roots can make you sick. Prepare a batch over the campfire before eating.',
        ),
        const SizedBox(height: 14),
        costs([
          ('ribbon_root', '3', 'ROOTS'),
          ('wood', '1', 'WOOD'),
          ('sun', '1', 'TIME'),
        ]),
        const SizedBox(height: 14),
        rowLine(
          const Icon(Icons.restaurant_rounded, size: 23, color: ink),
          'Prepared portions',
          '3',
        ),
        const SizedBox(height: 12),
        button('PREPARE 3 PORTIONS'),
      ],
    ),
  ),
  '17-all-conditions-guide': () => modal(
    'CONDITIONS',
    art: 'journal',
    subtitle: 'TIME MOVES WHEN YOU ACT',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in [
          (
            Condition.poison,
            'Loses health and water. Healing cannot restore health.',
            'Treat with Antidote.',
          ),
          (
            Condition.injury,
            'Physical actions are harder. Healing is reduced.',
            'Use Bandage or rest.',
          ),
          (
            Condition.wet,
            'Consumes more food and drains sanity.',
            'Dry by the fire or under shelter.',
          ),
          (
            Condition.exhausted,
            'Consumes more supplies. Timing windows get smaller.',
            'Rest or sleep.',
          ),
        ]) ...[
          Row(
            children: [
              ConditionSymbol(p.$1, size: 30),
              const SizedBox(width: 9),
              ParchmentLabel(
                p.$1 == Condition.poison
                    ? 'POISONED I / II'
                    : p.$1.title.toUpperCase(),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 6),
          body(p.$2),
          const SizedBox(height: 4),
          ParchmentLabel(p.$3, size: 12, color: leaf),
          const Divider(height: 22),
        ],
        body(
          'No time or health is lost while reading, pausing or opening menus.',
        ),
      ],
    ),
  ),
};

Widget scene({
  String? background,
  String? fileBackground,
  bool camp = false,
  bool rain = false,
  List<(Condition, int)> conditions = const [],
  Widget? heading,
  required Widget footer,
}) => Scaffold(
  backgroundColor: const Color(0xFF102A28),
  body: Stack(
    children: [
      Positioned.fill(
        child: camp
            ? CampBackdrop(state: sample, busy: true, initialVariant: 0)
            : fileBackground != null
            ? fileScene(fileBackground)
            : SceneArtwork(asset: background!),
      ),
      if (rain)
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: RainPainter())),
        ),
      Positioned.fill(
        child: SafeArea(
          child: CanopySceneBody(
            footer: footer,
            header: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CanopyHud(state: sample),
                if (conditions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  statusStrip(conditions),
                ],
                if (heading != null) ...[const SizedBox(height: 12), heading],
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);

Widget modal(
  String title, {
  String? subtitle,
  String art = 'journal',
  Widget? glyph,
  required Widget child,
  String? backgroundFile,
}) => Scaffold(
  backgroundColor: const Color(0xFF102A28),
  body: Stack(
    children: [
      Positioned.fill(
        child: backgroundFile == null
            ? CampBackdrop(state: sample, busy: true, initialVariant: 0)
            : fileScene(backgroundFile),
      ),
      const Positioned.fill(child: ColoredBox(color: Color(0xA8071714))),
      SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                child: Center(
                  child: PaperSurface(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              glyph ?? CardArt(art, size: 30),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ParchmentLabel(title, size: 17),
                                    if (subtitle != null)
                                      ParchmentLabel(
                                        subtitle,
                                        size: 10,
                                        color: muted,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              ParchmentClose(onPressed: noop),
                            ],
                          ),
                          const Divider(height: 20),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);

Widget paperNote(String eyebrow, String title, String detail) => PaperSurface(
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ParchmentLabel(eyebrow, size: 10, color: leaf),
        const SizedBox(height: 4),
        ParchmentLabel(title, size: 18),
        const SizedBox(height: 6),
        body(detail),
      ],
    ),
  ),
);
Widget body(String text) =>
    Text(text, style: const TextStyle(fontSize: 12, height: 1.4, color: ink));
Widget section(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: ParchmentLabel(title, size: 10, color: muted),
);
Widget button(String label) =>
    SizedBox(width: double.infinity, child: parchmentButton(label, noop));
Widget secondary(String label) => SizedBox(
  width: double.infinity,
  child: parchmentButton(label, noop, secondary: true),
);
Widget photo(Widget art) =>
    Center(child: SizedBox(width: 270, height: 180, child: art));
Widget darkNote(String text) => Padding(
  padding: const EdgeInsets.all(6),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: cream,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
    ),
  ),
);
Widget tabs(List<String> labels, int selected) => Row(
  children: [
    for (var i = 0; i < labels.length; i++) ...[
      if (i > 0) const SizedBox(width: 6),
      Expanded(
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: i == selected ? leaf : const Color(0xFFE6D6AE),
            border: Border.all(color: const Color(0xFFB7A981)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ParchmentLabel(
            labels[i],
            size: 10,
            color: i == selected ? cream : ink,
          ),
        ),
      ),
    ],
  ],
);
Widget cards(List<Widget> children) => ParchmentCardGrid(children: children);
Widget plantCard(int cell, String title, String info, String status) =>
    ParchmentCard(
      title: title,
      art: 'forage',
      info: info,
      status: status,
      onTap: noop,
      artWidget: SheetArt(cell),
    );
Widget medicalCard(int cell, String title, String info, String status) =>
    ParchmentCard(
      title: title,
      art: 'herb',
      info: info,
      status: status,
      onTap: noop,
      artWidget: SheetArt(cell, medical: true),
    );
Widget action(String title, String art, String info, String status) =>
    ParchmentCard(
      title: title,
      art: art,
      info: info,
      status: status,
      onTap: noop,
    );
Widget itemRow(Widget art, String name, String detail) => Row(
  children: [
    SizedBox(width: 66, height: 44, child: art),
    const SizedBox(width: 10),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParchmentLabel(name, size: 13),
          ParchmentLabel(detail, size: 11, color: muted),
        ],
      ),
    ),
  ],
);
Widget iconNote(IconData icon, String label) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Icon(icon, size: 20, color: leaf),
    const SizedBox(width: 8),
    Expanded(child: body(label)),
  ],
);
Widget rowLine(Widget icon, String label, String value, {Color color = ink}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(child: ParchmentLabel(label, size: 12)),
          const SizedBox(width: 8),
          ParchmentLabel(value, size: 12, color: color),
        ],
      ),
    );
Widget costs(List<(String, String, String)> values) => LayoutBuilder(
  builder: (context, c) {
    final columns = MediaQuery.textScalerOf(context).scale(12) > 18
        ? 2
        : values.length;
    final width = (c.maxWidth - 6 * (columns - 1)) / columns;
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: [
        for (final value in values)
          SizedBox(
            width: width,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB7A981)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                children: [
                  itemIcon(value.$1, size: 22),
                  ParchmentLabel(value.$2, size: 17),
                  ParchmentLabel(value.$3, size: 9, color: muted),
                ],
              ),
            ),
          ),
      ],
    );
  },
);
Widget statusStrip(List<(Condition, int)> conditions) => Align(
  alignment: Alignment.centerRight,
  child: PaperSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final condition in conditions)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConditionSymbol(condition.$1, size: 19),
                const SizedBox(width: 4),
                ParchmentLabel(
                  '${condition.$1.title} · ${condition.$2}',
                  size: 10,
                ),
              ],
            ),
        ],
      ),
    ),
  ),
);
Widget statusBanner(Condition condition, int time) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: condition.color.withValues(alpha: .10),
    border: Border.all(color: condition.color),
    borderRadius: BorderRadius.circular(3),
  ),
  child: Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConditionSymbol(condition, size: 27),
          const SizedBox(width: 8),
          ParchmentLabel(condition.title.toUpperCase(), size: 13),
        ],
      ),
      ParchmentLabel('$time time left', size: 11, color: muted),
    ],
  ),
);
Widget miniStats() => LayoutBuilder(
  builder: (context, c) {
    final columns = MediaQuery.textScalerOf(context).scale(12) > 18 ? 2 : 4;
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: [
        for (final stat in SurvivalStat.values)
          SizedBox(
            width: (c.maxWidth - 6 * (columns - 1)) / columns,
            child: miniStat(stat, sample.value(stat)),
          ),
      ],
    );
  },
);

Widget dayEnd() => modal(
  'DAY 5 SURVIVED',
  art: 'moon',
  subtitle: 'END OF DAY',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      body('Another night in the canopy. You are still here.'),
      const Divider(height: 20),
      section('TODAY'),
      rowLine(const CardArt('map', size: 23), 'Explored Mangrove Shallows', ''),
      rowLine(const CardArt('craft', size: 23), 'Prepared an Antidote', ''),
      rowLine(
        ConditionSymbol(Condition.poison, size: 23),
        'Poison treated',
        '',
      ),
      const SizedBox(height: 12),
      section('GOING INTO DAY 6'),
      miniStats(),
      const SizedBox(height: 10),
      statusStrip([(Condition.injury, 3), (Condition.wet, 1)]),
      const SizedBox(height: 14),
      section('CAMP MATERIALS'),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final p in [
            ('wood', '9 Wood'),
            ('stone', '3 Stone'),
            ('fiber', '8 Fiber'),
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CardArt(p.$1, size: 22),
                const SizedBox(width: 5),
                ParchmentLabel(p.$2, size: 11),
              ],
            ),
        ],
      ),
      const Divider(height: 24),
      itemRow(
        const CardArt('shelter', size: 28),
        'TOMORROW',
        'Build Established Camp',
      ),
      const SizedBox(height: 14),
      button('NEXT DAY  →'),
    ],
  ),
);
Widget miniStat(SurvivalStat stat, int value) => Container(
  padding: const EdgeInsets.all(5),
  decoration: BoxDecoration(
    border: Border.all(color: const Color(0xFFB7A981)),
    borderRadius: BorderRadius.circular(3),
  ),
  child: Column(
    children: [
      Row(
        children: [
          CardArt(stat.name, size: 20),
          const Spacer(),
          ParchmentLabel('$value', size: 10),
        ],
      ),
      const SizedBox(height: 6),
      LinearProgressIndicator(
        value: value / 100,
        minHeight: 5,
        color: switch (stat) {
          SurvivalStat.health => const Color(0xFFC14C3E),
          SurvivalStat.water => const Color(0xFF298CA2),
          SurvivalStat.food => const Color(0xFFA86A35),
          SurvivalStat.sanity => const Color(0xFF87639C),
        },
        backgroundColor: const Color(0xFFD1C5A3),
      ),
      const SizedBox(height: 5),
      ParchmentLabel(stat.label.toUpperCase(), size: 8, color: muted),
    ],
  ),
);

class SheetArt extends StatelessWidget {
  const SheetArt(this.cell, {super.key, this.medical = false});
  final int cell;
  final bool medical;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: SheetPainter(medical ? supplies : plants, cell),
    size: Size.infinite,
  );
}

class SheetPainter extends CustomPainter {
  SheetPainter(
    this.image,
    this.cell, {
    this.columns = 3,
    this.rows = 3,
    this.fit = BoxFit.cover,
  });
  final ui.Image image;
  final int cell;
  final int columns, rows;
  final BoxFit fit;
  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      (cell % columns) * image.width / columns,
      (cell ~/ columns) * image.height / rows,
      image.width / columns,
      image.height / rows,
    );
    final fitted = applyBoxFit(fit, source.size, size);
    final crop = Alignment.center.inscribe(fitted.source, source);
    canvas.drawImageRect(
      image,
      crop,
      Alignment.center.inscribe(fitted.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(SheetPainter old) =>
      old.image != image ||
      old.cell != cell ||
      old.columns != columns ||
      old.rows != rows ||
      old.fit != fit;
}

class AtlasIcon extends StatelessWidget {
  const AtlasIcon(this.cell, {super.key, this.size = 24});
  final int cell;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: SheetPainter(
        icons,
        cell,
        columns: 4,
        rows: 4,
        fit: BoxFit.contain,
      ),
    ),
  );
}

Widget itemIcon(String id, {double size = 24}) => switch (id) {
  'charcoal' => AtlasIcon(10, size: size),
  'wax_berries' => AtlasIcon(6, size: size),
  'ribbon_root' => AtlasIcon(5, size: size),
  _ => CardArt(id, size: size),
};

Widget fileScene(String path) => Center(
  child: AspectRatio(
    aspectRatio: 9 / 16,
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, .035, .965, 1],
      ).createShader(rect),
      child: Image.file(File(path), fit: BoxFit.cover),
    ),
  ),
);

class ConditionSymbol extends StatelessWidget {
  const ConditionSymbol(this.condition, {super.key, this.size = 24});
  final Condition condition;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: AtlasIcon(12 + condition.index, size: size),
  );
}

class RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x16465D79),
    );
    final p = Paint()
      ..color = const Color(0x448CB8C3)
      ..strokeWidth = 1;
    for (var i = 0; i < 65; i++) {
      final x = (i * 73.0) % size.width;
      final y = (i * 139.0) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 15), p);
    }
  }

  @override
  bool shouldRepaint(RainPainter old) => false;
}

class TimingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bar = Rect.fromLTWH(0, 7, size.width, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(4)),
      Paint()..color = const Color(0xFFBCB193),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .41, 7, size.width * .18, 18),
      Paint()..color = const Color(0xFF729457),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .47, 7, size.width * .06, 18),
      Paint()..color = leaf,
    );
    canvas.drawLine(
      Offset(size.width * .46, 1),
      Offset(size.width * .46, 31),
      Paint()
        ..color = ink
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(TimingPainter old) => false;
}
