import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/game_engine.dart';
import '../game/gathering_session.dart';
import '../game/ecology_catalog.dart';
import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';
import 'card_art.dart';
import 'scene_artwork.dart';

class GatheringScreen extends StatefulWidget {
  const GatheringScreen({super.key, required this.game});
  final GameEngine game;
  @override
  State<GatheringScreen> createState() => _GatheringScreenState();
}

class _GatheringScreenState extends State<GatheringScreen>
    with SingleTickerProviderStateMixin {
  late final GatheringSession session = widget.game.gathering!;
  late final Ticker _ticker;
  late final AppLifecycleListener _lifecycle;
  final _plants = ScrollController();
  Duration? _last;
  Timer? _outcome;
  bool _inactive = false, _dialog = false, _leaving = false;
  int _savedSecond = 0;
  GameEngine get game => widget.game;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _inactive = state != AppLifecycleState.resumed;
        _last = null;
        if (_inactive) {
          game.pauseGathering(true);
          _ticker.stop();
          _outcome?.cancel();
        } else if (!_dialog && mounted) {
          if (session.complete) {
            _scheduleOutcome();
          } else if (session.paused) {
            unawaited(_pause());
          }
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (session.complete) {
        _scheduleOutcome();
      } else if (session.paused) {
        unawaited(_pause());
      } else if (session.active) {
        _ticker.start();
      }
    });
  }

  void _tick(Duration elapsed) {
    if (_inactive || _dialog || !session.active) {
      _last = null;
      return;
    }
    final previous = _last;
    _last = elapsed;
    if (previous == null) return;
    setState(
      () => game.tickGathering((elapsed - previous).inMicroseconds / 1000000),
    );
    if (session.elapsed.floor() > _savedSecond) {
      _savedSecond = session.elapsed.floor();
      game.saveGatheringProgress();
    }
    if (session.complete) {
      _ticker.stop();
      game.saveGatheringProgress();
      _scheduleOutcome();
    }
  }

  void _scheduleOutcome() {
    _outcome?.cancel();
    _outcome = Timer(const Duration(milliseconds: 600), () {
      if (mounted && !_inactive && !_dialog) _finish();
    });
  }

  void _begin() {
    if (_inactive || _dialog || !game.beginGathering()) return;
    if (game.gathering == null) {
      _exit();
      return;
    }
    setState(() {});
    _last = null;
    _ticker.start();
  }

  void _strike() {
    if (_inactive || _dialog || !game.strikeGathering()) return;
    setState(() {});
    if (session.complete) {
      _ticker.stop();
      _scheduleOutcome();
    }
  }

  void _finish({bool leave = false}) {
    if (_leaving || !game.finishGathering(leave: leave)) return;
    _exit();
  }

  void _exit([String? command]) {
    if (_leaving) return;
    setState(() => _leaving = true);
    Navigator.pop(context, command);
  }

  void _back([String? command]) {
    if (!game.cancelGathering()) return;
    _exit(command);
  }

  void _resume() {
    if (_inactive || session.complete) return;
    game.pauseGathering(false);
    _last = null;
    if (!_ticker.isActive) _ticker.start();
    setState(() {});
  }

  Future<void> _pause() async {
    if (_dialog || _leaving || session.stage != GatheringStage.active) return;
    game.pauseGathering(true);
    _ticker.stop();
    _last = null;
    _dialog = true;
    final command = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: CanopyDialog(
          title: 'Paused',
          art: session.kind.art,
          subtitle: 'TAKE YOUR TIME',
          actions: [
            ActionCard(
              key: const ValueKey('gathering-resume'),
              title: 'Resume',
              art: session.kind.art,
              horizontal: true,
              onTap: () => Navigator.pop(dialogContext, 'resume'),
            ),
            ActionCard(
              key: const ValueKey('gathering-pause-leave'),
              title: 'Leave attempt',
              art: 'back',
              tone: CardTone.river,
              horizontal: true,
              onTap: () => Navigator.pop(dialogContext, 'leave'),
            ),
          ],
          child: const Text(
            'Your attempt is on hold. The timer and target stop until you resume.',
          ),
        ),
      ),
    );
    if (!mounted) return;
    _dialog = false;
    if (command == 'leave') {
      await _askLeave(fromPause: true);
    } else if (!_inactive) {
      _resume();
    }
  }

  Future<void> _askLeave({bool fromPause = false}) async {
    if (_dialog || _leaving) return;
    if (session.stage == GatheringStage.ready) {
      _back();
      return;
    }
    if (session.complete) {
      _finish();
      return;
    }
    game.pauseGathering(true);
    _ticker.stop();
    _last = null;
    _dialog = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => CanopyConfirmation(
        title: 'Leave this attempt?',
        message: session.kind == GatheringKind.foraging
            ? 'Your picked plants will be resolved. The daylight already spent is not returned.'
            : 'This ends the attempt with its current progress. The daylight already spent is not returned.',
        confirm: 'Leave attempt',
        cancel: 'Keep playing',
        destructive: true,
        confirmKey: const ValueKey('gathering-confirm-leave'),
      ),
    );
    if (!mounted) return;
    _dialog = false;
    if (leave == true) {
      _finish(leave: true);
    } else if (fromPause || _inactive) {
      if (!_inactive) unawaited(_pause());
    } else {
      _resume();
    }
  }

  @override
  void dispose() {
    _outcome?.cancel();
    _lifecycle.dispose();
    _ticker.dispose();
    _plants.dispose();
    game.saveGatheringProgress();
    super.dispose();
  }

  String get _instruction => switch (session.kind) {
    GatheringKind.chopping => 'Tap when the marker reaches the center.',
    GatheringKind.foraging => 'Pick up to three plants. Look carefully.',
    GatheringKind.hunting => 'Throw when the boar crosses the target.',
  };
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    // The hunting scene is 941×1672; keep its sprite and target registered
    // to the full artwork when portrait backgrounds fit the screen width.
    final sceneBounds = landscape
        ? Offset.zero & size
        : Alignment.center.inscribe(
            Size(size.width, size.width * 1672 / 941),
            Offset.zero & size,
          );
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CanopyHud(state: game.state),
        const SizedBox(height: 8),
        CampPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.kind.title.toUpperCase(),
                style: const TextStyle(
                  color: CanopyColors.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 5),
              Text(_instruction, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
    final footer = _footer(context);
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_askLeave());
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: CanopyColors.background),
            RepaintBoundary(
              child: SceneArtwork(
                asset: 'assets/art/${session.kind.scene}.png',
              ),
            ),
            if (session.kind == GatheringKind.hunting)
              Positioned(
                top: sceneBounds.top + sceneBounds.height * .405,
                left: size.width * (.43 + session.marker * .25),
                width: size.width * .29,
                height: sceneBounds.height * .115,
                child: Image.asset(
                  'assets/art/hunting_boar_sprite_v2.png',
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
            if (session.kind == GatheringKind.hunting &&
                session.stage != GatheringStage.ready &&
                !landscape)
              Positioned(
                left: size.width * .7 - 29,
                top: sceneBounds.top + sceneBounds.height * .4625 - 17.5,
                child: Container(
                  key: const ValueKey('hunting-scene-target'),
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
              minimum: const EdgeInsets.all(12),
              child: landscape
                  ? Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: 330,
                            child: SingleChildScrollView(child: header),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            width: 340,
                            child: SingleChildScrollView(child: footer),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: CanopySceneBody(
                          padding: EdgeInsets.zero,
                          header: header,
                          footer: footer,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final ready = session.stage == GatheringStage.ready;
    final available = session.active && !_dialog && !_inactive;
    final reason = game.gatheringBlockReason(session.kind);
    if (ready) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CampPanel(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CardArt(session.kind.art, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason ??
                        '${session.kind == GatheringKind.foraging ? 'Gather by hand · knife opens more plants' : '${itemName(session.kind.art)} · ${game.state.toolCondition(session.kind.art)}/${RunState.toolDurability[session.kind.art]}'}\nStart uses ${game.gatheringCost} time.${session.kind != GatheringKind.foraging && session.windowScale < 1 ? '\nConditions narrow the timing zone for this attempt.' : ''}',
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(160.0, (constraints.maxWidth - 10) / 2);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: width,
                    child: ActionCard(
                      key: const ValueKey('gathering-start'),
                      title: 'Start',
                      art: session.kind.art,
                      tag: reason == null ? 'READY' : null,
                      compact: true,
                      fixedHeight: large ? 200 : 176,
                      locked: reason != null,
                      onTap: reason == null ? _begin : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: width,
                    child: ActionCard(
                      key: const ValueKey('gathering-back'),
                      title: reason == null ? 'Back' : 'Workshop',
                      art: reason == null ? 'back' : 'craft',
                      tone: CardTone.river,
                      tag: reason == null ? 'LEAVE' : 'CRAFT TOOL',
                      compact: true,
                      fixedHeight: large ? 200 : 176,
                      onTap: reason == null ? _back : () => _back('workshop'),
                    ),
                  ),
                ],
              );
            },
          ),
          if (reason != null)
            TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('BACK'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.lastQuality != null &&
            (session.feedbackLeft > 0 || session.complete)) ...[
          Semantics(
            liveRegion: true,
            child: CampPanel(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                session.lastQuality!.name.toUpperCase(),
                style: TextStyle(
                  color: session.lastQuality == TimingQuality.miss
                      ? CanopyColors.health
                      : CanopyColors.leaf,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        CampPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (session.kind == GatheringKind.foraging)
                    const Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: CanopyColors.gold,
                    ),
                  if (session.kind == GatheringKind.foraging)
                    const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.kind == GatheringKind.foraging
                          ? '${session.remaining.ceil()}s'
                          : session.kind == GatheringKind.chopping
                          ? 'SWING ${math.min(3, session.hits.length + 1)} OF 3'
                          : 'WAIT FOR THE TARGET',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    session.kind == GatheringKind.foraging
                        ? '${session.picked.length}/3 PICKED'
                        : '${session.remaining.ceil()}s',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (session.kind == GatheringKind.foraging)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: session.remaining / session.duration,
                    minHeight: 6,
                    color: CanopyColors.gold,
                    backgroundColor: CanopyColors.panelLight,
                  ),
                )
              else
                Semantics(
                  label: 'Timing marker',
                  value: session.currentQuality.name,
                  child: SizedBox(
                    height: 35,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TimingPainter(
                        session.marker,
                        session.windowScale,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (session.kind == GatheringKind.foraging)
          _plantRow(available, large)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: ActionCard(
              key: const ValueKey('gathering-strike'),
              title: session.kind == GatheringKind.chopping ? 'Chop' : 'Throw',
              art: session.kind.art,
              horizontal: true,
              showStatus: false,
              onTap: available && session.feedbackLeft <= 0 ? _strike : null,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (session.kind == GatheringKind.foraging) ...[
              IconButton(
                key: const ValueKey('plants-previous'),
                onPressed: () => _scrollPlants(-1),
                tooltip: 'Previous plants',
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                key: const ValueKey('plants-next'),
                onPressed: () => _scrollPlants(1),
                tooltip: 'Next plants',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey('gathering-pause'),
                onPressed: available ? _pause : null,
                tooltip: 'Pause',
                icon: const Icon(Icons.pause_rounded),
              ),
            ] else
              Expanded(
                child: TextButton.icon(
                  key: const ValueKey('gathering-pause'),
                  onPressed: available ? _pause : null,
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  label: const Text('PAUSE', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('gathering-finish'),
                onPressed: available
                    ? session.kind == GatheringKind.foraging
                          ? _finish
                          : _askLeave
                    : null,
                icon: Icon(
                  session.kind == GatheringKind.foraging
                      ? Icons.check_rounded
                      : Icons.arrow_back_rounded,
                  size: 18,
                ),
                label: Text(
                  session.kind == GatheringKind.foraging ? 'FINISH' : 'LEAVE',
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

  void _scrollPlants(int direction) {
    if (!_plants.hasClients) return;
    final offset =
        (_plants.offset + direction * _plants.position.viewportDimension * .65)
            .clamp(0.0, _plants.position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _plants.jumpTo(offset);
    } else {
      unawaited(
        _plants.animateTo(
          offset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  Widget _plantRow(bool available, bool large) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(160.0, (constraints.maxWidth - 20) / 3);
      final height = large ? 240.0 : 190.0;
      return SizedBox(
        height: height,
        child: ListView.separated(
          controller: _plants,
          scrollDirection: Axis.horizontal,
          itemCount: session.availablePlants.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final id = session.availablePlants[index];
            final selected = session.picked.contains(id);
            final block = GatheringSession.plantBlock(id, game.state.tools);
            final full = session.picked.length >= 3;
            return SizedBox(
              width: width,
              child: ActionCard(
                key: ValueKey('plant-$id'),
                title:
                    jungleFoods[id]?.name ??
                    switch (id) {
                      'berries' => 'Berries',
                      'fiber' => 'Fiber',
                      'herb' => 'Herb',
                      'mushroom' => 'Mushrooms',
                      _ => 'Unknown plant',
                    },
                art: id == 'berries' ? 'forage' : id,
                image: id == 'mushroom' || id == 'unknown_plant'
                    ? 'assets/art/${id}_card_scene_v1.png'
                    : null,
                description: block,
                tag: selected ? 'SELECTED' : 'PICK',
                selected: selected,
                compact: true,
                fixedHeight: height,
                titleMaxLines: 2,
                descriptionMaxLines: 2,
                locked: block != null,
                onTap: available && block == null && !full && !selected
                    ? () {
                        if (game.pickGatheringPlant(id)) setState(() {});
                      }
                    : selected
                    ? () {}
                    : null,
              ),
            );
          },
        ),
      );
    },
  );
}

class _TimingPainter extends CustomPainter {
  const _TimingPainter(this.marker, this.scale);
  final double scale;
  final double marker;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 3, size.width, 14),
        const Radius.circular(6),
      ),
      Paint()..color = CanopyColors.panelLight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (.5 - .18 * scale),
          3,
          size.width * .36 * scale,
          14,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = CanopyColors.leaf,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * (.5 - .06 * scale),
        3,
        size.width * .12 * scale,
        14,
      ),
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
  bool shouldRepaint(_TimingPainter oldDelegate) =>
      oldDelegate.marker != marker || oldDelegate.scale != scale;
}
