import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/fishing_session.dart';
import '../feedback/haptics_controller.dart';
import '../feedback/haptics_scope.dart';
import '../game/game_engine.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'card_art.dart';
import 'canopy_theme.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key, required this.game});
  final GameEngine game;
  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen>
    with SingleTickerProviderStateMixin {
  late final FishingSession session = widget.game.fishing!;
  late final Ticker _ticker;
  late final AppLifecycleListener _lifecycle;
  Duration? _last;
  bool _inactive = false;
  bool _confirming = false;
  bool _leaving = false;

  Future<void> _showTutorial() async {
    if (_confirming || _leaving) return;
    _confirming = true;
    final wasTicking = _ticker.isActive;
    if (wasTicking) _ticker.stop();
    session.holding = false;
    _last = null;
    await showDialog<void>(
      context: context,
      builder: (_) => const FishingTutorial(),
    );
    if (!mounted) return;
    _confirming = false;
    _last = null;
    if (wasTicking && !_inactive && !session.complete) _ticker.start();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy ticker would first be built inside dispose()
    // when the player leaves before casting.
    _ticker = createTicker(_tick);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _inactive = state != AppLifecycleState.resumed;
        _last = null;
        if (_inactive) {
          session.holding = false;
          if (_ticker.isActive) _ticker.stop();
        } else if (!_confirming &&
            !session.complete &&
            session.stage != FishingStage.ready &&
            !_ticker.isActive) {
          _ticker.start();
        }
      },
    );
  }

  void _tick(Duration elapsed) {
    if (_inactive || _confirming) {
      _last = null;
      return;
    }
    final previous = _last;
    _last = elapsed;
    if (previous == null) return;
    final dt = ((elapsed - previous).inMicroseconds / 1000000).clamp(0.0, .1);
    final stage = session.stage;
    setState(() => session.update(dt));
    if (stage != session.stage) {
      if (session.stage == FishingStage.bite ||
          session.stage == FishingStage.caught) {
        HapticsScope.of(context)?.pulse(HapticCue.success);
      } else if (session.stage == FishingStage.escaped) {
        HapticsScope.of(context)?.pulse(HapticCue.warning);
      }
    }
    if (session.complete) _ticker.stop();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _cast() {
    if (!widget.game.castLine()) return;
    setState(() {});
    _last = null;
    _ticker.start();
  }

  void _hold(bool value) {
    if (session.stage != FishingStage.reeling || _inactive || _confirming) {
      return;
    }
    if (session.holding == value) return;
    if (value) HapticsScope.of(context)?.pulse(HapticCue.selection);
    setState(() => session.holding = value);
  }

  void _return({bool abandon = false}) {
    if (_leaving || !widget.game.finishFishing(abandon: abandon)) return;
    _leaving = true;
    Navigator.pop(context);
  }

  Future<void> _askLeave() async {
    if (_confirming || _leaving) return;
    if (session.complete) {
      _return();
      return;
    }
    _confirming = true;
    final wasTicking = _ticker.isActive;
    if (wasTicking) _ticker.stop();
    session.holding = false;
    _last = null;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => CanopyConfirmation(
        title: 'Return to camp?',
        art: 'basic_rod',
        message: session.stage == FishingStage.ready
            ? 'The round trip has used 2 daylight. Your bait will be kept.'
            : 'This ends your cast without a catch. Daylight and bait are already spent.',
        confirm: 'Return',
        cancel: 'Stay',
        confirmKey: const ValueKey('fishing-exit-confirm'),
      ),
    );
    if (!mounted) return;
    _confirming = false;
    _last = null;
    if (leave == true) {
      _return(abandon: true);
    } else {
      if (wasTicking && !_inactive && !session.complete) _ticker.start();
      setState(() {});
    }
  }

  String get _instruction => switch (session.stage) {
    FishingStage.ready => 'Cast your line',
    FishingStage.waiting => 'Waiting for a bite…',
    FishingStage.bite => 'A bite! Hook it now!',
    FishingStage.reeling => 'Keep the marker in the green zone',
    FishingStage.caught =>
      session.quality == CatchQuality.perfect
          ? 'Perfect catch!'
          : 'Fish caught!',
    FishingStage.escaped => 'The fish got away',
  };

  @override
  Widget build(BuildContext context) {
    final large =
        MediaQuery.textScalerOf(context).scale(14) > 19 ||
        MediaQuery.sizeOf(context).width < 360;
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_askLeave());
      },
      child: Scaffold(
        body: CanopyBackdrop(
          background: 'assets/art/fishing_pond.png',
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: CanopySceneBody(
                  header: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CanopyHud(state: widget.game.state),
                      const SizedBox(height: 10),
                      CampPanel(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: CanopyTitle(
                                title: 'Fishing Pond',
                                art: 'basic_rod',
                                subtitle:
                                    'Basic Rod · Bait ${widget.game.state.resource('bait')} · one cast per trip',
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('fishing-help'),
                              tooltip: 'How to fish · free practice',
                              onPressed: _showTutorial,
                              icon: const Icon(Icons.help_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  footer: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statusPanel(),
                      const SizedBox(height: 8),
                      CardDeck(
                        cards: [
                          if (session.stage == FishingStage.ready)
                            ActionCard(
                              key: const ValueKey('cast-line'),
                              title: 'Cast line',
                              art: 'basic_rod',
                              compact: true,
                              horizontal: large,
                              tag: '1 BAIT',
                              description:
                                  widget.game.state.resource('bait') < 1
                                  ? 'Need 1 bait'
                                  : 'Watch for a bite',
                              onTap: widget.game.state.resource('bait') >= 1
                                  ? _cast
                                  : null,
                            ),
                          if (session.stage == FishingStage.bite)
                            ActionCard(
                              key: const ValueKey('hook-fish'),
                              title: 'Hook!',
                              art: 'basic_rod',
                              compact: true,
                              horizontal: large,
                              tag: 'BITE',
                              description: 'Tap now to hook the fish',
                              onTap: () {
                                if (session.hook()) {
                                  HapticsScope.of(
                                    context,
                                  )?.pulse(HapticCue.light);
                                  setState(() {});
                                }
                              },
                            ),
                          if (session.stage == FishingStage.waiting)
                            ActionCard(
                              key: const ValueKey('waiting-for-fish'),
                              title: 'Waiting…',
                              art: 'basic_rod',
                              compact: true,
                              horizontal: large,
                              tag: 'WATCH THE LINE',
                              description: 'Hook when the fish bites',
                            ),
                          if (session.stage == FishingStage.reeling)
                            _ReelControl(
                              holding: session.holding,
                              onHold: _hold,
                              horizontal: large,
                            ),
                          ActionCard(
                            key: const ValueKey('fishing-return'),
                            title: session.complete
                                ? 'Return to camp'
                                : 'Leave',
                            art: 'back',
                            tone: CardTone.river,
                            compact: true,
                            horizontal: large,
                            description: session.complete
                                ? (session.stage == FishingStage.caught
                                      ? 'Carry your catch home'
                                      : 'Try again next trip')
                                : 'Return to camp',
                            onTap: session.complete
                                ? () => _return()
                                : _askLeave,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPanel() => CampPanel(
    padding: const EdgeInsets.all(10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            _instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: session.stage == FishingStage.bite
                  ? CanopyColors.gold
                  : CanopyColors.cream,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (session.stage == FishingStage.ready)
          Column(
            children: [
              const _FishingSteps(compact: true),
              TextButton.icon(
                key: const ValueKey('fishing-practice'),
                onPressed: _showTutorial,
                icon: const Icon(Icons.touch_app, size: 20),
                label: const Text('Try it first · no bait needed'),
              ),
            ],
          ),
        if (session.stage == FishingStage.waiting)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardArt('bait', size: 32),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Watch the line. Be ready to hook!',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        if (session.stage == FishingStage.bite)
          LinearProgressIndicator(
            value: session.remaining / FishingSession.biteWindow,
            color: CanopyColors.gold,
            minHeight: 7,
            borderRadius: BorderRadius.circular(4),
          ),
        if (session.stage == FishingStage.reeling) ...[
          SizedBox(height: 42, child: _ReelMeter(session: session)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: session.progress,
            color: CanopyColors.water,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: 'Catch progress',
            semanticsValue: '${(session.progress * 100).round()}',
          ),
          const SizedBox(height: 5),
          Text(
            'Catch ${(session.progress * 100).round()}% · ${session.remaining.toStringAsFixed(1)}s',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            session.inZone
                ? 'In the green! Follow the fish to fill the catch bar.'
                : session.cursor < session.target
                ? 'HOLD the reel button → move into the green'
                : 'RELEASE the reel button ← move into the green',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: CanopyColors.cream),
          ),
        ],
        if (session.complete)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardArt(
                session.stage == FishingStage.caught ? 'small_fish' : 'water',
                size: 48,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  session.stage == FishingStage.caught
                      ? '+${session.quality == CatchQuality.perfect ? 2 : 1} Small Fish\nCook your catch in the camp inventory.'
                      : 'Try again on your next trip. The bait was used.',
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

class _FishingSteps extends StatelessWidget {
  const _FishingSteps({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (icon, title, text) in [
        (
          Icons.phishing,
          '1 · Cast',
          compact ? 'Wait for a bite.' : 'Cast the line, then wait for a bite.',
        ),
        (
          Icons.touch_app,
          '2 · Hook',
          compact
              ? 'Tap HOOK when “A bite!” appears.'
              : 'When “A bite!” appears, tap HOOK within 2 seconds.',
        ),
        (
          Icons.swap_horiz,
          '3 · Reel',
          compact
              ? 'White bar = you. Hold →, release ←; stay in green.'
              : 'White bar = you. Green zone = fish. Hold to move right; release to move left. Stay in green until the catch bar fills.',
        ),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: CanopyColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$title  ',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// A separate simulation: learning never spends bait, daylight or awards loot.
/// The practice bite waits for input, so the instructions can be read calmly.
class FishingTutorial extends StatefulWidget {
  const FishingTutorial({super.key});
  @override
  State<FishingTutorial> createState() => FishingTutorialState();
}

class FishingTutorialState extends State<FishingTutorial>
    with SingleTickerProviderStateMixin {
  FishingSession? _practice;
  late final Ticker _ticker;
  late final AppLifecycleListener _lifecycle;
  Duration? _last;
  bool _inactive = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final previous = _last;
      _last = elapsed;
      if (previous == null || _inactive) return;
      setState(
        () => _practice!.update(
          ((elapsed - previous).inMicroseconds / 1000000).clamp(0.0, .1),
        ),
      );
      if (_practice!.stage == FishingStage.bite || _practice!.complete) {
        _ticker.stop();
        _last = null;
      }
    });
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _inactive = state != AppLifecycleState.resumed;
        _last = null;
        if (_inactive) {
          _practice?.holding = false;
          _ticker.stop();
        } else if (_practice?.stage == FishingStage.waiting ||
            _practice?.stage == FishingStage.reeling) {
          _ticker.start();
        }
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _cast() {
    setState(() => _practice = FishingSession()..cast());
    _last = null;
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    final practice = _practice;
    return CanopyDialog(
      title: 'How to fish',
      art: 'basic_rod',
      subtitle: 'Free practice · no bait or daylight used',
      actions: [
        if (practice == null || practice.complete)
          ActionCard(
            key: const ValueKey('practice-cast'),
            title: practice == null ? 'Practice casting' : 'Practice again',
            art: 'basic_rod',
            horizontal: true,
            onTap: _cast,
          ),
        if (practice?.stage == FishingStage.bite)
          ActionCard(
            key: const ValueKey('practice-hook'),
            title: 'Hook!',
            art: 'basic_rod',
            horizontal: true,
            onTap: () {
              if (!practice!.hook()) return;
              setState(() {});
              _last = null;
              _ticker.start();
            },
          ),
        if (practice?.stage == FishingStage.reeling)
          _ReelControl(
            holding: practice!.holding,
            horizontal: true,
            onHold: (value) {
              if (!_inactive) setState(() => practice.holding = value);
            },
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (practice == null) ...[
            const _FishingSteps(),
            const SizedBox(height: 12),
            SizedBox(height: 42, child: _ReelMeter(session: FishingSession())),
            const SizedBox(height: 6),
            const Text(
              'White bar: YOU  ·  Green zone: FISH',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ] else ...[
            Text(
              switch (practice.stage) {
                FishingStage.waiting => '1 · Watch the line. Wait for a bite…',
                FishingStage.bite =>
                  '2 · A bite! Tap HOOK.\nPractice waits for you; a real bite lasts 2 seconds.',
                FishingStage.reeling =>
                  practice.inZone
                      ? '3 · Stay in green. Alternate holding and releasing to follow the fish.'
                      : practice.cursor < practice.target
                      ? 'HOLD → move your white bar right'
                      : 'RELEASE ← move your white bar left',
                FishingStage.caught =>
                  'You caught it! You are ready for the pond.',
                FishingStage.escaped =>
                  'Try again. Follow the green zone; holding all the time will lose the fish.',
                FishingStage.ready => 'Cast to start',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (practice.stage == FishingStage.reeling ||
                practice.complete) ...[
              const SizedBox(height: 12),
              SizedBox(height: 42, child: _ReelMeter(session: practice)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: practice.progress,
                color: CanopyColors.water,
                minHeight: 8,
              ),
              const SizedBox(height: 6),
              Text(
                'Catch ${(practice.progress * 100).round()}%',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReelMeter extends StatelessWidget {
  const _ReelMeter({required this.session});
  final FishingSession session;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Fishing control',
    value: session.inZone ? 'Inside safe zone' : 'Outside safe zone',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 2;
        final travel = width - 16;
        return Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CanopyColors.border),
          ),
          child: Stack(
            children: [
              Positioned(
                left:
                    8 +
                    (session.target - FishingSession.zoneHalfWidth) * travel,
                top: 4,
                bottom: 4,
                width: FishingSession.zoneHalfWidth * 2 * travel,
                child: Container(
                  key: const ValueKey('fishing-fish-zone'),
                  decoration: BoxDecoration(
                    color: CanopyColors.leaf.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.set_meal,
                      size: 24,
                      color: CanopyColors.background,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: session.cursor * travel,
                top: 1,
                bottom: 1,
                child: Container(
                  key: const ValueKey('fishing-player-marker'),
                  width: 16,
                  decoration: BoxDecoration(
                    color: CanopyColors.cream,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: CanopyColors.background),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ReelControl extends StatefulWidget {
  const _ReelControl({
    required this.holding,
    required this.onHold,
    required this.horizontal,
  });
  final bool holding, horizontal;
  final ValueChanged<bool> onHold;
  @override
  State<_ReelControl> createState() => _ReelControlState();
}

class _ReelControlState extends State<_ReelControl> {
  bool focused = false;
  int? _pointer;
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    onShowFocusHighlight: (value) => setState(() => focused = value),
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          widget.onHold(!widget.holding);
          return null;
        },
      ),
    },
    child: Semantics(
      button: true,
      toggled: widget.holding,
      label: 'Reel. Hold to move right, release to move left.',
      onTap: () => widget.onHold(!widget.holding),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (_pointer != null) return;
            _pointer = event.pointer;
            widget.onHold(true);
          },
          onPointerUp: _release,
          onPointerCancel: _release,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: ActionCard(
                key: const ValueKey('reel-control'),
                title: 'Hold to reel',
                art: 'basic_rod',
                horizontal: widget.horizontal,
                compact: true,
                selected: focused || widget.holding,
                tag: widget.holding ? 'HOLDING →' : 'RELEASED ←',
                description: 'Hold → · Release ←',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _release(PointerEvent event) {
    if (_pointer != event.pointer) return;
    _pointer = null;
    widget.onHold(false);
  }
}
