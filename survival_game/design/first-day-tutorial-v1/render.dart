import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import '../../screenshots/tools/capture_fonts.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/world_catalog.dart';
import 'package:survival_game/ui/camp_screen.dart';
import 'package:survival_game/ui/craft_screen.dart';
import 'package:survival_game/ui/inventory_panels.dart';
import 'package:survival_game/ui/expedition_scene.dart';
import 'package:survival_game/ui/event_scene.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/card_art.dart';
import '../run-progression-v1/render.dart' as u;

const folder = 'design/first-day-tutorial-v1';

class _Fixed implements Random {
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

GameEngine initial() => GameEngine(
  EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
  recipes: RecipeCatalog.fromJson(
    File('assets/data/recipes.json').readAsStringSync(),
  ),
  world: WorldCatalog.fromJson(
    File('assets/data/locations.json').readAsStringSync(),
  ),
  random: _Fixed(),
);
void require(bool ok, String message) {
  if (!ok) throw StateError(message);
}

GameEngine collected() {
  final g = initial();
  require(g.startAction(CampAction.forage), 'Forage');
  require(g.pendingEvent?.id == 'berry_patch', 'Expected berries');
  require(g.choose('gather'), 'Gather');
  g.continueFromReport();
  return g;
}

GameEngine eaten() {
  final g = collected();
  require(g.consume('ember_berries'), 'Eat');
  g.continueFromReport();
  return g;
}

GameEngine equipped() {
  final g = eaten();
  require(g.craft('torch'), 'Craft');
  g.continueFromReport();
  return g;
}

GameEngine packing() {
  final g = equipped();
  require(g.beginPacking('riverbank'), 'Pack');
  require(
    g.updatePacking({'ember_berries': 1, 'herb': 1}, {'torch'}),
    'Supplies',
  );
  return g;
}

GameEngine expedition() {
  final g = packing();
  require(g.leaveCamp(), 'Leave');
  require(g.pendingEvent?.id == 'river_supplies', 'River supplies');
  require(g.choose('rod_materials'), 'Recover supplies');
  g.continueFromReport();
  return g;
}

GameEngine night() {
  final g = expedition();
  require(g.returnHome(), 'Return');
  g.continueFromReport();
  for (var i = 0; i < 2; i++) {
    require(g.startAction(CampAction.rest), 'Rest');
    g.continueFromReport();
  }
  require(g.pendingEvent?.id == 'fire_dying', 'Night event');
  return g;
}

GameEngine dawn() {
  final g = night();
  require(g.choose('torch'), 'Night decision');
  g.continueFromReport();
  require(g.sleep(), 'Sleep');
  require(g.state.day == 2 && g.metrics.nights == 1, 'Actual first dawn');
  return g;
}

Widget coach(
  Widget screen,
  int step,
  String title,
  String copy, {
  double bottom = 240,
}) => LayoutBuilder(
  builder: (context, box) {
    final compact =
        box.maxHeight < 650 ||
        box.maxWidth < 360 ||
        MediaQuery.textScalerOf(context).scale(12) > 18;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(child: screen),
          Positioned(
            left: 12,
            right: 12,
            bottom: compact ? 12 : bottom,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight * .42),
              child: PaperSurface(
                selected: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: u.column([
                    Row(
                      children: [
                        Expanded(
                          child: u.label(
                            'FIRST DAY · $step / 6',
                            size: 10,
                            color: u.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: u.noop,
                          child: const Text('Later'),
                        ),
                        TextButton(
                          onPressed: u.noop,
                          child: const Text('Skip guide'),
                        ),
                      ],
                    ),
                    u.label(title, size: 19),
                    u.gap(6),
                    u.label(copy, size: 13),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
);
final concepts = <String, Widget Function()>{
  '01-welcome': () => u.page(
    'YOUR FIRST DAY',
    'LEARN BY PLAYING · OPTIONAL',
    [
      AspectRatio(
        aspectRatio: 1.5,
        child: Image.asset(
          'assets/art/camp_tier_0_empty_v1.jpg',
          fit: BoxFit.cover,
        ),
      ),
      u.gap(16),
      u.label('Survive tonight. Build your way home.', size: 24),
      u.gap(),
      u.label(
        'Time moves when you choose an action. Reading and looking around cost no daylight.',
      ),
      u.section('WE WILL LEARN TO'),
      for (final v in [
        ('forage', 'Gather and eat'),
        ('torch', 'Craft a useful tool'),
        ('inventory', 'Pack, explore and return'),
        ('moon', 'Survive the first night'),
      ])
        u.line(v.$2, '', art: v.$1),
      u.gap(),
      u.notice(
        'You can collapse or skip the guide at any time. Your supplies follow the normal game rules.',
      ),
    ],
    close: false,
    actions: [
      u.button('GUIDE MY FIRST DAY'),
      u.button('PLAY WITHOUT HELP', secondary: true),
    ],
  ),
  '02-first-forage': () => coach(
    CampScreen(engine: initial()),
    1,
    'Find something to eat',
    'Tap FORAGE, then open a choice. The action uses daylight only when you confirm.',
  ),
  '03-eat-your-find': () => u.page(
    'EAT WHAT YOU FOUND',
    'FIRST DAY · 2 / 6',
    [
      u.notice('Gathering stored food. It did not feed you yet.'),
      u.gap(16),
      Center(
        child: SizedBox(
          width: 240,
          child: const InventoryPicture('ember_berries'),
        ),
      ),
      u.section('EMBER BERRIES · FAMILIAR & SAFE'),
      u.line('In camp storage', '2 portions', art: 'ember_berries'),
      u.line(
        'Daylight remaining',
        '${collected().state.timeLeft}/6',
        art: 'sun',
      ),
      u.gap(),
      u.label(
        'Open ITEMS, choose the berries and eat one portion. The result shows what changed.',
      ),
      u.gap(),
      u.notice(
        'Using a food portion costs no daylight. Unknown foods may need study or preparation.',
      ),
    ],
    art: 'ember_berries',
    actions: [u.button('OPEN ITEMS'), u.button('LATER', secondary: true)],
  ),
  '04-first-craft': () => coach(
    CraftScreen(game: eaten()),
    3,
    'Make your first tool',
    'Open TORCH. Check the recipe, then confirm the craft. Only a completed craft advances this lesson.',
    bottom: 16,
  ),
  '05-first-pack': () => coach(
    PackingScreen(game: packing()),
    4,
    'Choose what comes with you',
    'Backpack supplies use slots. The torch goes in GEAR. Camp storage stays here. Confirm LEAVE CAMP when ready.',
    bottom: 88,
  ),
  '06-return-home': () => coach(
    ExpeditionScene(game: expedition()),
    5,
    'Bring your finds home',
    'For this first trip, choose RETURN TO CAMP. Your backpack unloads automatically. Going deeper is optional.',
  ),
  '07-first-night': () => coach(
    EventScene(game: night()),
    6,
    'Night is another decision',
    'No daylight remains. Resolve this night event, then choose SLEEP. The next dawn completes your first day.',
  ),
  '08-first-day-complete': () => u.page(
    'YOU SURVIVED',
    'FIRST DAY COMPLETE · DAY ${dawn().state.day}',
    [
      u.gap(12),
      const Center(child: CardArt('sun', size: 86)),
      u.gap(20),
      u.label('One night survived. The jungle opens up.', size: 24),
      u.gap(16),
      for (final v in [
        ('Gathered food', 'forage'),
        ('Ate a portion', 'ember_berries'),
        ('Crafted a tool', 'torch'),
        ('Packed for the trail', 'inventory'),
        ('Returned safely', 'map'),
        ('Survived the night', 'moon'),
      ])
        u.line(v.$1, 'LEARNED', art: v.$2),
      u.section('YOUR NEXT GOAL'),
      u.label(
        'Build your first refuge. Explore for supplies and prepare before nightfall.',
      ),
      u.gap(),
      u.notice(
        'Fishing, plant safety and tool care are explained when you first use them. Every guide remains in the menu.',
      ),
      u.gap(),
      u.label(
        'Your normal day summary and supplies are saved. No separate tutorial XP bonus.',
        size: 12,
        color: u.muted,
      ),
    ],
    close: false,
    actions: [
      u.button('CONTINUE TO DAY 2'),
      u.button('OPEN SURVIVAL GUIDE', secondary: true),
    ],
  ),
};

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final boundary = GlobalKey();
    final files = <String>[];
    Future<void> mount(Widget widget, Size size, double scale) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            theme: canopyTheme,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      final providers =
          find
              .byType(Image)
              .evaluate()
              .map((e) => (e.widget as Image).image)
              .toSet()
            ..add(const AssetImage('assets/art/ui_parchment_texture.png'));
      await tester.runAsync(
        () => Future.wait(providers.map((p) => precacheImage(p, context))),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$size text $scale: $error');
    }

    Future<void> save(String name, {double ratio = 3}) async {
      final picture =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: ratio);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      File('$folder/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      picture.dispose();
      stdout.writeln('RENDERED $name');
    }

    for (final entry in concepts.entries) {
      await mount(entry.value(), const Size(390, 844), 1);
      await save(entry.key);
      files.add('${entry.key}.png');
    }
    for (final spec in [
      (const Size(320, 568), 1.0),
      (const Size(844, 390), 1.0),
      (const Size(375, 667), 2.0),
    ]) {
      for (final entry in concepts.entries) {
        await mount(entry.value(), spec.$1, spec.$2);
      }
      stdout.writeln('LAYOUT CHECKED ${spec.$1} text ${spec.$2}');
    }
    for (final board in [
      ('00a-first-day-basics', 'ELSŐ NAP · ALAPOK', [0, 1, 2, 3]),
      ('00b-first-expedition-and-night', 'ÚT ÉS ELSŐ ÉJSZAKA', [4, 5, 6, 7]),
    ]) {
      await mount(
        Scaffold(
          backgroundColor: const Color(0xFF102A28),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: u.column([
              u.label('LOST CANOPY · ${board.$2}', size: 20, color: u.cream),
              u.gap(6),
              u.label(
                'PERGAMENTES LÁTVÁNYTERV · MINTAADATOK · MÉG NINCS BEKÖTVE',
                size: 11,
                color: u.cream,
              ),
              u.gap(16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final i in board.$3)
                    SizedBox(
                      width: 216,
                      child: u.column([
                        SizedBox(
                          height: 28,
                          child: u.label(
                            files[i]
                                .replaceAll('.png', '')
                                .replaceAll('-', ' '),
                            size: 10,
                            color: u.cream,
                          ),
                        ),
                        Image.file(
                          File('$folder/${files[i]}'),
                          width: 216,
                          height: 216 * 844 / 390,
                          cacheWidth: 432,
                        ),
                      ]),
                    ),
                ],
              ),
            ]),
          ),
        ),
        const Size(720, 1120),
        1,
      );
      await save(board.$1, ratio: 2);
    }
    File('$folder/manifest.txt').writeAsStringSync('${files.join('\n')}\n');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}
