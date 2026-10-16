import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/card_art.dart';
import '../../screenshots/tools/capture_fonts.dart';

const folder = 'design/splash-menu-v2';
const cream = Color(0xFFFFEAC0);
Widget titleMark({bool compact = false}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      'LOST',
      style: TextStyle(
        fontSize: compact ? 44 : 60,
        height: .92,
        fontWeight: FontWeight.w900,
        letterSpacing: 9,
        color: cream,
        shadows: const [
          Shadow(
            color: Color(0xDD081D17),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
    ),
    Text(
      'CANOPY',
      style: TextStyle(
        fontSize: compact ? 45 : 59,
        height: 1.05,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        color: const Color(0xFFE6BA69),
        shadows: const [
          Shadow(
            color: Color(0xDD081D17),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    Container(height: 1, width: 150, color: const Color(0x88E6BA69)),
    const SizedBox(height: 10),
    const Text(
      'SURVIVE. ADAPT. FIND YOUR WAY HOME.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 1.7,
        color: cream,
        fontWeight: FontWeight.w700,
      ),
    ),
  ],
);
Widget background(Widget child, {bool splashArt = false}) => Scaffold(
  backgroundColor: const Color(0xFF102A28),
  body: Stack(
    fit: StackFit.expand,
    children: [
      Center(
        child: Image.file(
          File(
            splashArt
                ? 'design/splash-menu-v2/art/splash_jungle_v1.png'
                : 'design/splash-menu-v2/art/main_menu_camp_v1.png',
          ),
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, .22, .47, .7, 1],
            colors: [
              Color(0xF0102A28),
              Color(0x66102A28),
              Colors.transparent,
              Color(0x66102A28),
              Color(0xFF102A28),
            ],
          ),
        ),
      ),
      SafeArea(child: child),
    ],
  ),
);
Widget smallLine(String a, String b) => Row(
  children: [
    Expanded(child: ParchmentLabel(a, size: 11, weight: FontWeight.w500)),
    ParchmentLabel(b, size: 11),
  ],
);
Widget splash() => background(
  splashArt: true,
  LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleMark(),
              const SizedBox(height: 280),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'A WILDERNESS SURVIVAL JOURNEY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cream,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      value: .68,
                      minHeight: 3,
                      color: const Color(0xFFE6BA69),
                      backgroundColor: cream.withValues(alpha: .15),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Preparing your camp…',
                    style: TextStyle(color: cream, fontSize: 11),
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
Widget menu({bool saved = true}) => background(
  LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleMark(compact: true),
              const SizedBox(height: 240),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (saved) ...[
                    PaperSurface(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const CardArt('shelter', size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const ParchmentLabel(
                                    'YOUR JOURNEY',
                                    size: 10,
                                    color: ParchmentColors.muted,
                                  ),
                                  const SizedBox(height: 4),
                                  const ParchmentLabel(
                                    'Day 5 · Jungle Refuge',
                                    size: 15,
                                  ),
                                  const SizedBox(height: 5),
                                  smallLine(
                                    'Camp storage saved',
                                    'Ready to continue',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    parchmentButton('CONTINUE JOURNEY', () {}),
                    const SizedBox(height: 8),
                    parchmentButton('NEW JOURNEY', () {}, secondary: true),
                  ] else ...[
                    parchmentButton('BEGIN YOUR JOURNEY', () {}),
                    const SizedBox(height: 10),
                    const Text(
                      'Build a camp. Explore the jungle. Survive the night.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cream, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PaperSurface(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (icon, label) in [
                          (Icons.menu_book_rounded, 'SURVIVOR PROFILE'),
                          (Icons.tune_rounded, 'SETTINGS'),
                          (Icons.help_outline_rounded, 'HOW TO SURVIVE'),
                        ])
                          SizedBox(
                            height: 48,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: ParchmentColors.ink,
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'LOST CANOPY · SURVIVAL JOURNAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.3,
                      color: cream,
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

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  Directory(folder).createSync(recursive: true);
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final key = GlobalKey();
    Future<void> mount(Widget page, Size size, {double scale = 1}) async {
      await tester.pumpWidget(const SizedBox());
      await binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
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
            home: page,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() async {
        for (final img
            in find
                .byType(Image)
                .evaluate()
                .map((e) => (e.widget as Image).image)
                .toSet()) {
          await precacheImage(img, context);
        }
      });
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$size/$scale: $error');
    }

    Future<void> save(String name) async {
      final img =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 3);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$folder/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      img.dispose();
      stdout.writeln('RENDERED $name');
    }

    final pages = {
      '01-splash': splash,
      '02-main-menu-continue': () => menu(),
      '03-main-menu-first-launch': () => menu(saved: false),
    };
    for (final entry in pages.entries) {
      await mount(entry.value(), const Size(390, 844));
      await save(entry.key);
    }
    for (final spec in [
      (const Size(320, 568), 1.0),
      (const Size(844, 390), 1.0),
      (const Size(375, 667), 2.0),
    ]) {
      for (final page in pages.values) {
        await mount(page(), spec.$1, scale: spec.$2);
      }
      stdout.writeln('CHECKED ${spec.$1}/${spec.$2}');
    }
    await mount(
      Scaffold(
        backgroundColor: const Color(0xFF102A28),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'LOST CANOPY · SPLASH & MAIN MENU',
                style: TextStyle(
                  color: cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'LÁTVÁNYTERV · ÚJ GENERÁLT HÁTTEREK + PERGAMEN · MÉG NINCS BEKÖTVE',
                style: TextStyle(color: cream, fontSize: 11),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in pages.entries)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Image.file(File('$folder/${entry.key}.png')),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      const Size(1110, 875),
    );
    await save('00-overview');
    await tester.pumpWidget(const SizedBox());
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}
