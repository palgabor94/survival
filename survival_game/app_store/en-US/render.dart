import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/main_menu_screen.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import '../../screenshots/tools/capture_fonts.dart';
import 'iphone_mockup.dart';

const root = 'app_store/en-US';
const slides = <(String, String, String)>[
  (
    '01-survive',
    'Survive the\nJungle',
    'Manage your supplies.\nMake every day count.',
  ),
  (
    '02-explore',
    'Explore the\nUnknown',
    'Choose your route.\nBring your supplies home.',
  ),
  (
    '03-craft',
    'Craft Your\nWay Forward',
    'Make useful tools.\nBuild a stronger refuge.',
  ),
  (
    '04-face-the-wild',
    'Face the\nWild',
    'Meet the jungle’s dangers.\nChoose how you respond.',
  ),
  (
    '05-fishing',
    'Master the\nCatch',
    'Time the hook.\nKeep the fish in the green.',
  ),
  (
    '06-rescue',
    'Build Your\nEscape',
    'Recover the missing parts.\nSend a signal for rescue.',
  ),
];
Widget poster(int index) {
  final slide = slides[index];
  return Scaffold(
    backgroundColor: CanopyColors.background,
    body: MenuBackdrop(
      asset: menuBackgrounds[index % 3],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 25, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              slide.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: menuCream,
                fontSize: 39,
                height: 1.03,
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slide.$3,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: menuCream,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Center(
                child: IPhoneMockup(
                  screenshot: File('$root/raw/${slide.$1}.png'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SURVIVE. ADAPT. FIND YOUR WAY HOME.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.5,
                color: menuCream,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  Directory('.dart_tool/app-store-export').createSync(recursive: true);
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final key = GlobalKey();
    Future<void> mount(Widget page, Size size) async {
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
            home: page,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() async {
        for (final provider
            in find
                .byType(Image)
                .evaluate()
                .map((e) => (e.widget as Image).image)
                .toSet()) {
          await precacheImage(provider, context);
        }
      });
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$size: $error');
    }

    Future<void> save(String name, {double ratio = 3}) async {
      final img =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: ratio);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
        '.dart_tool/app-store-export/$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      img.dispose();
      stdout.writeln('RENDERED $name');
    }

    for (final (folder, size) in [
      ('iphone-large', const Size(440, 956)),
      ('iphone-medium', const Size(402, 874)),
    ]) {
      for (var i = 0; i < slides.length; i++) {
        await mount(poster(i), size);
        await save('${folder}__${slides[i].$1}');
      }
    }
    await mount(
      Scaffold(
        backgroundColor: CanopyColors.background,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'LOST CANOPY · APP STORE · ENGLISH',
                style: TextStyle(
                  color: menuCream,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final slide in slides)
                    SizedBox(
                      width: 212,
                      child: Image.file(
                        File(
                          '.dart_tool/app-store-export/iphone-large__${slide.$1}.png',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      const Size(708, 1040),
    );
    final img =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$root/00-overview.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    img.dispose();
    await tester.pumpWidget(const SizedBox());
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}
