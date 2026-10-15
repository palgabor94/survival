import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/canopy_components.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/parchment_components.dart';
import 'package:survival_game/ui/scene_artwork.dart';
import '../../screenshots/tools/capture_fonts.dart';
import '../survival-ecology-v1/ui/render.dart' as shared;

const folder = 'design/fishing-progression-v1';
const pond = 'assets/art/fishing_pond.png';
const ink = ParchmentColors.ink,
    leaf = ParchmentColors.leaf,
    cream = ParchmentColors.cream,
    muted = ParchmentColors.muted,
    rust = ParchmentColors.rust;
late ui.Image atlas;
void noop() {}
final state = RunState(
  day: 5,
  timeLeft: 4,
  resources: {'wood': 12, 'stone': 3, 'fiber': 8},
  stats: {
    SurvivalStat.health: 88,
    SurvivalStat.water: 62,
    SurvivalStat.food: 57,
    SurvivalStat.sanity: 76,
  },
);
Widget text(String value) => shared.body(value);
Widget title(String value) => shared.section(value);
Widget gap([double value = 12]) => SizedBox(height: value);
Widget button(String value, {bool secondary = false}) => SizedBox(
  width: double.infinity,
  child: parchmentButton(value, noop, secondary: secondary),
);
Widget art(int index) => CustomPaint(
  painter: shared.SheetPainter(atlas, index),
  size: Size.infinite,
);
Widget card(
  int index,
  String name,
  String info,
  String status, {
  bool selected = false,
}) => ParchmentCard(
  title: name,
  art: 'small_fish',
  artWidget: art(index),
  info: info,
  status: status,
  selected: selected,
  onTap: noop,
);
Widget cards(List<Widget> values) => ParchmentCardGrid(children: values);
Widget photo(int index) =>
    Center(child: SizedBox(width: 300, height: 200, child: art(index)));
Widget notice(String message, {bool warning = false}) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: warning ? const Color(0x168F4E37) : const Color(0x12294E36),
    border: Border(left: BorderSide(color: warning ? rust : leaf, width: 3)),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
        size: 21,
        color: warning ? rust : leaf,
      ),
      const SizedBox(width: 8),
      Expanded(child: text(message)),
    ],
  ),
);
Widget metrics(List<(String, String)> values) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final v in values)
      Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFB7A981)),
        ),
        child: Column(
          children: [
            ParchmentLabel(v.$2, size: 17),
            ParchmentLabel(v.$1, size: 9, color: muted),
          ],
        ),
      ),
  ],
);
Widget row(String label, String value, {String? icon}) => shared.rowLine(
  icon == null
      ? const Icon(Icons.check_circle_outline_rounded, size: 22, color: leaf)
      : CardArt(icon, size: 23),
  label,
  value,
);
Widget modal(
  String name,
  String subtitle,
  Widget child, {
  String icon = 'small_fish',
}) => shared.modal(
  name,
  subtitle: subtitle,
  art: icon,
  backgroundFile: pond,
  child: child,
);
Widget scene(Widget heading, Widget footer) => Scaffold(
  backgroundColor: const Color(0xFF102A28),
  body: Stack(
    children: [
      const Positioned.fill(child: SceneArtwork(asset: pond)),
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x55102A28),
                Colors.transparent,
                Color(0x88102A28),
              ],
            ),
          ),
        ),
      ),
      SafeArea(
        child: CanopySceneBody(
          header: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CanopyHud(state: state),
              gap(),
              heading,
            ],
          ),
          footer: footer,
        ),
      ),
    ],
  ),
);
Widget panel(String eyebrow, String heading, String detail) =>
    shared.paperNote(eyebrow, heading, detail);
Widget column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: children,
);

