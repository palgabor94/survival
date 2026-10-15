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

const folder = 'design/run-progression-v1';
const ink = ParchmentColors.ink;
const leaf = ParchmentColors.leaf;
const cream = ParchmentColors.cream;
const muted = ParchmentColors.muted;
const rust = ParchmentColors.rust;
void noop() {}
Widget gap([double h = 12]) => SizedBox(height: h);
Widget column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: children,
);
Widget label(String text, {double size = 13, Color color = ink}) =>
    ParchmentLabel(text, size: size, weight: FontWeight.w600, color: color);
Widget section(String text) => Padding(
  padding: const EdgeInsets.only(top: 12, bottom: 8),
  child: label(text, size: 11, color: muted),
);
Widget button(String text, {bool secondary = false}) =>
    parchmentButton(text, noop, secondary: secondary);
Widget line(
  String name,
  String value, {
  String? art,
  Color color = ink,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    children: [
      if (art != null) ...[CardArt(art, size: 26), const SizedBox(width: 10)],
      Expanded(child: label(name, size: 12)),
      const SizedBox(width: 12),
      Flexible(child: label(value, size: 13, color: color)),
    ],
  ),
);
Widget notice(String text, {bool warning = false}) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: warning ? const Color(0x148F4E37) : const Color(0x14294E36),
    border: Border(left: BorderSide(color: warning ? rust : leaf, width: 3)),
  ),
  child: label(text, size: 12),
);
Widget progress({int total = 666, int floor = 500, int next = 900}) => column([
  line(
    'RANK ${floor == 500 ? 3 : 2} · ${floor == 500 ? 'FORAGER' : 'PATHFINDER'}',
    '$total XP',
  ),
  ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: LinearProgressIndicator(
      value: (total - floor) / (next - floor),
      minHeight: 10,
      color: leaf,
      backgroundColor: const Color(0xFFCABE98),
    ),
  ),
  gap(6),
  label(
    '${next - total} XP to next rank · $next XP total',
    size: 11,
    color: muted,
  ),
]);
Widget metrics(List<(String, String)> values) => LayoutBuilder(
  builder: (context, box) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        SizedBox(
          width: (box.maxWidth - 16) / 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            color: const Color(0x12294E36),
            child: Column(
              children: [
                label(v.$2, size: 19),
                gap(2),
                label(v.$1, size: 10, color: muted),
              ],
            ),
          ),
        ),
    ],
  ),
);
Widget page(
  String title,
  String subtitle,
  List<Widget> body, {
  String art = 'journal',
  List<Widget> actions = const [],
  bool close = true,
}) => Scaffold(
  backgroundColor: const Color(0xFF102A28),
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: PaperSurface(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      CardArt(art, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: column([
                          label(subtitle, size: 10, color: muted),
                          gap(2),
                          label(title, size: 21),
                        ]),
                      ),
                      if (close) ParchmentClose(onPressed: noop),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: column(body),
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: column([
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) gap(8),
                        actions[i],
                      ],
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
Widget result({bool rescued = false}) => page(
  rescued ? 'RESCUED' : 'JOURNEY ENDED',
  rescued ? 'HELP HAS ARRIVED' : 'REACHED DAY 8 · RIVERBANK',
  [
    AspectRatio(
      aspectRatio: 1.65,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            rescued
                ? 'assets/art/rescue_arrival_camp_style_v1.png'
                : 'assets/art/riverbank_camp_style_v2.png',
            fit: BoxFit.cover,
            alignment: rescued
                ? const Alignment(0, -.8)
                : const Alignment(0, .2),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD7102A28)],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            right: 16,
            child: column([
              label(
                rescued ? '10 NIGHTS SURVIVED' : '7 NIGHTS SURVIVED',
                size: 23,
                color: cream,
              ),
              label(
                rescued ? 'Rescued on Day 11' : 'Your record stays with you.',
                size: 12,
                color: cream,
              ),
            ]),
          ),
        ],
      ),
    ),
    gap(),
    notice(
      rescued
          ? 'You kept the beacon alive through all 3 storm challenges.'
          : 'Poisoned II caused the final health loss. No antidote was used.',
      warning: !rescued,
    ),
    gap(),
    metrics(
      rescued
          ? [
              ('Locations', '6 / 6'),
              ('Fish caught', '12'),
              ('Items made', '16'),
              ('Camp tier', '3'),
              ('Components', '5 / 5'),
              ('Storm steps', '3 / 3'),
            ]
          : [
              ('Locations', '3 / 6'),
              ('Fish caught', '5'),
              ('Items made', '9'),
              ('Camp tier', '2'),
              ('Components', '1 / 5'),
              ('Encounters', '4'),
            ],
    ),
    gap(),
    PaperSurface(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: column([
          line('SURVIVAL XP RECORDED', rescued ? '+720 XP' : '+246 XP'),
          label(
            rescued
                ? '420 → 1140 total XP · Rank 4'
                : '420 → 666 total XP · Rank 3',
            size: 12,
          ),
          gap(6),
          button('VIEW XP BREAKDOWN', secondary: true),
        ]),
      ),
    ),
  ],
  art: rescued ? 'shelter' : 'health',
  close: false,
  actions: [
    button('VIEW PROFILE'),
    Row(
      children: [
        Expanded(child: button('JOURNEY DETAILS', secondary: true)),
        const SizedBox(width: 8),
        Expanded(child: button('NEW JOURNEY', secondary: true)),
      ],
    ),
  ],
);
Widget perk(
  String name,
  String art,
  String info,
  String status, {
  bool selected = false,
}) => ParchmentCard(
  title: name,
  art: art,
  info: info,
  status: status,
  selected: selected,
  onTap: noop,
);

