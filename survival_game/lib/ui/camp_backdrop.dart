import 'dart:async';

import 'package:flutter/material.dart';

import '../game/rescue_progress.dart';
import '../game/run_state.dart';
import 'camp_widgets.dart';
import 'camp_character.dart';
import 'canopy_theme.dart';
import 'scene_artwork.dart';

/// Ambient artwork changes are visual only; they never advance the game.
class CampBackdrop extends StatefulWidget {
  const CampBackdrop({
    super.key,
    required this.state,
    required this.busy,
    this.initialVariant,
    this.onVariantChanged,
  }) : assert(
         initialVariant == null ||
             (initialVariant >= 0 && initialVariant < campActivities.length),
       );
  final RunState state;
  final bool busy;
  final int? initialVariant;

  /// Lets camp-owned routes preserve the currently displayed character pose.
  final ValueChanged<int>? onVariantChanged;

  static int variantForDay(int day) => (day - 1) % campActivities.length;

  static const interval = Duration(seconds: 30);
  static const fade = Duration(milliseconds: 650);

  @override
  State<CampBackdrop> createState() => _CampBackdropState();
}

class _CampBackdropState extends State<CampBackdrop>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _variant = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _variant =
        widget.initialVariant ?? CampBackdrop.variantForDay(widget.state.day);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(CampBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.campTier != widget.state.campTier) {
      _variant =
          widget.initialVariant ?? CampBackdrop.variantForDay(widget.state.day);
      widget.onVariantChanged?.call(_variant);
    } else if (oldWidget.state.day != widget.state.day) {
      // Active players need not wait idle for 30 seconds to see other poses.
      _variant = (_variant + 1) % campActivities.length;
      widget.onVariantChanged?.call(_variant);
    }
  }

  void _syncTimer() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (MediaQuery.disableAnimationsOf(context) ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(
      CampBackdrop.interval,
      (_) => unawaited(_advance()),
    );
  }

  bool get _canAdvance =>
      mounted &&
      !widget.busy &&
      !MediaQuery.disableAnimationsOf(context) &&
      widget.state.phase == RunPhase.day &&
      widget.state.rescueStage != RescueStage.storm &&
      ModalRoute.of(context)?.isCurrent == true &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  Future<void> _advance() async {
    if (_loading || !_canAdvance) return;
    _loading = true;
    final tier = widget.state.campTier;
    final next = (_variant + 1) % campActivities.length;
    try {
      await precacheImage(AssetImage(campCharacterArt(tier, next)), context);
      if (_canAdvance && widget.state.campTier == tier) {
        setState(() => _variant = next);
        widget.onVariantChanged?.call(_variant);
      }
    } finally {
      _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final night = state.phase == RunPhase.night;
    final storm = state.rescueStage == RescueStage.storm;
    final path = storm
        ? 'assets/art/rescue_storm_camp_style_v1.png'
        : campArt(state.campTier, variant: _variant);
    if (!storm) {
      return ColoredBox(
        key: ValueKey('camp-art-${state.campTier}'),
        color: CanopyColors.background,
        child: SceneArtwork(
          asset: path,
          alignment: campAlignment(state.campTier),
          tint: night ? campNightTint : null,
          foregroundBuilder: (context, rect) => CampCharacter(
            artworkRect: rect,
            tier: state.campTier,
            variant: _variant,
            tint: night ? campNightTint : null,
            animate: true,
          ),
        ),
      );
    }
    return ColoredBox(
      color: CanopyColors.background,
      child: AnimatedSwitcher(
        key: ValueKey('camp-art-${state.campTier}'),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : CampBackdrop.fade,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: SceneArtwork(
          asset: path,
          key: ValueKey('camp-background-$path-${night && !storm}'),
          alignment: const Alignment(0, .18),
          tint: night && !storm ? campNightTint : null,
        ),
      ),
    );
  }
}