final concepts = <String, Widget Function()>{
  '01-fishing-loadout': () => scene(
    panel(
      'FISHING POND',
      'Prepare your cast',
      'Choose a bait. Each attracts different fish.',
    ),
    column([
      PaperSurface(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const CardArt('basic_rod', size: 34),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ParchmentLabel('REINFORCED ROD', size: 13),
                    ParchmentLabel('Condition 16 / 20', size: 10, color: muted),
                  ],
                ),
              ),
              parchmentButton('CHANGE', noop, secondary: true),
            ],
          ),
        ),
      ),
      gap(8),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: Text(
          'CHOOSE BAIT · tap for details',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cream,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ),
      gap(5),
      cards([
        card(6, 'Worms', 'In pack · 4', 'SELECTED', selected: true),
        card(7, 'Insects', 'In pack · 2', 'AVAILABLE'),
        card(8, 'Fruit bait', 'In pack · 3', 'AVAILABLE'),
      ]),
      gap(10),
      PaperSurface(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: column([
            row('This cast', '1 bait · 1 time', icon: 'sun'),
            button('CAST LINE'),
          ]),
        ),
      ),
    ]),
  ),
  '02-bait-details': () => modal(
    'INSECT BAIT',
    'CHOOSE A DIFFERENT CATCH',
    column([
      photo(7),
      gap(),
      text(
        'Grasshoppers skim across the surface and attract fish that hunt near the banks.',
      ),
      gap(),
      title('KNOWN PREFERENCES'),
      row('Redfin Perch', 'FAVOURED'),
      row('Stream Silverfish', 'POSSIBLE'),
      gap(6),
      notice(
        'Bait changes which fish may bite. It never guarantees a rare catch.',
      ),
      gap(),
      row('In your pack', '2 portions', icon: 'inventory'),
      gap(),
      button('SELECT INSECTS'),
    ]),
    icon: 'bait',
  ),
  '03-fishing-reeling': () => scene(
    panel(
      'FISH ON THE LINE',
      'Keep it in the green zone',
      'Hold to move right. Release to move left.',
    ),
    column([
      shared.darkNote('A strong pull · the species is revealed after landing.'),
      PaperSurface(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: column([
            row('Reinforced Rod', 'STEADY', icon: 'basic_rod'),
            gap(6),
            SizedBox(height: 42, child: CustomPaint(painter: ReelPainter())),
            gap(),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(3)),
              child: LinearProgressIndicator(
                value: .64,
                minHeight: 9,
                color: leaf,
                backgroundColor: Color(0xFFCDBF96),
              ),
            ),
            gap(6),
            const ParchmentLabel(
              'LANDING PROGRESS · 64%',
              size: 10,
              align: TextAlign.center,
            ),
            gap(),
            button('HOLD TO REEL'),
            gap(6),
            text('No extra daylight is spent while you reel.'),
          ]),
        ),
      ),
    ]),
  ),
  '04-catch-common': () => catchResult(
    0,
    'STREAM SILVERFISH',
    'COMMON · KNOWN SPECIES',
    '18 cm',
    '0.24 kg',
    [notice('A reliable food fish. Cook at camp before eating.')],
  ),
  '05-catch-new-rare': () => catchResult(
    4,
    'GOLDSPOT RIVERFISH',
    'RARE · FIRST DISCOVERY',
    '42 cm',
    '1.35 kg',
    [
      notice(
        'New species added to your journal. Golden spots and a forked tail identify this river fish.',
      ),
    ],
  ),
  '06-catch-dangerous': () => catchResult(
    3,
    'SPINY SUNLURKER',
    'UNCOMMON · KNOWN HAZARD',
    '27 cm',
    '0.68 kg',
    [
      notice(
        'VENOMOUS SPINES\nKeep it as a raw item. Prepare with a knife at camp before eating.',
        warning: true,
      ),
      gap(6),
      text('Catching and keeping this fish does not automatically poison you.'),
    ],
  ),
  '07-fish-journal': () => modal(
    'RIVER FIELD GUIDE',
    '5 SPECIES · 3 DISCOVERED',
    column([
      shared.tabs(['FISH', 'PLANTS', 'CONDITIONS'], 0),
      gap(),
      cards([
        card(0, 'Stream silverfish', 'Common', 'KNOWN'),
        card(1, 'Redfin perch', 'Uncommon', 'KNOWN'),
        card(2, 'Mud whisker', 'Not studied', 'UNKNOWN'),
        card(3, 'Spiny sunlurker', 'Venomous spines', 'KNOWN'),
        card(4, 'Goldspot riverfish', 'Not discovered', 'UNKNOWN'),
      ]),
      gap(),
      notice(
        'Shape, fins and markings identify each species. Tap a card for handling and bait notes.',
      ),
    ]),
    icon: 'journal',
  ),
  '08-species-and-preparation': () => modal(
    'SPINY SUNLURKER',
    'SPECIES DETAILS · KNOWN',
    column([
      photo(3),
      gap(),
      notice(
        'TOXIC UNTIL PREPARED\nThe danger comes from its spines and unsafe handling.',
        warning: true,
      ),
      gap(),
      title('HOW TO HANDLE IT'),
      text(
        'Use a knife to remove the venomous spines, clean the fish, then cook it over the campfire. Cooking the whole fish alone is not enough.',
      ),
      gap(),
      title('PREFERRED HABITAT'),
      text('Shaded pools and slow, rocky river bends.'),
      gap(),
      row('Stone Knife', 'AVAILABLE', icon: 'stone_knife'),
      row('Raw fish in camp', '1', icon: 'small_fish'),
      gap(),
      button('VIEW PREPARATION'),
    ]),
  ),
  '09-prepare-fish': () => modal(
    'PREPARE SUNLURKER',
    'CAMP WORKSHOP · CONFIRM',
    column([
      photo(5),
      gap(),
      text(
        'Remove the spines and clean the fish before cooking. The prepared portion is stored in Items; it is not eaten automatically.',
      ),
      gap(),
      title('MATERIALS · HAVE / NEED'),
      row('Spiny Sunlurker', '1 / 1', icon: 'small_fish'),
      row('Firewood', '12 / 1', icon: 'wood'),
      row('Stone Knife', 'REQUIRED', icon: 'stone_knife'),
      const Divider(height: 20),
      row('Daylight cost', '1 time', icon: 'sun'),
      gap(),
      notice('Other active conditions still take their normal time cost.'),
      gap(),
      button('PREPARE FISH · 1 TIME'),
    ]),
    icon: 'stone_knife',
  ),
  '10-items-fish': () => modal(
    'ITEMS',
    'FOOD · YOUR STORED CATCH',
    column([
      shared.tabs(['MATERIALS', 'FOOD', 'GEAR'], 1),
      gap(),
      cards([
        card(0, 'Stream silverfish', 'Raw · cook at camp', '2 IN PACK'),
        card(1, 'Redfin perch', 'Raw · cook at camp', '1 IN PACK'),
        card(3, 'Spiny sunlurker', 'Knife required', '1 IN PACK'),
        card(5, 'Prepared fish', 'Ready to eat', '2 IN PACK'),
      ]),
      gap(),
      notice(
        'Raw, prepared and hazardous fish have text labels. Tap to inspect before using.',
      ),
    ]),
    icon: 'inventory',
  ),
  '11-rod-progression': () => modal(
    'FISHING GEAR',
    'THREE ROD LEVELS',
    column([
      cards([
        ParchmentCard(
          title: 'Basic Rod',
          art: 'basic_rod',
          info: 'Starting gear',
          status: 'OWNED',
          onTap: noop,
        ),
        ParchmentCard(
          title: 'Reinforced Rod',
          art: 'basic_rod',
          info: 'View upgrade',
          status: 'SELECTED',
          selected: true,
          onTap: noop,
        ),
        ParchmentCard(
          title: 'River Rod',
          art: 'basic_rod',
          info: 'Advanced craft',
          status: 'LOCKED',
          onTap: noop,
        ),
      ]),
      gap(),
      title('REINFORCED ROD'),
      text(
        'A stronger rod gives more control while reeling and can hold heavier fish. Bait still determines which species are attracted.',
      ),
      gap(),
      row('Safe zone', 'WIDER', icon: 'basic_rod'),
      row('Heavy fish', 'SUPPORTED', icon: 'small_fish'),
      row('Durability', '20 uses', icon: 'craft'),
      gap(),
      notice(
        'These are proposed gear properties. Upgrade costs and final values will be balanced together.',
      ),
      gap(),
      button('EQUIP REINFORCED ROD'),
    ]),
    icon: 'basic_rod',
  ),
  '12-unsafe-meal-confirmation': () => modal(
    'EAT WITHOUT PREPARING?',
    'KNOWN HAZARD · CONFIRM',
    column([
      photo(3),
      gap(),
      notice(
        'POISON RISK\nThis fish still has venomous spines. Eating it unprepared causes Poisoned II.',
        warning: true,
      ),
      gap(),
      text(
        'You have a knife at camp. Preparing the fish first avoids this preventable risk.',
      ),
      gap(),
      row('Consumes', '1 raw fish', icon: 'small_fish'),
      row('Daylight cost', 'No time', icon: 'sun'),
      gap(),
      button('PREPARE SAFELY'),
      gap(8),
      button('EAT UNPREPARED', secondary: true),
    ]),
  ),
  '13-illness-after-unsafe-meal': () => modal(
    'A DANGEROUS MEAL',
    'WHAT HAPPENED',
    column([
      Row(
        children: [
          const CardArt('poisoned', size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: column([
              const ParchmentLabel('POISONED II', size: 20, color: rust),
              const ParchmentLabel('4 time remaining', size: 12, color: muted),
            ]),
          ),
        ],
      ),
      gap(),
      text(
        'You ate the fish without removing its venomous spines. The toxin has taken hold.',
      ),
      gap(),
      title('ACTUAL CHANGES'),
      row('Food', '+8 · now 65', icon: 'food'),
      row('Spiny Sunlurker', '−1 · none left', icon: 'small_fish'),
      gap(),
      notice(
        'No health was lost while eating. Poison damages health when you next spend game time.',
        warning: true,
      ),
      gap(),
      title('RECOVERY'),
      text(
        'An antidote clears the poison. Bitter herbs can shorten it; healing alone will not remove it.',
      ),
      gap(),
      button('VIEW TREATMENT'),
      gap(8),
      button('CONTINUE', secondary: true),
    ]),
  ),
};

