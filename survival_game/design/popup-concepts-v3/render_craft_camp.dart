import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import '../../screenshots/tools/capture_fonts.dart';

const ink = Color(0xFF203B31);
const parchment = Color(0xFFE8DDC0);
const gold = Color(0xFFF0C773);
const cream = Color(0xFFFFF0CC);

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    await binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    for (final light in [false, true]) {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: canopyTheme,
            home: Concept(light: light),
          ),
        ),
      );
      await tester.pump();
      final pictures = find
          .byType(Image)
          .evaluate()
          .map((e) => (e.widget as Image).image)
          .toSet();
      final context = tester.element(find.byType(Scaffold));
      var ready = false;
      final loading = Future.wait(
        pictures.map((p) => precacheImage(p, context)),
      ).then((_) => ready = true);
      for (var i = 0; i < 300 && !ready; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      if (!ready) throw StateError('Assets did not load');
      await loading;
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$error');
      final shot =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 3);
      final data = await shot.toByteData(format: ui.ImageByteFormat.png);
      File(
        'design/popup-concepts-v3/${light ? '06-camp-upgrade-B' : '05-craft-menu-B'}.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      shot.dispose();
      stdout.writeln('CAPTURED ${light ? 'A' : 'B'}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}

class Concept extends StatelessWidget {
  const Concept({super.key, required this.light});
  final bool light;
  bool get camp => light;
  static const muted = Color(0xFFB0BEAB),
      leaf = Color(0xFFBBD987),
      panel = Color(0xFF253F32);
  Widget text(
    String s,
    double size, {
    Color color = cream,
    FontWeight weight = FontWeight.w700,
  }) => Text(
    s,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.25,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/art/camp_tier_1_empty_v1.jpg', fit: BoxFit.cover),
        const ColoredBox(color: Color(0xBC071D19)),
        Positioned(
          top: 20,
          left: 22,
          right: 22,
          child: Row(
            children: [
              text(
                camp ? '06 / CAMP UPGRADES' : '05 / CRAFT MENU',
                12,
                color: gold,
              ),
              const Spacer(),
              text('B · FOREST COMPACT', 9, color: muted),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 366,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF182F28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF718C64), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 30,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: const Color(0xFF213C31),
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      const CardArt('craft', size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text('WORKSHOP', 19, weight: FontWeight.w900),
                            const SizedBox(height: 2),
                            text('BASIC REFUGE · 4/6 TIME', 9, color: muted),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.close_rounded, color: gold),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          for (final tab in ['CRAFT', 'CAMP'])
                            Expanded(
                              child: Container(
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: (camp ? tab == 'CAMP' : tab == 'CRAFT')
                                      ? leaf
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: text(
                                  tab,
                                  11,
                                  color: (camp ? tab == 'CAMP' : tab == 'CRAFT')
                                      ? ink
                                      : muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (camp) ...campContents() else ...craftContents(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 18,
          left: 20,
          right: 20,
          child: Text(
            camp
                ? 'CLEAR PROGRESSION · PREVIEW · EXACT REQUIREMENTS'
                : 'FIXED CARD SLOTS · SELECT TO SEE COSTS',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFBDCBB1),
              fontSize: 9,
              letterSpacing: .4,
            ),
          ),
        ),
      ],
    ),
  );
  List<Widget> craftContents() => [
    Row(
      children: [
        text('TOOLS', 9, color: muted),
        const Spacer(),
        text('6 RECIPES', 9, color: muted),
      ],
    ),
    const SizedBox(height: 8),
    for (final row in [0, 1]) ...[
      if (row == 1) const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: recipe(row * 3 + i)),
          ],
        ],
      ),
    ],
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CardArt('stone_axe', size: 28),
              const SizedBox(width: 8),
              text('STONE AXE', 14, weight: FontWeight.w900),
              const Spacer(),
              text('TOOL', 9, color: muted),
            ],
          ),
          const SizedBox(height: 5),
          text(
            'Chop fallen trees for extra wood.',
            11,
            weight: FontWeight.w500,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              text('MATERIALS', 9, color: muted),
              const Spacer(),
              text('HAVE / NEED', 9, color: muted),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final r in [
                ('wood', '3 / 2'),
                ('stone', '1 / 1'),
                ('fiber', '3 / 2'),
              ])
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CardArt(r.$1, size: 22),
                      const SizedBox(width: 5),
                      text(r.$2, 11, color: leaf),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    button('CRAFT STONE AXE', '1 TIME', true),
  ];
  Widget recipe(int index) {
    const data = [
      ('torch', 'TORCH', 'READY'),
      ('stone_axe', 'STONE AXE', 'READY'),
      ('basic_rod', 'BASIC ROD', 'READY'),
      ('stone_knife', 'STONE KNIFE', 'OWNED'),
      ('stone_spear', 'STONE SPEAR', 'READY'),
      ('machete', 'MACHETE', 'MISSING'),
    ];
    final r = data[index];
    return card(r.$1, r.$2, r.$3, index == 1, r.$3 == 'MISSING');
  }

  List<Widget> campContents() => [
    Row(
      children: [
        text('SHELTER PROGRESSION', 9, color: muted),
        const Spacer(),
        text('TIER 1 OF 3', 9, color: muted),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: card('camp_tier_1', 'BASIC REFUGE', 'CURRENT', false, false),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: card(
            'camp_tier_2',
            'ESTABLISHED CAMP',
            'UPGRADE',
            true,
            false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: card('camp_tier_3', 'RESCUE BASE', 'LOCKED', false, true),
        ),
      ],
    ),
    const SizedBox(height: 12),
    ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: 104,
        child: Image.asset(
          'assets/art/camp_tier_2_empty_v1.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, .13),
        ),
      ),
    ),
    const SizedBox(height: 10),
    text('ESTABLISHED CAMP', 15, weight: FontWeight.w900),
    const SizedBox(height: 4),
    text('+6 water each dawn · Better sleep', 11, color: leaf),
    const SizedBox(height: 3),
    text(
      'Opens the way to the Ancient Ruins.',
      11,
      color: muted,
      weight: FontWeight.w500,
    ),
    const SizedBox(height: 10),
    Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              text('BUILD REQUIREMENTS', 9, color: muted),
              const Spacer(),
              text('HAVE / NEED', 9, color: muted),
            ],
          ),
          const SizedBox(height: 5),
          for (final r in [
            ('wood', 'Wood', '10 / 12', false),
            ('hardwood', 'Hardwood', '4 / 4', true),
            ('fiber', 'Fiber', '8 / 8', true),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CardArt(r.$1, size: 21),
                  const SizedBox(width: 8),
                  Expanded(child: text(r.$2, 11)),
                  text(r.$3, 11, color: r.$4 ? leaf : const Color(0xFFF8B168)),
                  const SizedBox(width: 8),
                  Icon(
                    r.$4 ? Icons.check_rounded : Icons.remove_rounded,
                    size: 14,
                    color: r.$4 ? leaf : const Color(0xFFF8B168),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    button('NEED 2 MORE WOOD', '2 TIME', false),
  ];
  Widget button(String title, String time, bool enabled) => Container(
    height: 44,
    decoration: BoxDecoration(
      color: enabled ? leaf : panel,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        text(title, 11, color: enabled ? ink : muted, weight: FontWeight.w900),
        const SizedBox(width: 12),
        Icon(Icons.schedule_rounded, size: 14, color: enabled ? ink : muted),
        const SizedBox(width: 4),
        text(time, 10, color: enabled ? ink : muted),
      ],
    ),
  );
  Widget card(
    String art,
    String title,
    String status,
    bool selected,
    bool missing,
  ) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF294537),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: selected ? gold : const Color(0xFF527149),
        width: 2,
      ),
    ),
    child: Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/art/card_${art}_scene_v1.png',
                fit: BoxFit.cover,
              ),
              if (selected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: ink,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 34,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: cream,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: Container(
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: missing
                  ? const Color(0xFF563B2E)
                  : const Color(0xFF193127),
              borderRadius: BorderRadius.circular(5),
            ),
            child: text(
              status,
              8,
              color: missing ? const Color(0xFFF8B168) : leaf,
            ),
          ),
        ),
      ],
    ),
  );
}
