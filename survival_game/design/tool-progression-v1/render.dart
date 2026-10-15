import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/canopy_components.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/scene_artwork.dart';
import '../../screenshots/tools/capture_fonts.dart';
import '../survival-ecology-v1/ui/render.dart' as shared;
import '../fishing-progression-v1/render.dart' as f;

const folder = 'design/tool-progression-v1';
const workshop = 'assets/art/workshop_camp_style_v1.png';
const jaguar = 'design/jaguar-camp-style-test/jaguar_camp_style_v3.png';
const chopping = 'assets/art/wood_chopping_background_v1.png';
const ink = ParchmentColors.ink,
    leaf = ParchmentColors.leaf,
    cream = ParchmentColors.cream,
    muted = ParchmentColors.muted;
late ui.Image atlas;
void noop() {}
Widget gap([double size = 12]) => SizedBox(height: size);
Widget text(String value) => shared.body(value);
Widget title(String value) => shared.section(value);
Widget col(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: children,
);
Widget art(int index) => CustomPaint(
  painter: shared.SheetPainter(atlas, index),
  size: Size.infinite,
);
Widget photo(int index) =>
    Center(child: SizedBox(width: 300, height: 200, child: art(index)));
Widget card(
  int index,
  String name,
  String info,
  String status, {
  bool selected = false,
}) => ParchmentCard(
  title: name,
  art: 'stone_axe',
  artWidget: art(index),
  info: info,
  status: status,
  selected: selected,
  onTap: noop,
);
Widget cards(List<Widget> values) => ParchmentCardGrid(children: values);
Widget button(String label, {bool secondary = false}) => SizedBox(
  width: double.infinity,
  child: parchmentButton(label, noop, secondary: secondary),
);
Widget row(String label, String value, {String? icon}) =>
    f.row(label, value, icon: icon);
Widget modal(
  String name,
  String subtitle,
  Widget child, {
  String? background,
  String icon = 'stone_axe',
}) => shared.modal(
  name,
  subtitle: subtitle,
  art: icon,
  backgroundFile: background ?? workshop,
  child: child,
);
Widget meter(String label, int current, int maximum) => col([
  Row(
    children: [
      Expanded(child: text(label)),
      ParchmentLabel('$current / $maximum', size: 13),
    ],
  ),
  gap(6),
  LinearProgressIndicator(
    value: current / maximum,
    minHeight: 7,
    color: leaf,
    backgroundColor: const Color(0xFFCDC098),
  ),
]);
Widget tabs(bool axes) => Row(
  children: [
    Expanded(child: button('AXES', secondary: !axes)),
    const SizedBox(width: 8),
    Expanded(child: button('SPEARS', secondary: axes)),
  ],
);
Widget spentStat(
  String icon,
  String label,
  int spent,
  int remaining,
  Color color,
) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CardArt(icon, size: 28),
      const SizedBox(width: 12),
      Expanded(
        child: col([
          ParchmentLabel(
            '−$spent $label',
            size: 15,
            color: ParchmentColors.rust,
          ),
          gap(3),
          Text(
            'Remaining: $remaining / 100',
            style: const TextStyle(fontSize: 11, color: ink),
          ),
          gap(5),
          LinearProgressIndicator(
            value: remaining / 100,
            minHeight: 5,
            color: color,
            backgroundColor: const Color(0xFFCDC098),
          ),
        ]),
      ),
    ],
  ),
);
Widget scene(String asset, Widget heading, Widget footer) => Scaffold(
  backgroundColor: const Color(0xFF102A28),
  body: Stack(
    children: [
      Positioned.fill(
        child: asset.startsWith('design/')
            ? Image.file(File(asset), fit: BoxFit.cover)
            : SceneArtwork(asset: asset),
      ),
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x66102A28),
                Colors.transparent,
                Color(0x99102A28),
              ],
            ),
          ),
        ),
      ),
      SafeArea(
        child: CanopySceneBody(
          header: col([CanopyHud(state: f.state), gap(), heading]),
          footer: footer,
        ),
      ),
    ],
  ),
);
Widget paper(Widget child) => PaperSurface(
  child: Padding(padding: const EdgeInsets.all(12), child: child),
);
Widget compare(String label, String before, String after) =>
    row(label, '$before  →  $after');