Widget catchResult(
  int index,
  String name,
  String rarity,
  String length,
  String weight,
  List<Widget> notes,
) => modal(
  'CATCH LANDED',
  rarity,
  column([
    photo(index),
    gap(10),
    ParchmentLabel(name, size: 21, align: TextAlign.center),
    gap(),
    Center(
      child: metrics([
        ('LENGTH', length),
        ('WEIGHT', weight),
        (
          'SIZE',
          index == 4
              ? 'LARGE'
              : index == 0
              ? 'SMALL'
              : 'MEDIUM',
        ),
      ]),
    ),
    gap(),
    ...notes,
    gap(),
    row('Pack capacity', '5 / 8 slots', icon: 'inventory'),
    gap(6),
    button('KEEP CATCH'),
    gap(7),
    button('RELEASE', secondary: true),
  ]),
);

class ReelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 8, size.width, 22),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xFFB5AA87),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .38, 8, size.width * .34, 22),
        const Radius.circular(5),
      ),
      paint..color = leaf,
    );
    canvas.drawLine(
      Offset(size.width * .54, 1),
      Offset(size.width * .54, 37),
      paint
        ..color = cream
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(ReelPainter old) => false;
}

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final codec = await tester.runAsync(
      () => ui.instantiateImageCodec(
        File('$folder/assets/fish-and-bait-atlas-v1.png').readAsBytesSync(),
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
      ('00a-fishing-and-catches', 'HORGÁSZAT ÉS FOGÁS', [0, 1, 2, 3, 4, 5]),
      (
        '00b-species-preparation-gear',
        'FAJISMERET, ÉTEL ÉS MÉRGEZÉS',
        [6, 7, 8, 9, 11, 12],
      ),
    ];
    for (final board in boards) {
      await render(
        Scaffold(
          backgroundColor: const Color(0xFF102A28),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: column([
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
                      child: column([
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
  atlas.dispose();
  keepAlive.cancel();
  exit(0);
}
