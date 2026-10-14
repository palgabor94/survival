import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import '../../screenshots/tools/capture_fonts.dart';

final mapImage = FileImage(
  File('design/map-on-scene-concept-v1/jungle-map-background-v1.png'),
);
const destinations = [
  ('bamboo', 'Bamboo Grove', .21, .235, false, 2, 'fiber'),
  ('pond', 'Fishing Pond', .78, .26, false, 2, 'basic_rod'),
  ('river', 'Riverbank', .49, .408, false, 2, 'water'),
  ('camp', 'Camp', .23, .55, false, 0, 'shelter'),
  ('wreck', 'Plane Wreck', .78, .55, false, 3, 'radio_module'),
  ('ruins', 'Ancient Ruins', .76, .765, true, 3, 'beacon_core'),
  ('mangrove', 'Mangrove', .23, .875, false, 2, 'bait'),
];
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
          home: const MapConcept(),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(
      () => Future.wait([
        precacheImage(mapImage, context),
        precacheImage(
          const AssetImage('assets/art/ui_parchment_texture.png'),
          context,
        ),
      ]),
    );
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
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
      if (error != null) throw StateError('$error');
      final im =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 3);
      final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
      File(
        'design/map-on-scene-concept-v1/$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      im.dispose();
      stdout.writeln('CAPTURED $name');
    }

    await shot('01-map-overview');
    await tester.tap(find.byKey(const ValueKey('pin-river')));
    await shot('02-riverbank-selected');
    await tester.tap(find.byKey(const ValueKey('pin-ruins')));
    await shot('03-ruins-locked');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  timer.cancel();
  exit(0);
}

class MapConcept extends StatefulWidget {
  const MapConcept({super.key});
  @override
  State<MapConcept> createState() => _MapConceptState();
}

class _MapConceptState extends State<MapConcept> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final place = destinations.where((p) => p.$1 == selected).firstOrNull;
    return Scaffold(
      backgroundColor: const Color(0xFF102A28),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            final mapHeight = width * 1.5;
            const top = 82.0;
            return Stack(
              children: [
                Positioned(
                  top: top,
                  left: 0,
                  right: 0,
                  height: mapHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image(image: mapImage, fit: BoxFit.contain),
                      ),
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF102A28),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Color(0xFF102A28),
                                ],
                                stops: [0, .025, .975, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (place != null)
                        Positioned(
                          left: place.$3 * width - 38,
                          top: place.$4 * mapHeight - 45,
                          width: 76,
                          height: 38,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: place.$5
                                      ? const Color(0xFFE8D9AF)
                                      : const Color(0xFFB6D78A),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      for (final p in destinations)
                        Positioned(
                          left: (p.$3 * width - 59).clamp(2, width - 120),
                          top: p.$4 * mapHeight - 2,
                          width: 118,
                          height: 44,
                          child: Semantics(
                            button: true,
                            selected: p.$1 == selected,
                            label: p.$2,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: ValueKey('pin-${p.$1}'),
                                onTap: () => setState(() => selected = p.$1),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.$1 == selected
                                          ? ParchmentColors.leaf
                                          : const Color(0xF0EFE0BA),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: p.$1 == selected
                                            ? const Color(0xFFB6D78A)
                                            : const Color(0xFFB7A981),
                                        width: 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x60000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (p.$5) ...[
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 11,
                                            color: p.$1 == selected
                                                ? ParchmentColors.cream
                                                : ParchmentColors.muted,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        if (p.$1 == 'camp') ...[
                                          Icon(
                                            Icons.home_rounded,
                                            size: 12,
                                            color: p.$1 == selected
                                                ? ParchmentColors.cream
                                                : ParchmentColors.leaf,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Flexible(
                                          child: ParchmentLabel(
                                            p.$2,
                                            size: 10,
                                            color: p.$1 == selected
                                                ? ParchmentColors.cream
                                                : ParchmentColors.ink,
                                            align: TextAlign.center,
                                          ),
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
                ),
                Positioned(
                  top: 18,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      PaperSurface(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.explore_outlined,
                                size: 22,
                                color: ParchmentColors.leaf,
                              ),
                              const SizedBox(width: 7),
                              const ParchmentLabel('EXPLORE', size: 18),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      PaperSurface(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Column(
                            children: [
                              const ParchmentLabel('DAY 4', size: 11),
                              const ParchmentLabel(
                                '4/6 time',
                                size: 10,
                                color: ParchmentColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PaperSurface(
                        child: IconButton(
                          tooltip: 'Close map',
                          onPressed: () {},
                          icon: const Icon(
                            Icons.close_rounded,
                            color: ParchmentColors.ink,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 18,
                  child: place == null
                      ? PaperSurface(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.touch_app_outlined,
                                  size: 22,
                                  color: ParchmentColors.leaf,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: ParchmentLabel(
                                    'Tap a place on the map.',
                                    size: 13,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : PaperSurface(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    CardArt(place.$7, size: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ParchmentLabel(
                                        place.$2.toUpperCase(),
                                        size: 17,
                                      ),
                                    ),
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: ParchmentColors.leaf,
                                      size: 21,
                                    ),
                                  ],
                                ),
                                if (place.$5) ...[
                                  const SizedBox(height: 7),
                                  const ParchmentLabel(
                                    'Established Camp and a Machete required.',
                                    size: 12,
                                    color: ParchmentColors.rust,
                                    weight: FontWeight.w500,
                                  ),
                                ],
                                const SizedBox(height: 9),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    cost('time', '${place.$6} time'),
                                    cost('water', '−${place.$6 * 4} water'),
                                    cost('food', '−${place.$6 * 3} food'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                parchmentButton(
                                  place.$5
                                      ? 'LOCATION LOCKED'
                                      : 'TRAVEL TO ${place.$2.toUpperCase()}',
                                  place.$5 ? null : () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget cost(String id, String label) => Row(
    children: [
      if (id == 'time')
        const Icon(Icons.schedule_rounded, size: 18, color: ParchmentColors.ink)
      else
        CardArt(id, size: 18),
      const SizedBox(width: 4),
      ParchmentLabel(label, size: 11),
    ],
  );
}
