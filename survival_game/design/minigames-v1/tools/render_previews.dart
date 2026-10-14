// Design-only native Flutter preview exporter. No GameEngine mutations.
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/camp_widgets.dart';
import 'package:survival_game/ui/canopy_components.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/event_dialog.dart';

import '../../../screenshots/tools/capture_fonts.dart';

const designRoot = 'design/minigames-v1';
void previewTap() {}

enum Mini { chopping, foraging, hunting }

extension MiniCopy on Mini {
  String get title => switch (this) {
    Mini.chopping => 'WOOD CHOPPING',
    Mini.foraging => 'FORAGING',
    Mini.hunting => 'HUNTING',
  };
  String get tool => switch (this) {
    Mini.chopping => 'Stone axe',
    Mini.foraging => 'Stone knife',
    Mini.hunting => 'Stone spear',
  };
  String get art => switch (this) {
    Mini.chopping => 'stone_axe',
    Mini.foraging => 'stone_knife',
    Mini.hunting => 'stone_spear',
  };
  String get background => switch (this) {
    Mini.chopping => 'wood_chopping_background_v1',
    Mini.foraging => 'foraging_background_v1',
    Mini.hunting => 'hunting_background_v1',
  };
  String get instruction => switch (this) {
    Mini.chopping => 'Tap when the marker reaches the center.',
    Mini.foraging => 'Pick up to three plants. Look carefully.',
    Mini.hunting => 'Throw when the boar crosses the target.',
  };
}

