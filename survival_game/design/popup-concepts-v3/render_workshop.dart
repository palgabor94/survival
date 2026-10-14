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
    for (final light in [false]) {
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
        'design/popup-concepts-v3/02-workshop-B.png',
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
          top: 24,
          left: 22,
          right: 22,
          child: Row(
            children: [
              text('02 / WORKSHOP', 12, color: gold),
              const Spacer(),
              text('B · FOREST COMPACT', 10, color: const Color(0xFFB6C0AA)),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 354,
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
                            text(
                              'TOOLS & CAMP EQUIPMENT',
                              9,
                              color: const Color(0xFFB8C7A7),
                            ),
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
                          for (final label in ['ALL', 'TOOLS', 'CAMP'])
                            Expanded(
                              child: Container(
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: label == 'ALL'
                                      ? const Color(0xFFBBD987)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: text(
                                  label,
                                  10,
                                  color: label == 'ALL'
                                      ? ink
                                      : const Color(0xFFB0BEAB),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: card(
                              'torch',
                              'TORCH',
                              '2 materials',
                              'READY',
                              false,
                              false,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: card(
                              'stone_axe',
                              'STONE\nAXE',
                              '3 materials',
                              'READY',
                              true,
                              false,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: card(
                              'rain_collector',
                              'RAIN\nCOLLECTOR',
                              '2 materials',
                              'MISSING',
                              false,
                              true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF253F32),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const CardArt('stone_axe', size: 34),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: text(
                                    'STONE AXE',
                                    14,
                                    weight: FontWeight.w900,
                                  ),
                                ),
                                text('TOOL', 9, color: const Color(0xFFB0BEAB)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            text(
                              'Chop fallen trees for extra wood.',
                              11,
                              weight: FontWeight.w500,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(
                                height: 1,
                                color: Color(0xFF486047),
                              ),
                            ),
                            Row(
                              children: [
                                text(
                                  'MATERIALS',
                                  9,
                                  color: const Color(0xFFB0BEAB),
                                ),
                                const Spacer(),
                                text(
                                  'HAVE / NEED',
                                  9,
                                  color: const Color(0xFFB0BEAB),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            for (final cost in [
                              ('wood', 'Wood', '3 / 2'),
                              ('stone', 'Stone', '1 / 1'),
                              ('fiber', 'Fiber', '3 / 2'),
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    CardArt(cost.$1, size: 22),
                                    const SizedBox(width: 8),
                                    text(cost.$2, 12),
                                    const Spacer(),
                                    text(
                                      cost.$3,
                                      12,
                                      color: const Color(0xFFBBD987),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Color(0xFFBBD987),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBBD987),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.handyman_rounded,
                              size: 17,
                              color: ink,
                            ),
                            const SizedBox(width: 8),
                            text(
                              'CRAFT',
                              12,
                              color: ink,
                              weight: FontWeight.w900,
                            ),
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: ink,
                            ),
                            const SizedBox(width: 4),
                            text('1 TIME', 11, color: ink),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          left: 24,
          right: 24,
          child: Text(
            'EQUAL CARDS  ·  COSTS IN THE DETAIL PANEL',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFBDCBB1),
              fontSize: 10,
              letterSpacing: .7,
            ),
          ),
        ),
      ],
    ),
  );
  Widget card(
    String art,
    String title,
    String info,
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
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: ink,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: cream,
                height: 1.15,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 22,
          child: Center(
            child: text(
              info,
              9,
              color: const Color(0xFFB0BEAB),
              weight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
          child: Container(
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: missing
                  ? const Color(0xFF563B2E)
                  : const Color(0xFF193127),
              borderRadius: BorderRadius.circular(5),
            ),
            child: text(
              status,
              9,
              color: missing
                  ? const Color(0xFFF8B168)
                  : const Color(0xFFBBD987),
            ),
          ),
        ),
      ],
    ),
  );
}