final concepts = <String, Widget Function()>{
  '01-lost-journey': () => result(),
  '02-rescued-journey': () => result(rescued: true),
  '03-xp-breakdown': () => page(
    'SURVIVAL XP',
    'LOST JOURNEY · DAY 8',
    [
      label('+246 XP', size: 34),
      label(
        'Earned through this journey. Already recorded.',
        size: 12,
        color: muted,
      ),
      section('WHAT YOU ACHIEVED'),
      line('7 nights × 8', '+56'),
      line('3 unique locations × 15', '+45', art: 'map'),
      line('2 fish species × 10', '+20', art: 'small_fish'),
      line('6 unique recipes × 5', '+30', art: 'stone_axe'),
      line('2 camp tiers × 20', '+40', art: 'shelter'),
      line('2 encounter types × 15', '+30', art: 'stone_spear'),
      line('1 component brought home', '+25', art: 'battery'),
      const Divider(),
      line('Final storm / rescue', '+0'),
      line('TOTAL THIS JOURNEY', '+246 XP'),
      gap(),
      progress(),
      gap(16),
      notice(
        'Repeated crafts and catches do not repeat the unique-discovery bonus. Practice gives no XP.',
      ),
    ],
    actions: [button('BACK TO SUMMARY')],
  ),
  '04-rank-unlocked': () => page(
    'RANK 3 · FORAGER',
    'NEW RANK RECORDED',
    [
      gap(24),
      const Center(child: CardArt('journal', size: 96)),
      gap(24),
      Center(child: label('PATHFINDER → FORAGER', size: 18)),
      gap(24),
      progress(),
      section('NEW STARTING OPTION'),
      ParchmentCardGrid(
        children: [
          perk('SCAVENGER KIT', 'stone', 'Rank 3 · supplies', 'UNLOCKED'),
        ],
      ),
      gap(16),
      notice(
        'Optional for your next journey. Your current or archived journey stays as played.',
      ),
      gap(),
      label('No perk is selected automatically.', size: 12),
    ],
    actions: [
      button('VIEW NEW OPTION'),
      button('KEEP NO PERK', secondary: true),
    ],
  ),
  '05-player-profile': () => page(
    'SURVIVOR PROFILE',
    'LOCAL RECORD · SAVED ON THIS DEVICE',
    [
      Row(
        children: [
          const CardArt('journal', size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: column([
              label('RANK 3', size: 28),
              label('FORAGER', size: 15),
            ]),
          ),
        ],
      ),
      gap(12),
      progress(),
      section('YOUR RECORD'),
      metrics([
        ('Journeys', '3'),
        ('Rescues', '0'),
        ('Best nights', '9'),
        ('Fish caught', '13'),
        ('Items made', '22'),
        ('Places seen', '5 / 6'),
      ]),
      gap(),
      line('Fastest rescue', 'Not rescued yet'),
      section('NEXT JOURNEY'),
      line('Starting option', 'NO PERK', art: 'inventory'),
      button('CHOOSE STARTING OPTION', secondary: true),
      gap(),
      button('JOURNEY ARCHIVE · 3', secondary: true),
      gap(),
      notice(
        'XP and records persist. Camp, gear and supplies start fresh in each journey.',
      ),
    ],
    actions: [button('NEW JOURNEY')],
  ),
  '06-journey-archive': () =>
      page('YOUR JOURNEYS', 'LATEST 20 · LIFETIME RECORDS ARE KEPT', [
        for (final record in [
          ('DAY 8 · LOST', '7 nights · Poisoned II', '+246 XP', 'LATEST'),
          (
            'DAY 10 · LOST',
            '9 nights · Jaguar encounter',
            '+297 XP',
            'BEST NIGHTS',
          ),
          ('DAY 7 · LOST', '6 nights · Deprivation', '+123 XP', 'RECORDED'),
        ]) ...[
          PaperSurface(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: column([
                label(record.$4, size: 10, color: muted),
                gap(6),
                label(record.$1, size: 18),
                gap(6),
                label(record.$2, size: 12),
                gap(8),
                line('SURVIVAL XP', record.$3),
                button('VIEW JOURNEY', secondary: true),
              ]),
            ),
          ),
          gap(12),
        ],
      ]),
  '07-journey-details': () => page(
    'JOURNEY DETAILS',
    'DAY 8 · LOST · RECORD SAVED',
    [
      notice(
        'Final cause: Poisoned II. Your health reached zero at the riverbank.',
        warning: true,
      ),
      section('THE JOURNEY'),
      for (final milestone in [
        ('DAY 1', 'A first tool', 'Crafted a Stone Knife.', 'stone_knife'),
        (
          'DAY 2',
          'A safe place to sleep',
          'Built the first camp upgrade.',
          'shelter',
        ),
        ('DAY 3', 'First catch', 'Caught a Stream Silverfish.', 'small_fish'),
        (
          'DAY 5',
          'Camp Tier 2',
          'A stronger base for longer trips.',
          'shelter',
        ),
        (
          'DAY 6',
          'A part of the signal',
          'Brought the battery safely home.',
          'battery',
        ),
        (
          'DAY 8',
          'The last expedition',
          'Poisoned II ended the journey.',
          'health',
        ),
      ]) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardArt(milestone.$4, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: column([
                label(milestone.$1, size: 10, color: muted),
                label(milestone.$2, size: 14),
                gap(3),
                label(milestone.$3, size: 12),
              ]),
            ),
          ],
        ),
        gap(16),
      ],
      notice(
        'Original supplies and camp stock are part of this archived journey. They do not carry into a new one.',
      ),
    ],
    actions: [button('VIEW XP BREAKDOWN', secondary: true)],
  ),
  '08-starting-options': () => page(
    'STARTING OPTION',
    'CHOOSE 0 OR 1 · NEXT JOURNEY ONLY',
    [
      notice('Choose a small supply trade. No automatic stat or combat bonus.'),
      gap(16),
      ParchmentCardGrid(
        children: [
          perk('NO PERK', 'inventory', 'Standard start', 'AVAILABLE'),
          perk(
            'SCAVENGER KIT',
            'stone',
            'Rank 3 · details',
            'SELECTED',
            selected: true,
          ),
          perk('ANGLER SUPPLIES', 'bait', 'Rank 5 · 1400 XP', 'LOCKED'),
          perk('FIELD MEDIC', 'bandage', 'Rank 7 · 2700 XP', 'LOCKED'),
        ],
      ),
      section('SCAVENGER KIT · SELECTED FOR NEXT RUN'),
      line('Stone at start', '+2', art: 'stone'),
      line('Wood at start', '−2', art: 'wood', color: rust),
      gap(),
      label(
        'Tap any card for the full trade and unlock requirement.',
        size: 12,
        color: muted,
      ),
    ],
    actions: [button('SAVE NEXT-JOURNEY CHOICE')],
  ),
  '09-option-details': () => page(
    'SCAVENGER KIT',
    'RANK 3 · UNLOCKED',
    [
      Center(
        child: SizedBox(
          width: 240,
          height: 160,
          child: Image.asset(
            'assets/art/card_stone_scene_v1.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      gap(16),
      label('Bring stone instead of starting firewood.', size: 17),
      section('STARTING SUPPLY TRADE'),
      line('Stone', '0 → 2', art: 'stone'),
      line('Wood', '2 → 0', art: 'wood', color: rust),
      gap(),
      notice(
        'You must gather wood before using recipes that need it.',
        warning: true,
      ),
      section('APPLIES WHEN A NEW JOURNEY STARTS'),
      label(
        'Supplies go into camp storage. Gear, stats and the 8-slot starting backpack follow the normal rules.',
        size: 13,
      ),
      gap(),
      label(
        'One starting option at a time. You can return to NO PERK for free.',
        size: 12,
        color: muted,
      ),
    ],
    art: 'stone',
    actions: [button('SELECT FOR NEXT JOURNEY')],
  ),
  '10-new-journey': () => page(
    'BEGIN AGAIN?',
    'NEXT JOURNEY · FINAL REVIEW',
    [
      section('YOUR START'),
      line('Starting option', 'Scavenger Kit', art: 'inventory'),
      line('Camp storage · Wood', '0', art: 'wood'),
      line('Camp storage · Stone', '2', art: 'stone'),
      line('Backpack', '8 slots · empty', art: 'inventory'),
      gap(),
      button('CHANGE STARTING OPTION', secondary: true),
      section('KEPT IN YOUR PROFILE'),
      line('Lifetime XP', '666 XP', art: 'journal'),
      label(
        'Ranks, unlocked options, records and saved journey summaries stay with you.',
        size: 13,
      ),
      section('A FRESH JOURNEY'),
      label(
        'Day 1 · Camp Tier 0. New supplies, gear progression and rescue search. Your completed journey is already archived.',
        size: 13,
      ),
      gap(16),
      notice('The selected option changes the new starting supplies only.'),
    ],
    actions: [
      button('START NEW JOURNEY'),
      button('KEEP VIEWING SUMMARY', secondary: true),
    ],
  ),
};

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final boundary = GlobalKey();
    final files = <String>[];
    Future<void> mount(Widget widget, Size size, double scale) async {
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
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      final providers =
          find
              .byType(Image)
              .evaluate()
              .map((e) => (e.widget as Image).image)
              .toSet()
            ..add(const AssetImage('assets/art/ui_parchment_texture.png'));
      await tester.runAsync(
        () => Future.wait(providers.map((p) => precacheImage(p, context))),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$size text $scale: $error');
    }

    Future<void> save(String name, {double ratio = 3}) async {
      final picture =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: ratio);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      File('$folder/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      picture.dispose();
      stdout.writeln('RENDERED $name');
    }

    for (final entry in concepts.entries) {
      await mount(entry.value(), const Size(390, 844), 1);
      await save(entry.key);
      files.add('${entry.key}.png');
    }
    for (final spec in [
      (const Size(320, 568), 1.0),
      (const Size(844, 390), 1.0),
      (const Size(375, 667), 2.0),
    ]) {
      for (final entry in concepts.entries) {
        await mount(entry.value(), spec.$1, spec.$2);
      }
      stdout.writeln('LAYOUT CHECKED ${spec.$1} text ${spec.$2}');
    }
    for (final board in [
      ('00a-results-and-profile', 'MENETVÉGE ÉS PROFIL', [0, 1, 2, 3, 4]),
      ('00b-records-and-start', 'TÖRTÉNET ÉS KÖVETKEZŐ MENET', [5, 6, 7, 8, 9]),
    ]) {
      await mount(
        Scaffold(
          backgroundColor: const Color(0xFF102A28),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: column([
              label('LOST CANOPY · ${board.$2}', size: 20, color: cream),
              gap(6),
              label(
                'PERGAMENTES LÁTVÁNYTERV · MINTAADATOK · MÉG NINCS BEKÖTVE',
                size: 11,
                color: cream,
              ),
              gap(16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final i in board.$3)
                    SizedBox(
                      width: 216,
                      child: column([
                        SizedBox(
                          height: 28,
                          child: label(
                            files[i]
                                .replaceAll('.png', '')
                                .replaceAll('-', ' '),
                            size: 10,
                            color: cream,
                          ),
                        ),
                        Image.file(
                          File('$folder/${files[i]}'),
                          width: 216,
                          height: 216 * 844 / 390,
                          cacheWidth: 432,
                        ),
                      ]),
                    ),
                ],
              ),
            ]),
          ),
        ),
        const Size(720, 1120),
        1,
      );
      await save(board.$1, ratio: 2);
    }
    File('$folder/manifest.txt').writeAsStringSync('${files.join('\n')}\n');
    await tester.pumpWidget(const SizedBox.shrink());
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}
