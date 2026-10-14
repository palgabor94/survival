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
    for (final light in [true, false]) {
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
        'design/popup-concepts-v3/${light ? 'A-field-journal' : 'B-forest-compact'}.png',
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
  Widget label(
    String value,
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => Text(
    value,
    style: TextStyle(
      fontSize: size,
      color: color ?? (light ? ink : cream),
      fontWeight: weight,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final columns = light ? 2 : 3;
    return Scaffold(
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
                Text(
                  light ? 'A / FIELD JOURNAL' : 'B / FOREST COMPACT',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                const Text(
                  'UI CONCEPT',
                  style: TextStyle(
                    color: Color(0xFFB6C0AA),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 354,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: light ? parchment : const Color(0xFF182F28),
                borderRadius: BorderRadius.circular(light ? 18 : 14),
                border: Border.all(
                  color: light
                      ? const Color(0xFFCBB884)
                      : const Color(0xFF718C64),
                  width: 1.5,
                ),
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
                        const CardArt('inventory', size: 36),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAMP ITEMS',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: cream,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'SUPPLIES & EQUIPMENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.4,
                                  color: Color(0xFFB8C7A7),
                                ),
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
                            for (final text in ['MATERIALS', 'FOOD', 'GEAR'])
                              Expanded(
                                child: Container(
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: text == 'MATERIALS'
                                        ? (light
                                              ? ink
                                              : const Color(0xFFBBD987))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: label(
                                    text,
                                    10,
                                    color: text == 'MATERIALS'
                                        ? (light ? cream : ink)
                                        : (light
                                              ? const Color(0xFF657062)
                                              : const Color(0xFFB0BEAB)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width =
                                (constraints.maxWidth - (columns - 1) * 10) /
                                columns;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final item in [
                                  ('firewood', 'WOOD', '3'),
                                  ('stone', 'STONE', '3'),
                                  ('fiber', 'FIBER', '6'),
                                  ('bait', 'BAIT', '2'),
                                ])
                                  SizedBox(
                                    width: width,
                                    child: itemCard(
                                      item.$1,
                                      item.$2,
                                      item.$3,
                                      item.$1 == 'firewood',
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: light
                                ? const Color(0xFFD9CDAB)
                                : const Color(0xFF253F32),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CardArt('wood', size: 34),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        label('WOOD', 13),
                                        const Spacer(),
                                        label(
                                          '3 available',
                                          10,
                                          weight: FontWeight.w500,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    label(
                                      'Building material for tools\nand shelter upgrades.',
                                      11,
                                      weight: FontWeight.w500,
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
                            color: light ? ink : const Color(0xFFBBD987),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.handyman_rounded,
                                size: 17,
                                color: light ? cream : ink,
                              ),
                              const SizedBox(width: 8),
                              label(
                                'OPEN WORKSHOP',
                                12,
                                color: light ? cream : ink,
                              ),
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
              light
                  ? '2 COLUMNS  ·  WARM PAPER  ·  LARGER ART'
                  : '3 COLUMNS  ·  COMPACT CARDS  ·  MORE VISIBLE',
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
  }

  Widget itemCard(String art, String title, String count, bool selected) =>
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: light ? const Color(0xFFF4EBD4) : const Color(0xFF294537),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? (light ? const Color(0xFF687A42) : gold)
                : (light ? const Color(0xFFC7BE9F) : const Color(0xFF527149)),
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
              height: 34,
              child: Center(child: label(title, light ? 13 : 11)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
              child: Container(
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: light
                      ? const Color(0xFFE4D9BC)
                      : const Color(0xFF193127),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: label('× $count', 12),
              ),
            ),
          ],
        ),
      );
}
