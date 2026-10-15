import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/fishing_art.dart';
import 'package:survival_game/ui/card_illustration.dart';
import 'package:survival_game/ui/parchment_components.dart';
import '../../screenshots/tools/capture_fonts.dart';
import '../survival-ecology-v1/ui/render.dart' as shared;
import '../fishing-progression-v1/render.dart' as f;

const folder = 'design/inventory-storage-v1';
const ink = ParchmentColors.ink,
    leaf = ParchmentColors.leaf,
    cream = ParchmentColors.cream,
    muted = ParchmentColors.muted;
const river = 'assets/art/riverbank_camp_style_v2.png';
void noop() {}
Widget text(String value) => shared.body(value);
Widget title(String value) => shared.section(value);
Widget gap([double v = 12]) => SizedBox(height: v);
Widget col(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: children,
);
Widget button(String value, {bool secondary = false}) =>
    f.button(value, secondary: secondary);
Widget row(String label, String value, {String? icon}) =>
    f.row(label, value, icon: icon);
Widget modal(
  String name,
  String subtitle,
  Widget child, {
  bool field = false,
  String art = 'inventory',
}) => shared.modal(
  name,
  subtitle: subtitle,
  art: art,
  backgroundFile: field ? river : null,
  child: child,
);
Widget cards(List<Widget> children) => ParchmentCardGrid(children: children);
Widget item(
  String id,
  String name,
  String info,
  String status, {
  bool selected = false,
}) => ParchmentCard(
  title: name,
  art: id,
  info: info,
  status: status,
  selected: selected,
  onTap: noop,
);
Widget tabs(String selected, {bool field = false}) => Row(
  children: [
    for (final value in ['STORAGE', 'BACKPACK', 'GEAR']) ...[
      if (value != 'STORAGE') const SizedBox(width: 6),
      Expanded(
        child: parchmentButton(
          value,
          field && value == 'STORAGE' ? null : noop,
          secondary: selected != value,
        ),
      ),
    ],
  ],
);
Widget capacity(int used, {int maximum = 8, String? caption}) => col([
  Row(
    children: [
      const Icon(Icons.backpack_outlined, size: 22, color: leaf),
      const SizedBox(width: 8),
      const Expanded(child: ParchmentLabel('PACK SPACE', size: 11)),
      ParchmentLabel(
        '$used / $maximum',
        size: 17,
        color: used > maximum ? ParchmentColors.rust : ink,
      ),
    ],
  ),
  gap(6),
  Row(
    children: [
      for (var i = 0; i < maximum; i++)
        Expanded(
          child: Container(
            height: 9,
            margin: EdgeInsets.only(right: i == maximum - 1 ? 0 : 3),
            color: i < used ? leaf : const Color(0xFFCDC098),
          ),
        ),
    ],
  ),
  if (caption != null) ...[gap(6), text(caption)],
]);
Widget qty(String label, String value, {String? icon}) => col([
  row(label, value, icon: icon),
  Row(
    children: [
      for (final value in ['−1', '+1', '+5', 'ALL']) ...[
        if (value != '−1') const SizedBox(width: 8),
        Expanded(child: button(value, secondary: true)),
      ],
    ],
  ),
]);
Widget hero(String id) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 270),
    child: AspectRatio(
      aspectRatio: 1.5,
      child: Image.asset(cardIllustrationFor(id)!, fit: BoxFit.cover),
    ),
  ),
);
Widget gearLine() => col([
  title('EQUIPPED · SEPARATE FROM PACK'),
  Wrap(
    spacing: 12,
    runSpacing: 8,
    children: [
      for (final id in [
        'stone_axe',
        'hunting_spear',
        'basic_rod',
        'machete',
        'torch',
        'leaf_rain_cape',
      ])
        CardArt(id, size: 30),
    ],
  ),
  gap(8),
  text('One tool per slot. Equipped gear stays with you if you drop the pack.'),
]);
final fullPack = <Widget>[
  item('prepared_small_fish', 'COOKED FISH', '2 / 3 in stack', '1 SLOT'),
  item('herb', 'HERBS', '3 / 5 in stack', '1 SLOT'),
  item('bandage', 'BANDAGE', '1 / 3 in stack', '1 SLOT'),
  item('bait', 'WORMS', '4 / 10 in stack', '1 SLOT'),
  item('wood', 'WOOD', '10 / 10 in stack', '1 SLOT'),
  item('fiber', 'FIBER', '8 / 10 in stack', '1 SLOT'),
  item('stone', 'STONE', '5 / 5 in stack', '1 SLOT'),
  item('stone', 'STONE', '1 / 5 in stack', '1 SLOT'),
];
final concepts = <String, Widget Function()>{
  '01-camp-storage': () => modal(
    'ITEMS',
    'CAMP · SAFE STORAGE',
    col([
      tabs('STORAGE'),
      gap(),
      f.notice(
        'Stored here, safe from expedition losses. Available only at camp.',
      ),
      gap(16),
      cards([
        item('wood', 'WOOD', '12 stored', 'SAFE'),
        item('stone', 'STONE', '8 stored', 'SAFE'),
        item('fiber', 'FIBER', '12 stored', 'SAFE'),
        item('prepared_small_fish', 'COOKED FISH', '6 stored', 'SAFE'),
        item('herb', 'HERBS', '8 stored', 'SAFE'),
        item('bandage', 'BANDAGE', '3 stored', 'SAFE'),
      ]),
      gap(12),
      row('Camp capacity', 'Unlimited'),
      gap(),
      button('PREPARE PACK'),
    ]),
  ),
  '02-prepare-pack': () => modal(
    'PREPARE PACK',
    'RIVERBANK · BEFORE YOU LEAVE',
    col([
      tabs('BACKPACK'),
      gap(),
      capacity(4, caption: '4 free slots for discoveries.'),
      gap(16),
      cards([
        item('prepared_small_fish', 'COOKED FISH', '2 / 3 in stack', 'PACKED'),
        item('herb', 'HERBS', '3 / 5 in stack', 'PACKED'),
        item('bandage', 'BANDAGE', '1 / 3 in stack', 'PACKED'),
        item('bait', 'WORMS', '4 / 10 in stack', 'PACKED'),
      ]),
      gap(16),
      gearLine(),
      gap(16),
      button('LEAVE CAMP · 2 TIME'),
      TextButton(onPressed: noop, child: const Text('Review supplies & route')),
    ]),
  ),
  '03-transfer-quantity': () => modal(
    'PACK COOKED FISH',
    'MOVE FROM CAMP STORAGE',
    col([
      Center(
        child: SizedBox(
          width: 250,
          height: 167,
          child: const ParchmentCardImage(),
        ),
      ),
      gap(12),
      row('In camp now', '6 portions'),
      row('Stack size', '3 portions per slot'),
      gap(16),
      qty('Planned for backpack', '2 portions', icon: 'prepared_small_fish'),
      gap(16),
      row('Will remain at camp', '4 portions'),
      row('Fish uses', '1 backpack slot'),
      gap(),
      capacity(4, caption: '4 of 8 slots used after this change.'),
      gap(16),
      button('USE THIS AMOUNT'),
      gap(),
      text(
        'Transfers are free at camp. The draft commits only when you leave.',
      ),
    ]),
  ),
  '04-departure-confirmation': () => modal(
    'READY TO LEAVE?',
    'DESTINATION · RIVERBANK',
    col([
      capacity(4, caption: '4 free slots for loot.'),
      gap(16),
      title('PACKED SUPPLIES'),
      row('Cooked fish', '2 portions', icon: 'prepared_small_fish'),
      row('Herbs', '3', icon: 'herb'),
      row('Bandage', '1', icon: 'bandage'),
      row('Worms', '4', icon: 'bait'),
      gap(16),
      gearLine(),
      gap(16),
      title('JOURNEY COST'),
      row('Daylight', '2 time'),
      row('Base supplies', '8 Water · 6 Food'),
      gap(),
      f.notice(
        'Dropping your pack loses carried items. Your camp stock and equipped gear stay safe.',
        warning: true,
      ),
      gap(16),
      button('LEAVE CAMP'),
    ]),
  ),
  '05-backpack-on-trail': () => modal(
    'BACKPACK',
    'RIVERBANK · CARRIED ITEMS',
    col([
      tabs('BACKPACK', field: true),
      gap(),
      capacity(8),
      gap(12),
      cards(fullPack),
      gap(),
      text(
        'Tap an item to use it or inspect its stack. Camp storage is unavailable here.',
      ),
    ]),
    field: true,
  ),
  '06-pending-haul': () => modal(
    'YOUR PACK IS FULL',
    'NEW DISCOVERY · NOT YET PACKED',
    col([
      capacity(8),
      gap(16),
      title('NEW ITEMS FOUND'),
      cards([
        item('battery', 'BATTERY', '1 found', 'NEEDS 1 SLOT'),
        item('wood', 'WOOD', '3 found', 'NEEDS 1 SLOT'),
      ]),
      gap(16),
      row('Space if you keep everything', '10 / 8 slots'),
      gap(),
      f.notice(
        'Make room or leave something behind. Nothing is discarded until you confirm.',
        warning: true,
      ),
      gap(16),
      button('CHOOSE WHAT TO KEEP'),
      gap(),
      text(
        'The action is already resolved. Reopening this screen does not repeat its cost or reward.',
      ),
    ]),
    field: true,
  ),
  '07-choose-kept-items': () => modal(
    'MAKE ROOM',
    'SELECT FINAL AMOUNTS',
    col([
      capacity(
        8,
        caption: 'Selected items fit. Other supplies stay unchanged.',
      ),
      gap(16),
      title('ADJUST YOUR HAUL'),
      qty('Wood · 13 available', 'Keep 10', icon: 'wood'),
      gap(),
      qty('Stone · 6 available', 'Keep 5', icon: 'stone'),
      gap(),
      row('Battery', 'Keep 1 / 1', icon: 'battery'),
      gap(),
      f.notice('Reducing Stone from 6 to 5 frees one whole slot.'),
      gap(16),
      title('WILL BE LEFT BEHIND'),
      row('Wood', '3', icon: 'wood'),
      row('Stone', '1', icon: 'stone'),
      gap(16),
      button('REVIEW KEPT ITEMS'),
    ]),
    field: true,
  ),
  '08-confirm-left-behind': () => modal(
    'LEAVE THESE ITEMS?',
    'FINAL CONFIRMATION',
    col([
      const Center(
        child: Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: ParchmentColors.rust,
        ),
      ),
      gap(16),
      text('You will keep the Battery and leave the following items behind:'),
      gap(16),
      row('Wood', '3 left behind', icon: 'wood'),
      row('Stone', '1 left behind', icon: 'stone'),
      gap(16),
      capacity(8, caption: 'Your chosen items fit in the backpack.'),
      gap(16),
      f.notice(
        'Left items cannot be collected later. Closing returns to your selection.',
        warning: true,
      ),
      gap(16),
      button('CONFIRM & KEEP SELECTED'),
      gap(8),
      button('CHANGE SELECTION', secondary: true),
    ]),
    field: true,
  ),
  '09-return-and-unload': () => modal(
    'HOME WITH THE HAUL',
    'AUTOMATICALLY STORED AT CAMP',
    col([
      title('NEW ITEMS BROUGHT HOME'),
      row('Wood', '+10 · total 22', icon: 'wood'),
      row('Fiber', '+8 · total 20', icon: 'fiber'),
      row('Stone', '+5 · total 13', icon: 'stone'),
      row('Battery', '+1 · total 1', icon: 'battery'),
      gap(16),
      f.notice(
        'Unused food, medicine and bait were returned to storage. They are not counted as new loot.',
      ),
      gap(16),
      capacity(0, caption: 'Backpack unloaded. Your camp stock is safe.'),
      gap(16),
      button('CONTINUE'),
    ]),
  ),
  '10-backpack-upgrades': () => modal(
    'BACKPACK UPGRADES',
    'WORKSHOP · MORE ROOM FOR DISCOVERIES',
    col([
      cards([
        item('inventory', 'WORN BACKPACK', '8 slots', 'OWNED'),
        item(
          'inventory',
          'TRAIL BACKPACK',
          '12 slots',
          'READY',
          selected: true,
        ),
        item('inventory', 'EXPEDITION PACK', '16 slots', 'TIER 2'),
      ]),
      gap(16),
      title('SELECTED · TRAIL BACKPACK'),
      row('Capacity', '8 → 12 slots'),
      row('Extra room', '+4 slots'),
      gap(12),
      title('COST · NEEDED / AVAILABLE'),
      row('Fiber', '10 / 12', icon: 'fiber'),
      row('Hardwood', '2 / 4', icon: 'hardwood'),
      row('Daylight', '1 time'),
      row('Requirement', 'Camp Tier 1'),
      gap(),
      text(
        'Permanent for this run. Does not wear out and uses no backpack slot.',
      ),
      gap(16),
      button('CRAFT UPGRADE · 1 TIME'),
    ]),
  ),
};

class ParchmentCardImage extends StatelessWidget {
  const ParchmentCardImage({super.key});
  @override
  Widget build(BuildContext context) => const FishingArt('prepared_small_fish');
}

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
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
      ('00a-storage-and-packing', 'TÁROLÁS ÉS INDULÁS', [0, 1, 2, 3, 4, 5]),
      ('00b-overflow-and-return', 'ZSÁKMÁNY ÉS HAZATÉRÉS', [6, 7, 8, 9]),
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
        const Size(720, 1120),
        2,
      );
    }
    File('$folder/manifest.txt').writeAsStringSync('${files.join('\n')}\n');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}