final concepts = <String, Widget Function()>{
  '01-workshop-axes': () => modal(
    'CRAFT',
    'TOOLS & WEAPONS',
    col([
      tabs(true),
      gap(16),
      title('AXES · BUILD YOUR NEXT TOOL'),
      cards([
        card(0, 'STONE AXE', '10 durability', 'OWNED'),
        card(1, 'REINFORCED AXE', '16 durability', 'READY', selected: true),
        card(2, 'SALVAGE AXE', '24 durability', 'TIER 2'),
      ]),
      gap(16),
      f.notice(
        'Tap a tool for its benefits, exact costs and crafting confirmation.',
      ),
      gap(16),
      title('SELECTED · REINFORCED AXE'),
      meter('Lasts longer in the field', 16, 16),
      gap(),
      text(
        'A stronger binding and a steadier swing. Your Stone Axe stays as a spare.',
      ),
      gap(16),
      button('VIEW CRAFTING DETAILS'),
    ]),
  ),
  '02-workshop-spears': () => modal(
    'CRAFT',
    'TOOLS & WEAPONS',
    col([
      tabs(false),
      gap(16),
      title('SPEARS · KEEP YOUR DISTANCE'),
      cards([
        card(3, 'STONE SPEAR', '10 durability', 'OWNED'),
        card(4, 'HUNTING SPEAR', '16 durability', 'READY', selected: true),
        card(5, 'SALVAGE SPEAR', '24 durability', 'TIER 2'),
      ]),
      gap(16),
      f.notice(
        'Better spears improve control and physical standoffs. They never guarantee a win.',
      ),
      gap(16),
      title('SELECTED · HUNTING SPEAR'),
      row('Hunting control', 'Wider GOOD zone'),
      row('Spear decisions', '+8 percentage points'),
      gap(),
      button('VIEW CRAFTING DETAILS'),
    ]),
    icon: 'stone_spear',
  ),
  '03-axe-crafting-details': () => modal(
    'REINFORCED AXE',
    'CRAFT · TIER 1',
    col([
      photo(1),
      gap(),
      title('UPGRADE FROM STONE AXE'),
      compare('Durability', '10', '16'),
      compare('GOOD zone', '×1', '×1.10'),
      row('Wood bonus', '+1 per successful attempt'),
      gap(),
      title('REQUIREMENTS'),
      row('Basic Refuge', 'Tier 1 · met'),
      row('Stone Axe', 'Owned · kept as spare'),
      gap(),
      title('CRAFTING COST · NEEDED / AVAILABLE'),
      row('Wood', '3 / 12', icon: 'wood'),
      row('Stone', '2 / 3', icon: 'stone'),
      row('Fiber', '3 / 8', icon: 'fiber'),
      row('Daylight', '1 time'),
      gap(),
      button('CRAFT & EQUIP'),
    ]),
  ),
  '04-items-gear': () => modal(
    'ITEMS',
    'GEAR · SPEARS',
    col([
      title('CHOOSE YOUR SPEAR'),
      cards([
        card(3, 'STONE SPEAR', '7 / 10 condition', 'AVAILABLE'),
        card(
          4,
          'HUNTING SPEAR',
          '12 / 16 condition',
          'EQUIPPED',
          selected: true,
        ),
        card(5, 'SALVAGE SPEAR', '3 / 24 condition', 'AVAILABLE'),
      ]),
      gap(16),
      title('EQUIPPED · HUNTING SPEAR'),
      meter('Condition', 12, 16),
      gap(),
      row('Hunting control', 'GOOD zone ×1.10'),
      row('Spear decisions', '+8 percentage points'),
      gap(),
      f.notice(
        'Switching costs no time. Equipment is fixed when an attempt begins.',
      ),
      gap(),
      button('VIEW TOOL DETAILS', secondary: true),
    ]),
    icon: 'inventory',
  ),
  '05-repair-confirmation': () => modal(
    'REPAIR SALVAGE SPEAR',
    'WORKSHOP · RESTORE CONDITION',
    col([
      photo(5),
      gap(),
      meter('Before repair', 3, 24),
      gap(),
      Row(
        children: [
          const Icon(Icons.arrow_downward, color: leaf),
          const SizedBox(width: 8),
          Expanded(child: meter('After repair', 24, 24)),
        ],
      ),
      gap(18),
      title('REPAIR COST · NEEDED / AVAILABLE'),
      row('Metal Scrap', '1 / 4', icon: 'metal_scrap'),
      row('Fiber', '2 / 8', icon: 'fiber'),
      row('Daylight', '1 time'),
      gap(),
      f.notice(
        'Restores this spear to full condition. Your other tools are unchanged.',
      ),
      gap(16),
      button('REPAIR · 1 TIME'),
    ]),
    icon: 'stone_spear',
  ),
  '06-chopping-loadout': () => scene(
    chopping,
    shared.paperNote(
      'WOOD CHOPPING',
      'Choose your axe',
      'Three swings. Time each strike in the green zone.',
    ),
    col([
      paper(
        col([
          Row(
            children: [
              SizedBox(width: 90, height: 60, child: art(1)),
              const SizedBox(width: 12),
              Expanded(
                child: col([
                  const ParchmentLabel('REINFORCED AXE', size: 14),
                  gap(6),
                  meter('Condition', 14, 16),
                ]),
              ),
            ],
          ),
          gap(),
          row('GOOD zone', '×1.10 control'),
          row('Start cost', '1 time · 4 water · 3 food'),
          gap(),
          text(
            'Each miss causes extra tool wear. Find out what you gathered after the attempt.',
          ),
          gap(),
          Row(
            children: [
              Expanded(child: button('CHANGE', secondary: true)),
              const SizedBox(width: 8),
              Expanded(child: button('START')),
            ],
          ),
        ]),
      ),
    ]),
  ),
  '07-jaguar-encounter': () => scene(
    jaguar,
    shared.paperNote(
      'DANGER · RIVERBANK',
      'Eyes in the grass',
      'Choose your response.',
    ),
    col([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'CHOOSE A RESPONSE',
                style: TextStyle(
                  color: cream,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_left, color: cream),
            const SizedBox(width: 16),
            Icon(Icons.chevron_right, color: cream),
          ],
        ),
      ),
      cards([
        const ParchmentCard(
          title: 'WAVE THE TORCH',
          art: 'torch',
          info: 'View details',
          status: 'LOCKED',
          onTap: noop,
        ),
        card(4, 'HOLD YOUR GROUND', 'View details', 'READY'),
        const ParchmentCard(
          title: 'THROW IT MEAT',
          art: 'raw_meat',
          info: 'View details',
          status: 'READY',
          onTap: noop,
        ),
      ]),
    ]),
  ),
  '08-spear-decision-details': () => modal(
    'HOLD YOUR GROUND',
    'DANGER · DECISION DETAILS',
    col([
      photo(4),
      gap(),
      text(
        'Keep the spear between you and the jaguar. It may still break through.',
      ),
      gap(16),
      title('USING · HUNTING SPEAR'),
      meter('Condition', 12, 16),
      gap(),
      row('Base chance', '70%'),
      row('Hunting Spear', '+8 points'),
      row('Injured', '−10 points'),
      const Divider(height: 20),
      row('Current success chance', '68%'),
      gap(),
      f.notice(
        'Failure can injure you and cost your carried loot.',
        warning: true,
      ),
      gap(),
      row('Tool wear', '1 condition'),
      text(
        'No extra daylight for this response. Route costs are shown before travel.',
      ),
      gap(16),
      button('CONFIRM RESPONSE'),
    ]),
    background: jaguar,
    icon: 'stone_spear',
  ),
  '09-chopping-outcome': () => modal(
    'WOOD GATHERED',
    'WHAT HAPPENED',
    col([
      photo(1),
      gap(),
      text(
        'Three well-timed swings split the fallen trunk. Your stronger axe helped finish the job.',
      ),
      gap(16),
      title('COLLECTED'),
      row('Wood', '+10 · now 22', icon: 'wood'),
      row('Hardwood', '+2 · now 4', icon: 'hardwood'),
      gap(16),
      title('TOOL CONDITION'),
      meter('Reinforced Axe · 14 → 13', 13, 16),
      gap(),
      title('SUPPLIES USED'),
      spentStat('water', 'WATER', 4, 58, const Color(0xFF287E90)),
      spentStat('food', 'FOOD', 3, 54, const Color(0xFF9C6338)),
      const Divider(height: 16),
      Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 26, color: leaf),
          const SizedBox(width: 12),
          Expanded(
            child: col([
              const ParchmentLabel('3 / 6 TIME LEFT', size: 14),
              gap(3),
              const Text(
                'This action used 1 time',
                style: TextStyle(fontSize: 11, color: ink),
              ),
            ]),
          ),
        ],
      ),
      gap(16),
      button('CONTINUE'),
    ]),
    background: chopping,
  ),
};

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final codec = await tester.runAsync(
      () => ui.instantiateImageCodec(
        File('$folder/assets/tools-atlas-v1.png').readAsBytesSync(),
      ),
    );
    atlas = (await tester.runAsync(() => codec!.getNextFrame()))!.image;
    codec!.dispose();
    final boundary = GlobalKey();
    final files = <String>[];
    Future<void> render(
      Widget screen,
      String name,
      Size size,
      double ratio,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            theme: canopyTheme,
            debugShowCheckedModeBanner: false,
            home: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      final providers = find
          .byType(Image)
          .evaluate()
          .map((e) => (e.widget as Image).image)
          .toSet();
      providers.add(const AssetImage('assets/art/ui_parchment_texture.png'));
      await tester.runAsync(
        () => Future.wait(providers.map((p) => precacheImage(p, context))),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$name: $error');
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$folder/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
      stdout.writeln('RENDERED $name');
    }

    for (final entry in concepts.entries) {
      await render(entry.value(), entry.key, const Size(390, 844), 3);
      files.add('${entry.key}.png');
    }
    final boards = [
      ('00-overview', 'BALTÁK ÉS LÁNDZSÁK', [0, 1, 2, 3, 4, 5, 6, 7, 8]),
    ];
    for (final board in boards) {
      await render(
        Scaffold(
          backgroundColor: const Color(0xFF102A28),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: col([
              Text(
                'LOST CANOPY · ${board.$2}',
                style: const TextStyle(
                  color: cream,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              gap(5),
              const Text(
                'UI LÁTVÁNYTERVEK · 390 × 844 · még nincs bekötve',
                style: TextStyle(color: cream, fontSize: 11),
              ),
              gap(16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final index in board.$3)
                    SizedBox(
                      width: 216,
                      child: col([
                        SizedBox(
                          height: 29,
                          child: Text(
                            files[index]
                                .replaceAll('.png', '')
                                .replaceAll('-', ' '),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: cream,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Image.file(
                          File('$folder/${files[index]}'),
                          width: 216,
                          height: 216 * 844 / 390,
                          fit: BoxFit.contain,
                          cacheWidth: 432,
                        ),
                      ]),
                    ),
                ],
              ),
            ]),
          ),
        ),
        board.$1,
        const Size(720, 1640),
        2,
      );
    }
    File('$folder/manifest.txt').writeAsStringSync('${files.join('\n')}\n');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  atlas.dispose();
  keepAlive.cancel();
  exit(0);
}
