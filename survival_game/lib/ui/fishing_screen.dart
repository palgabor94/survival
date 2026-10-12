import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/fishing_session.dart';
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
    setState(() => session.update(dt));
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
                        child: CanopyTitle(
                          title: 'Fishing Pond',
                          art: 'basic_rod',
                          subtitle:
                              'Basic Rod · Bait ${widget.game.state.resource('bait')} · one cast per trip',
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
                              onTap: () => setState(() => session.hook()),
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
                                ? 'Carry your catch home'
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
          const Text(
            'Hook when a fish bites. Hold to reel right, release to drift left.\nRound trip: 2 time already spent.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.3),
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
          const Text(
            'Hold: right · Release: left\nKeyboard Enter / Space toggles reeling.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: CanopyColors.muted),
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

class _ReelMeter extends StatelessWidget {
  const _ReelMeter({required this.session});
  final FishingSession session;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Fishing control',
    value: session.inZone ? 'Inside safe zone' : 'Outside safe zone',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
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
                    (session.target - FishingSession.zoneHalfWidth) *
                    (width - 2),
                top: 4,
                bottom: 4,
                width: FishingSession.zoneHalfWidth * 2 * (width - 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: CanopyColors.leaf.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                left: session.cursor * (width - 10),
                top: 1,
                bottom: 1,
                child: Container(
                  width: 8,
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => widget.onHold(true),
          onTapUp: (_) => widget.onHold(false),
          onTapCancel: () => widget.onHold(false),
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: ActionCard(
                key: const ValueKey('reel-control'),
                title: 'Hold to reel',
                art: 'basic_rod',
                horizontal: widget.horizontal,
                compact: true,
                selected: focused || widget.holding,
                tag: widget.holding ? 'REELING' : 'READY',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
