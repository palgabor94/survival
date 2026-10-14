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
        'design/popup-concepts-v3/04-menu-B.png',
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
  static const muted = Color(0xFFB0BEAB);
  static const leaf = Color(0xFFBBD987);
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
        Image.asset('assets/art/camp_tier_0_empty_v1.jpg', fit: BoxFit.cover),
        const ColoredBox(color: Color(0xBC071D19)),
        Positioned(
          top: 24,
          left: 22,
          right: 22,
          child: Row(
            children: [
              text('04 / CAMP MENU', 12, color: gold),
              const Spacer(),
              text('B · FOREST COMPACT', 10, color: muted),
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
                            text('CAMP MENU', 19, weight: FontWeight.w900),
                            const SizedBox(height: 2),
                            text('YOUR JOURNEY & SETTINGS', 9, color: muted),
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
                      text('AROUND CAMP', 9, color: muted),
                      const SizedBox(height: 8),
                      panel(
                        Column(
                          children: [
                            nav('forage', 'Gather around camp'),
                            line(),
                            nav('journal', 'Survival journal'),
                            line(),
                            nav('map', 'How to survive'),
                            line(),
                            nav('emergency_beacon', 'Rescue signal'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      text('SOUND & FEEDBACK', 9, color: muted),
                      const SizedBox(height: 8),
                      panel(
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              audio(Icons.music_note_rounded, 'Music', .65),
                              line(),
                              audio(
                                Icons.volume_up_rounded,
                                'Sound effects',
                                .8,
                              ),
                              line(),
                              SizedBox(
                                height: 46,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.vibration_rounded,
                                      size: 20,
                                      color: muted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: text('Haptic feedback', 12),
                                    ),
                                    toggle(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8B7052)),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.restart_alt_rounded,
                              size: 22,
                              color: gold,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: text('Start a new run', 12, color: gold),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: gold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 13,
                            color: muted,
                          ),
                          const SizedBox(width: 5),
                          text(
                            'Progress saves automatically',
                            10,
                            color: muted,
                            weight: FontWeight.w500,
                          ),
                        ],
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
            'COMPACT NAVIGATION  ·  CLEAR SETTINGS  ·  X TO CLOSE',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFBDCBB1),
              fontSize: 9,
              letterSpacing: .5,
            ),
          ),
        ),
      ],
    ),
  );
  Widget panel(Widget child) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF253F32),
      borderRadius: BorderRadius.circular(9),
    ),
    child: child,
  );
  Widget line() => const Divider(
    height: 1,
    indent: 12,
    endIndent: 12,
    color: Color(0xFF3C5540),
  );
  Widget nav(String art, String name) => SizedBox(
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          CardArt(art, size: 30),
          const SizedBox(width: 10),
          Expanded(child: text(name, 13)),
          const Icon(Icons.chevron_right_rounded, size: 20, color: muted),
        ],
      ),
    ),
  );
  Widget toggle() => SizedBox(
    width: 44,
    height: 44,
    child: Center(
      child: Container(
        width: 34,
        height: 20,
        padding: const EdgeInsets.all(3),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: leaf,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
        ),
      ),
    ),
  );
  Widget audio(IconData icon, String name, double value) => Column(
    children: [
      SizedBox(
        height: 38,
        child: Row(
          children: [
            Icon(icon, size: 20, color: muted),
            const SizedBox(width: 10),
            Expanded(child: text(name, 12)),
            text('${(value * 100).round()}%', 10, color: muted),
            const SizedBox(width: 6),
            toggle(),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 22, bottom: 6),
        child: SizedBox(
          height: 24,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: leaf,
              inactiveTrackColor: Color(0xFF435C46),
              thumbColor: cream,
            ),
            child: Slider(value: value, onChanged: (_) {}),
          ),
        ),
      ),
    ],
  );
}
