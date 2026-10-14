import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:survival_game/ui/camp_character.dart';
import 'package:survival_game/ui/card_illustration.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import '../../screenshots/tools/capture_fonts.dart';

const ink = Color(0xFF203B31);
final paper = FileImage(File('design/parchment-ui-all-v1/paper-texture.png'));
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
    for (final spec
        in (jsonDecode(
              File(
                'design/parchment-ui-all-v1/manifest.json',
              ).readAsStringSync(),
            )
            as List)) {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: canopyTheme,
            home: Concept(spec: Map<String, dynamic>.from(spec)),
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
        [...pictures, paper].map((p) => precacheImage(p, context)),
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
        'design/parchment-ui-all-v1/${spec['id']}.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      shot.dispose();
      stdout.writeln('CAPTURED ${spec['id']}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}

class Concept extends StatelessWidget {
  const Concept({super.key, required this.spec});
  final Map<String, dynamic> spec;
  static const leaf = Color(0xFF294E36),
      muted = Color(0xFF68705A),
      rust = Color(0xFF8F4E37);
  Widget text(
    String s,
    double n, {
    Color color = ink,
    FontWeight weight = FontWeight.w700,
    TextAlign align = TextAlign.left,
  }) => Text(
    s,
    textAlign: align,
    style: TextStyle(
      fontSize: n,
      height: 1.28,
      color: color,
      fontWeight: weight,
    ),
  );
  Widget gap([double v = 10]) => SizedBox(height: v);
  Decoration decor({bool selected = false, bool border = true}) =>
      BoxDecoration(
        color: const Color(0xFFF1E2BD),
        image: DecorationImage(image: paper, fit: BoxFit.cover, opacity: .75),
        borderRadius: BorderRadius.circular(4),
        border: border
            ? Border.all(
                color: selected ? leaf : const Color(0xFFB7A981),
                width: selected ? 2 : 1,
              )
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      );
  Widget panel(Widget child, {double pad = 12}) => Container(
    decoration: decor(),
    padding: EdgeInsets.all(pad),
    child: child,
  );
  Widget button(String label, {bool secondary = false}) => Container(
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: secondary ? const Color(0xFFE6D6AE) : leaf,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: leaf),
    ),
    child: text(label, 11, color: secondary ? ink : cream),
  );
  Widget card(List data, int index) {
    final selected = index == (spec['selected'] ?? -1);
    final art = data[0] as String;
    final status = data[3] as String;
    final locked = ['LOCKED', 'MISSING'].contains(status);
    return Container(
      width: 112,
      height: 172,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1E2BD),
        image: DecorationImage(image: paper, fit: BoxFit.cover),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? leaf : const Color(0xFFB7A981),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: text(
                      data[1],
                      10,
                      weight: FontWeight.w900,
                      align: TextAlign.center,
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(Icons.check_circle, size: 12, color: leaf),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 108,
            height: 72,
            child: Image.asset(
              cardIllustrationFor(art) ?? 'assets/art/card_trail_scene_v1.png',
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            height: 22,
            child: Center(child: text(data[2], 9, color: muted)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 26,
            alignment: Alignment.center,
            color: locked ? rust : leaf,
            child: text(status, 9, color: cream),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget deck(List cards) => Column(
    children: [
      for (var start = 0; start < cards.length; start += 3) ...[
        if (start > 0) gap(8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (var i = start; i < cards.length && i < start + 3; i++) ...[
              if (i > start) const SizedBox(width: 8),
              card(cards[i], i),
            ],
          ],
        ),
      ],
    ],
  );
  Widget row(List data) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        CardArt(data[0], size: 23),
        const SizedBox(width: 8),
        Expanded(child: text(data[1], 11)),
        const SizedBox(width: 6),
        text(
          data[2],
          10,
          color: data[2].toString().startsWith('−') ? rust : leaf,
        ),
      ],
    ),
  );
  Widget costs(List rows) => Row(
    children: [
      for (final r in rows)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardArt(r[0], size: 22),
              const SizedBox(width: 5),
              text(r[2], 11),
            ],
          ),
        ),
    ],
  );
  Widget timing() => panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            text('FOLLOW THE MARKER', 9, color: muted),
            const Spacer(),
            text('GOOD / PERFECT', 9, color: leaf),
          ],
        ),
        gap(8),
        Container(
          height: 30,
          color: const Color(0xFF273B30),
          child: Stack(
            children: [
              Positioned(
                left: 104,
                width: 98,
                top: 3,
                bottom: 3,
                child: Container(color: const Color(0xFF91AF69)),
              ),
              Positioned(
                left: 140,
                width: 28,
                top: 3,
                bottom: 3,
                child: Container(color: const Color(0xFFCBD7A3)),
              ),
              Positioned(
                left: 150,
                width: 4,
                top: 0,
                bottom: 0,
                child: Container(color: cream),
              ),
            ],
          ),
        ),
        gap(6),
        text(
          (spec['id'].toString().contains('fishing'))
              ? '← RELEASE                         HOLD →'
              : 'TAP WHEN THE MARKER REACHES THE CENTER',
          10,
          color: muted,
        ),
      ],
    ),
  );
  Widget tabs() {
    final tab = spec['tab'] ?? '';
    final values = spec['view'] == 'items'
        ? ['MATERIALS', 'FOOD', 'GEAR']
        : ['CRAFT', 'CAMP'];
    return Row(
      children: [
        for (final value in values)
          Expanded(
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tab == value ? leaf : const Color(0xFFE6D6AE),
                border: Border.all(color: const Color(0xFFB7A981)),
              ),
              child: text(value, 10, color: tab == value ? cream : ink),
            ),
          ),
      ],
    );
  }

  List<Widget> content() {
    final cards = spec['cards'] as List?;
    final rows = spec['rows'] as List?;
    return [
      if (spec['tab'] != null) ...[tabs(), gap(10)],
      if (spec['view'] == 'tutorial') ...[
        for (var i = 0; i < (spec['steps'] as List).length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  color: leaf,
                  child: text('${i + 1}', 12, color: cream),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: text(spec['steps'][i], 12, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (i == 1 &&
              [
                'fishing',
                'chopping',
                'hunting',
              ].contains(spec['tutorial'])) ...[
            gap(6),
            timing(),
            gap(8),
          ],
          if (i == 1 && spec['tutorial'] == 'ruins') ...[
            gap(6),
            panel(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final icon in [
                    Icons.wb_sunny_outlined,
                    Icons.waves,
                    Icons.eco_outlined,
                  ])
                    Icon(icon, size: 36, color: leaf),
                ],
              ),
            ),
            gap(8),
          ],
        ],
      ],
      if (cards != null) ...[deck(cards), gap(12)],
      if (spec['detail'] != null) ...[
        text(spec['detail'], 14, weight: FontWeight.w900),
        gap(5),
      ],
      if (spec['body'] != null) ...[
        text(spec['body'], 11, weight: FontWeight.w500),
        gap(10),
      ],
      if (rows != null) ...[
        if (spec['view'] == 'craft' && spec['tab'] == 'CRAFT')
          costs(rows)
        else
          panel(Column(children: [for (final r in rows) row(r)]), pad: 10),
        gap(10),
      ],
      if (spec['settings'] == true) ...[
        panel(
          Column(
            children: [
              for (final name in ['Music', 'Sound effects', 'Haptic feedback'])
                Column(
                  children: [
                    SizedBox(
                      height: 38,
                      child: Row(
                        children: [
                          Expanded(child: text(name, 11)),
                          if (name != 'Haptic feedback')
                            text(
                              name == 'Music' ? '65%' : '80%',
                              10,
                              color: muted,
                            ),
                          const SizedBox(width: 8),
                          Container(
                            width: 34,
                            height: 18,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: leaf,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const CircleAvatar(
                              radius: 6,
                              backgroundColor: cream,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (name != 'Haptic feedback')
                      SizedBox(
                        height: 22,
                        child: SliderTheme(
                          data: const SliderThemeData(
                            trackHeight: 3,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            activeTrackColor: leaf,
                            inactiveTrackColor: Color(0xFFC3B58F),
                            thumbColor: leaf,
                          ),
                          child: Slider(
                            value: name == 'Music' ? .65 : .8,
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        gap(10),
      ],
      if (spec['note'] != null) ...[
        text(spec['note'], 10, color: muted, weight: FontWeight.w500),
        gap(10),
      ],
      if (spec['button'] != null) ...[button(spec['button']), gap(6)],
      if (spec['secondary'] != null) button(spec['secondary'], secondary: true),
    ];
  }

  Widget popup() => Center(
    child: Container(
      width: 368,
      decoration: decor(),
      padding: const EdgeInsets.all(7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 0, 5),
            child: Row(
              children: [
                CardArt(spec['headerArt'] ?? 'journal', size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text(spec['title'], 17, weight: FontWeight.w900),
                      if (spec['subtitle'] != null)
                        text(spec['subtitle'], 9, color: muted),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.close_rounded, color: leaf),
                  style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                ),
              ],
            ),
          ),
          const Divider(height: 14, color: Color(0xFFB7A981)),
          ...content(),
        ],
      ),
    ),
  );
  Widget hud() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 78,
        padding: const EdgeInsets.all(7),
        decoration: decor(),
        child: Column(
          children: [
            text('DAY 7', 14, weight: FontWeight.w900),
            text('Sunny', 10),
            text('4/6 TIME', 10, color: muted),
          ],
        ),
      ),
      const Spacer(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              for (final stat in [
                ('health', '100'),
                ('water', '80'),
                ('food', '75'),
                ('sanity', '80'),
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 43,
                        height: 43,
                        child: Image.file(
                          File(
                            'design/parchment-cards-concept-v1/stat-${stat.$1}-v1.png',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        color: const Color(0xDBEEE1BA),
                        child: text(stat.$2, 10),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 32,
                        height: 3,
                        color: const Color(0xFF9CAD72),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          gap(8),
          panel(
            Row(
              children: [
                for (final r in [
                  ('wood', '12'),
                  ('stone', '4'),
                  ('fiber', '8'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        CardArt(r.$1, size: 19),
                        const SizedBox(width: 4),
                        text(r.$2, 10),
                      ],
                    ),
                  ),
              ],
            ),
            pad: 4,
          ),
        ],
      ),
    ],
  );
  Widget camp() => Padding(
    padding: const EdgeInsets.fromLTRB(19, 26, 19, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hud(),
        gap(18),
        Align(
          alignment: Alignment.centerLeft,
          child: panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  spec['night'] == true
                      ? 'Prepare for the night'
                      : spec['objective'],
                  12,
                ),
                text(spec['progress'], 10, color: muted),
              ],
            ),
            pad: 9,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final title in ['ITEMS', 'CRAFT', 'MENU', 'MAP'])
              Container(
                width: 57,
                height: 44,
                margin: const EdgeInsets.only(left: 5),
                alignment: Alignment.center,
                decoration: decor(),
                child: text(title, 10),
              ),
          ],
        ),
        gap(8),
        deck([
          ['forage', 'FORAGE', '1 time', 'SURVIVAL'],
          ['map', 'EXPLORE', '2 time', 'TRAVEL'],
          ['shelter', 'REST', '1 time', 'SURVIVAL'],
        ]),
      ],
    ),
  );
  Widget scene() => Padding(
    padding: const EdgeInsets.fromLTRB(19, 26, 19, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hud(),
        gap(14),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(spec['title'], 16, weight: FontWeight.w900),
              if (spec['body'] != null) ...[
                gap(4),
                text(spec['body'], 11, weight: FontWeight.w500),
              ],
            ],
          ),
          pad: 10,
        ),
        const Spacer(),
        if (spec['timing'] == true) ...[timing(), gap(10)],
        if (spec['discs'] == true) ...[
          panel(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final icon in [
                  Icons.wb_sunny_outlined,
                  Icons.waves,
                  Icons.eco_outlined,
                ])
                  Icon(icon, size: 25, color: leaf),
              ],
            ),
          ),
          gap(10),
        ],
        if (spec['rows'] != null) ...[
          panel(
            Column(children: [for (final r in spec['rows']) row(r)]),
            pad: 8,
          ),
          gap(10),
        ],
        if (spec['detail'] != null) ...[
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(spec['detail'], 13),
                if (spec['note'] != null) ...[
                  gap(5),
                  text(spec['note'], 11, weight: FontWeight.w500),
                ],
              ],
            ),
          ),
          gap(10),
        ],
        if (spec['cards'] != null) ...[deck(spec['cards']), gap(10)],
        if (spec['note'] != null && spec['detail'] == null) ...[
          panel(text(spec['note'], 10, weight: FontWeight.w500), pad: 7),
          gap(10),
        ],
        if (spec['button'] != null) ...[button(spec['button']), gap(6)],
        if (spec['secondary'] != null)
          button(spec['secondary'], secondary: true),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final kind = spec['kind'];
    final tier = spec['tier'] ?? 2;
    final bg = kind == 'camp'
        ? 'camp_tier_${tier}_empty_v1.jpg'
        : spec['background'] ?? 'camp_tier_2_empty_v1.jpg';
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/art/$bg', fit: BoxFit.fitWidth),
          if (kind == 'camp')
            CampCharacter(
              artworkRect: const Rect.fromLTWH(0, 72, 390, 700),
              variant: 0,
              tier: tier,
            ),
          if (kind == 'popup') const ColoredBox(color: Color(0xA8071D19)),
          if (spec['night'] == true) const ColoredBox(color: Color(0x780B152B)),
          if (kind == 'camp')
            camp()
          else if (kind == 'scene')
            scene()
          else
            popup(),
        ],
      ),
    );
  }
}