class Preview extends StatelessWidget {
  const Preview(this.mini, this.state, {super.key});
  final Mini mini;
  final String state;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final ready = state == 'ready' || state == 'locked';
    final feedback = state == 'perfect' || state == 'miss';
    final footer = Footer(mini, state, ready: ready);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File('$designRoot/assets/${mini.background}.png'),
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          if (mini == Mini.hunting)
            Positioned(
              top: size.height * .405,
              left: size.width * (state == 'miss' ? .70 : .52),
              width: size.width * .29,
              height: size.height * .115,
              child: Image.file(
                File('$designRoot/assets/hunting_boar_sprite_v2.png'),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55102926),
                  Colors.transparent,
                  Color(0xAA102926),
                ],
                stops: [0, .4, 1],
              ),
            ),
          ),
          if (mini == Mini.hunting && !ready && !landscape)
            Positioned(
              left: size.width * .57,
              top: size.height * .438,
              child: Container(
                width: 58,
                height: 35,
                decoration: BoxDecoration(
                  border: Border.all(color: CanopyColors.cream, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.add,
                  color: CanopyColors.cream,
                  size: 18,
                ),
              ),
            ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: landscape
                ? Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(width: 330, child: header(context)),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: SizedBox(width: 340, child: footer),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      header(context),
                      const Spacer(),
                      if (feedback) ...[
                        feedbackChip(),
                        const SizedBox(height: 12),
                      ],
                      footer,
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget header(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      CanopyHud(
        state: RunState(
          day: 4,
          timeLeft: state == 'ready' || state == 'locked' ? 4 : 3,
          resources: {'wood': 14, 'stone': 3, 'fiber': 8},
          stats: {
            SurvivalStat.health: 100,
            SurvivalStat.water: 70,
            SurvivalStat.food: 65,
            SurvivalStat.sanity: 82,
          },
        ),
      ),
      const SizedBox(height: 8),
      CampPanel(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mini.title,
              style: const TextStyle(
                color: CanopyColors.gold,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 5),
            Text(mini.instruction, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ],
  );

  Widget feedbackChip() => CampPanel(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          state == 'perfect' ? Icons.check_circle_rounded : Icons.close_rounded,
          color: state == 'perfect' ? CanopyColors.leaf : CanopyColors.health,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          state == 'perfect'
              ? 'PERFECT!'
              : mini == Mini.hunting
              ? 'MISS · THE BOAR ESCAPED'
              : 'MISS · TRY THE NEXT SWING',
          style: TextStyle(
            color: state == 'perfect' ? CanopyColors.leaf : CanopyColors.health,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class Footer extends StatelessWidget {
  const Footer(this.mini, this.state, {required this.ready, super.key});
  final Mini mini;
  final String state;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(14) > 19;
    if (ready) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CampPanel(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CardArt(mini.art, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state == 'locked'
                        ? 'Requires ${mini.tool.toLowerCase()}.'
                        : '${mini.tool} · 8/10\nStart uses 1 time.',
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: min(160, (MediaQuery.sizeOf(context).width - 36) / 2),
                child: ActionCard(
                  title: 'Start',
                  art: mini.art,
                  tag: state == 'locked' ? null : 'READY',
                  compact: true,
                  fixedHeight: scaled ? 200 : 176,
                  locked: state == 'locked',
                  onTap: state == 'locked' ? null : previewTap,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: min(160, (MediaQuery.sizeOf(context).width - 36) / 2),
                child: ActionCard(
                  title: state == 'locked' ? 'Workshop' : 'Back',
                  art: state == 'locked' ? 'craft' : 'back',
                  tone: CardTone.river,
                  tag: state == 'locked' ? 'CRAFT TOOL' : 'LEAVE',
                  compact: true,
                  fixedHeight: scaled ? 200 : 176,
                  onTap: previewTap,
                ),
              ),
            ],
          ),
          if (state == 'locked')
            TextButton.icon(
              onPressed: previewTap,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('BACK', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mini == Mini.foraging) ...[
          forageMeter(),
          const SizedBox(height: 8),
          PlantRow(state, tall: scaled),
          const SizedBox(height: 6),
        ] else ...[
          CampPanel(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mini == Mini.chopping
                          ? 'SWING 2 OF 3'
                          : 'WAIT FOR THE TARGET',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    CardArt(mini.art, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 35,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: TimingPainter(
                      marker: state == 'perfect'
                          ? .5
                          : state == 'miss'
                          ? .85
                          : .36,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: ActionCard(
              title: mini == Mini.chopping ? 'Chop' : 'Throw',
              art: mini.art,
              horizontal: true,
              showStatus: false,
              onTap: previewTap,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (mini == Mini.foraging) ...[
              IconButton(
                onPressed: previewTap,
                tooltip: 'Previous plants',
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                onPressed: previewTap,
                tooltip: 'Next plants',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: previewTap,
                tooltip: 'Pause',
                icon: const Icon(Icons.pause_rounded),
              ),
            ] else
              Expanded(
                child: TextButton.icon(
                  onPressed: previewTap,
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  label: const Text('PAUSE', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: previewTap,
                icon: Icon(
                  mini == Mini.foraging
                      ? Icons.check_rounded
                      : Icons.arrow_back_rounded,
                  size: 18,
                ),
                label: Text(
                  mini == Mini.foraging ? 'FINISH' : 'LEAVE',
                  style: const TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget forageMeter() => CampPanel(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.timer_outlined, color: CanopyColors.gold, size: 20),
        const SizedBox(width: 6),
        const Text(
          '6s',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const LinearProgressIndicator(
              value: .75,
              minHeight: 6,
              color: CanopyColors.gold,
              backgroundColor: CanopyColors.panelLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          state == 'selected' ? '1/3 PICKED' : '0/3 PICKED',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class PlantRow extends StatelessWidget {
  const PlantRow(this.state, {required this.tall, super.key});
  final String state;
  final bool tall;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = min(160.0, (constraints.maxWidth - 20) / 3);
      final second = state == 'page-two';
      final plants = second
          ? [
              ('Herb', 'herb', false),
              ('Mushrooms', 'mushroom', false),
              ('Unknown plant', 'unknown_plant', true),
            ]
          : [
              ('Berries', 'forage', false),
              ('Fiber', 'fiber', false),
              ('Herb', 'herb', false),
            ];
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < plants.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            SizedBox(
              width: width,
              child: ActionCard(
                title: plants[i].$1,
                art: plants[i].$2,
                artWidget: second && i > 0
                    ? Image.file(
                        File(
                          '$designRoot/assets/${plants[i].$2 == 'mushroom' ? 'mushroom' : 'unknown_plant'}_card_scene_v1.png',
                        ),
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      )
                    : null,
                description: plants[i].$3 ? 'Machete required' : null,
                tag: state == 'selected' && i == 0 ? 'SELECTED' : 'PICK',
                selected: state == 'selected' && i == 0,
                compact: true,
                fixedHeight: tall ? 220 : 166,
                titleMaxLines: 2,
                descriptionMaxLines: 2,
                locked: plants[i].$3,
                onTap: plants[i].$3 ? null : previewTap,
              ),
            ),
          ],
        ],
      );
    },
  );
}

class TimingPainter extends CustomPainter {
  const TimingPainter({required this.marker});
  final double marker;
  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 3, size.width, 14),
      const Radius.circular(6),
    );
    canvas.drawRRect(bar, Paint()..color = CanopyColors.panelLight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .35, 3, size.width * .3, 14),
        const Radius.circular(4),
      ),
      Paint()..color = CanopyColors.leaf,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .465, 3, size.width * .07, 14),
      Paint()..color = CanopyColors.gold,
    );
    canvas.drawLine(
      Offset(size.width * marker, 0),
      Offset(size.width * marker, 21),
      Paint()
        ..color = CanopyColors.cream
        ..strokeWidth = 3,
    );
    final text = TextPainter(
      text: const TextSpan(
        text: 'GOOD     PERFECT     GOOD',
        style: TextStyle(
          fontFamily: 'Arial',
          color: CanopyColors.cream,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset((size.width - text.width) / 2, 24));
  }

  @override
  bool shouldRepaint(TimingPainter oldDelegate) => oldDelegate.marker != marker;
}

Widget popup(Mini mini, String state) {
  if (state == 'pause') {
    return CanopyDialog(
      title: 'Paused',
      art: mini.art,
      subtitle: 'TAKE YOUR TIME',
      actions: [
        ActionCard(
          title: 'Resume',
          art: mini.art,
          horizontal: true,
          onTap: previewTap,
        ),
        ActionCard(
          title: 'Leave attempt',
          art: 'back',
          tone: CardTone.river,
          horizontal: true,
          onTap: previewTap,
        ),
      ],
      child: const Text(
        'Your attempt is on hold. The timer and target stop until you resume.',
      ),
    );
  }
  if (state == 'leave') {
    return CanopyConfirmation(
      title: 'Leave this attempt?',
      message: mini == Mini.foraging
          ? 'Your picked plants will be resolved. The time spent starting this attempt is not returned.'
          : 'This ends the attempt with its current progress. The time already spent is not returned.',
      confirm: 'Leave attempt',
      cancel: 'Keep playing',
      destructive: true,
    );
  }
  final failure = state == 'failure-result';
  final risky = state == 'risky-result';
  final timeout = state == 'timeout';
  final title = switch (mini) {
    Mini.chopping => failure ? 'A rough cut' : 'Clean cuts',
    Mini.foraging =>
      risky
          ? 'A bitter discovery'
          : timeout
          ? 'Time is up'
          : 'Gathered from the grove',
    Mini.hunting => failure ? 'The boar escaped' : 'A well-timed throw',
  };
  final body = switch (mini) {
    Mini.chopping =>
      failure
          ? 'The axe slipped twice. You recovered a little wood. Axe durability: 8 → 5.'
          : 'Two clean swings and one perfect cut. The logs are ready to carry. Axe durability: 8 → 7.',
    Mini.foraging =>
      risky
          ? 'The unfamiliar berries were irritating. You lost some health, but kept the useful fiber you picked.'
          : timeout
          ? 'The gathering window ended. The plants you already picked have been collected.'
          : 'You picked ripe berries and fresh herbs, leaving the unfamiliar plant alone.',
    Mini.hunting =>
      failure
          ? 'Your spear landed wide and the boar fled. You brought back no meat. Spear durability: 8 → 7.'
          : 'Your spear hit cleanly. You brought fresh meat back from the clearing. Spear durability: 8 → 7.',
  };
  final changes = switch (mini) {
    Mini.chopping => {'wood': failure ? 1 : 5, 'Water': -3, 'Food': -2},
    Mini.foraging =>
      risky
          ? {'Health': -8, 'fiber': 2, 'Water': -2}
          : timeout
          ? {'fiber': 2, 'Water': -2}
          : {'Food': 6, 'herb': 1, 'Water': -2},
    Mini.hunting =>
      failure
          ? {'Water': -4, 'Food': -3}
          : {'raw_meat': 3, 'Water': -4, 'Food': -3},
  };
  return OutcomeDialog(
    report: ActionReport.saved(title: title, body: body, changes: changes),
    nightNext: false,
  );
}

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
  final directory = Directory('$designRoot/screens')
    ..createSync(recursive: true);
  final manifest = <String>[];
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    final key = GlobalKey();
    var number = 0;
    Future<void> capture(
      Mini mini,
      String state, {
      Size size = const Size(390, 844),
      double scale = 1,
      String? suffix,
    }) async {
      await binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final modal = [
        'result',
        'failure-result',
        'risky-result',
        'timeout',
        'pause',
        'leave',
      ].contains(state);
      final baseState = modal ? 'active' : state;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: canopyTheme,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 20),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Preview(mini, baseState),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold));
        await precacheImage(
          FileImage(File('$designRoot/assets/${mini.background}.png')),
          context,
        );
        if (mini == Mini.hunting) {
          await precacheImage(
            FileImage(File('$designRoot/assets/hunting_boar_sprite_v2.png')),
            context,
          );
        }
        for (final name in [
          'hud_atlas.png',
          'card_art_atlas_v2.png',
          'camp_objects_atlas.png',
          'card_foliage_backdrop_v1.png',
          'card_${mini.art}_scene_v1.png',
          'card_back_scene_v1.png',
          'card_craft_scene_v1.png',
          'card_forage_scene_v1.png',
          'card_fiber_scene_v1.png',
          'card_herb_scene_v1.png',
        ]) {
          await precacheImage(AssetImage('assets/art/$name'), context);
        }
        for (final name in [
          'mushroom_card_scene_v1',
          'unknown_plant_card_scene_v1',
        ]) {
          await precacheImage(
            FileImage(File('$designRoot/assets/$name.png')),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      if (modal) {
        final context = tester.element(find.byType(Scaffold));
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => popup(mini, state),
          ),
        );
        await tester.pumpAndSettle();
      }
      final error = tester.takeException();
      if (error != null) throw StateError('$mini/$state: $error');
      final name =
          '${(++number).toString().padLeft(2, '0')}-${mini.name}-${suffix ?? state}';
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final picture = await boundary.toImage(pixelRatio: 2);
        final data = await picture.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${directory.path}/$name.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        picture.dispose();
      });
      manifest.add('$name.png');
      stdout.writeln('CAPTURED $name');
    }

    for (final mini in Mini.values) {
      for (final state in [
        'ready',
        'active',
        if (mini == Mini.foraging) ...[
          'selected',
          'page-two',
        ] else ...[
          'perfect',
          'miss',
        ],
        'result',
        if (mini == Mini.foraging) ...[
          'risky-result',
          'timeout',
        ] else
          'failure-result',
        'pause',
        'leave',
        'locked',
      ]) {
        await capture(mini, state);
      }
    }
    for (final mini in Mini.values) {
      await capture(
        mini,
        'active',
        size: const Size(375, 812),
        suffix: 'small-phone',
      );
      await capture(
        mini,
        'active',
        size: const Size(844, 390),
        suffix: 'landscape',
      );
      await capture(mini, 'active', scale: 1.5, suffix: 'large-text');
    }
    File(
      '$designRoot/screens/manifest.txt',
    ).writeAsStringSync('${manifest.join('\n')}\n');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  keepAlive.cancel();
  stdout.writeln('EXPORTED ${manifest.length} DESIGN PREVIEWS');
  exit(0);
}
