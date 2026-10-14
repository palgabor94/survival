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
        'design/popup-concepts-v3/03-outcome-B.png',
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
      height: 1.35,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/art/camp_tier_0_empty_v1.jpg', fit: BoxFit.cover),
        const ColoredBox(color: Color(0xBC071D19)),
        Positioned(
          top: 24,
          left: 22,
          right: 22,
          child: Row(
            children: [
              text('03 / OUTCOME', 12, color: gold),
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
                      const CardArt('journal', size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text(
                              'FORAGING COMPLETE',
                              17,
                              weight: FontWeight.w900,
                            ),
                            const SizedBox(height: 2),
                            text(
                              'WHAT HAPPENED',
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.asset(
                              'assets/art/card_forage_scene_v1.png',
                              width: 84,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text(
                                  'Familiar berries',
                                  15,
                                  weight: FontWeight.w900,
                                ),
                                const SizedBox(height: 3),
                                text(
                                  'Picked around camp',
                                  11,
                                  color: const Color(0xFFB0BEAB),
                                  weight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      text(
                        'You eat the ripe berries and keep a handful of useful fibers.',
                        13,
                        weight: FontWeight.w500,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          text(
                            'TOTAL CHANGES',
                            9,
                            color: const Color(0xFFB0BEAB),
                          ),
                          const Spacer(),
                          text(
                            'BEFORE → AFTER',
                            9,
                            color: const Color(0xFFB0BEAB),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF253F32),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Column(
                          children: [
                            change('food', 'Food', '+17', '75 → 92', true),
                            const Divider(height: 1, color: Color(0xFF3C5540)),
                            change('fiber', 'Fiber', '+1', '6 → 7', true),
                            const Divider(height: 1, color: Color(0xFF3C5540)),
                            change('water', 'Water', '−4', '80 → 76', false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: gold,
                          ),
                          const SizedBox(width: 6),
                          text(
                            '1 time spent',
                            11,
                            color: const Color(0xFFB0BEAB),
                            weight: FontWeight.w500,
                          ),
                          const Spacer(),
                          text('5/6 remaining', 11, color: gold),
                        ],
                      ),
                      const SizedBox(height: 6),
                      text(
                        'Includes food and water used while foraging.',
                        10,
                        color: const Color(0xFFB0BEAB),
                        weight: FontWeight.w500,
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
            'CLEAR RESULTS  ·  COMPACT ROWS  ·  CLOSE WITH X',
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
  Widget change(
    String art,
    String name,
    String amount,
    String total,
    bool positive,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CardArt(art, size: 30),
        const SizedBox(width: 10),
        Expanded(child: text(name, 13)),
        text(
          amount,
          18,
          color: positive ? const Color(0xFFBBD987) : const Color(0xFFF8B168),
          weight: FontWeight.w900,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 58,
          child: Text(
            total,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: Color(0xFFB0BEAB)),
          ),
        ),
      ],
    ),
  );
}
