import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/parchment_components.dart';

import '../../screenshots/tools/capture_fonts.dart';

Future<void> main() async {
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    await binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: canopyTheme,
          debugShowCheckedModeBanner: false,
          home: const DayEndConcept(),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(
      () => Future.wait([
        precacheImage(
          const AssetImage('assets/art/camp_tier_0_empty_v1.jpg'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/art/ui_parchment_texture.png'),
          context,
        ),
      ]),
    );
    await tester.pumpAndSettle();
    final error = tester.takeException();
    if (error != null) throw StateError('$error');
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(
      'design/day-end-concept-v1/01-day-survived.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  timer.cancel();
  exit(0);
}

class DayEndConcept extends StatelessWidget {
  const DayEndConcept({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D2225),
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/art/camp_tier_0_empty_v1.jpg',
            fit: BoxFit.fitWidth,
            alignment: Alignment.center,
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Color(0xB8071A1E))),
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: PaperSurface(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(17, 15, 17, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const CardArt('moon', size: 50),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ParchmentLabel(
                                    'END OF DAY',
                                    size: 11,
                                    color: ParchmentColors.muted,
                                  ),
                                  ParchmentLabel('DAY 3 SURVIVED', size: 21),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Another night in the canopy. You are still here.',
                          style: TextStyle(fontSize: 12, height: 1.3),
                        ),
                        const Divider(height: 22),
                        const ParchmentLabel(
                          'TODAY',
                          size: 11,
                          color: ParchmentColors.muted,
                        ),
                        const SizedBox(height: 5),
                            const _ProgressLine('stone_axe', 'Crafted Stone Axe'),
                        const _ProgressLine('water', 'Reached Riverbank'),
                        const _ProgressLine('wood', 'Gathered 2 Wood'),
                        const SizedBox(height: 12),
                        const ParchmentLabel(
                          'GOING INTO DAY 4',
                          size: 11,
                          color: ParchmentColors.muted,
                        ),
                        const SizedBox(height: 7),
                        const Row(
                          children: [
                            Expanded(
                              child: _StatCell('health', '100', 'HEALTH'),
                            ),
                            SizedBox(width: 6),
                            Expanded(child: _StatCell('water', '68', 'WATER')),
                            SizedBox(width: 6),
                            Expanded(child: _StatCell('food', '66', 'FOOD')),
                            SizedBox(width: 6),
                            Expanded(
                              child: _StatCell('sanity', '80', 'SANITY'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        const Divider(height: 1),
                        const SizedBox(height: 11),
                        const Row(
                          children: [
                            CardArt('shelter', size: 29),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ParchmentLabel(
                                    'TOMORROW',
                                    size: 10,
                                    color: ParchmentColors.muted,
                                  ),
                                  ParchmentLabel(
                                    'Build Basic Refuge',
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: parchmentButton('NEXT DAY  →', () {}),
                        ),
                      ],
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
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine(this.art, this.text);
  final String art, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: ParchmentColors.leaf, size: 17),
        const SizedBox(width: 7),
        CardArt(art, size: 20),
        const SizedBox(width: 7),
        Expanded(child: ParchmentLabel(text, size: 12)),
      ],
    ),
  );
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.art, this.value, this.label);
  final String art, value, label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
    decoration: BoxDecoration(
      color: const Color(0x55E0D3AF),
      border: Border.all(color: const Color(0xFFBAA981)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Column(
      children: [
        CardArt(art, size: 24),
        ParchmentLabel(value, size: 15),
        ParchmentLabel(label, size: 8, color: ParchmentColors.muted),
      ],
    ),
  );
}
