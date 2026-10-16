import '../analytics/analytics_ui.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/music_scope.dart';
import '../audio/sounds_scope.dart';
import '../feedback/haptics_scope.dart';
import '../game/game_engine.dart';
import 'camp_screen.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';
import 'parchment_components.dart';
import 'progression_screens.dart' as progression;
import 'scene_artwork.dart';
import 'survival_guide_dialog.dart';

const menuBackgrounds = [
  'assets/art/menu_world_map_v1.png',
  'assets/art/menu_river_valley_v1.png',
  'assets/art/menu_misty_ruins_v1.png',
];
const splashBackground = 'assets/art/menu_splash_jungle_v1.png';
const menuCream = Color(0xFFFFEAC0);

class MenuBackgroundRotation {
  static const preferenceKey = 'lost_canopy.menu_background';
  Future<int> next() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final last = preferences.getInt(preferenceKey) ?? -1;
      final next = (last + 1) % menuBackgrounds.length;
      await preferences.setInt(preferenceKey, next);
      return next;
    } catch (_) {
      // A cosmetic preference must never prevent loading a saved journey.
      return 0;
    }
  }
}

/// Fade is applied to the actual image rectangle, before any readability
/// overlay. Thus letterboxed image edges have exactly the backing colour.
class MenuBackdrop extends StatelessWidget {
  const MenuBackdrop({super.key, required this.asset, required this.child});
  final String asset;
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CanopyColors.background,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: SceneArtwork(
            asset: asset,
            edgeFade: 140,
            alwaysFadeEdges: true,
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .2, .5, .72, 1],
                colors: [
                  Color(0x99102A28),
                  Color(0x33102A28),
                  Colors.transparent,
                  Color(0x33102A28),
                  Color(0xCC102A28),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

class LostCanopyTitle extends StatelessWidget {
  const LostCanopyTitle({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'LOST',
          style: TextStyle(
            fontSize: large ? 60 : 44,
            height: .92,
            fontWeight: FontWeight.w900,
            letterSpacing: 9,
            color: menuCream,
          ),
        ),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'CANOPY',
          style: TextStyle(
            fontSize: large ? 59 : 45,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: const Color(0xFFE6BA69),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Container(height: 1, width: 150, color: const Color(0x88E6BA69)),
      const SizedBox(height: 10),
      const Text(
        'SURVIVE. ADAPT. FIND YOUR WAY HOME.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1.7,
          color: menuCream,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class JourneyButton extends StatelessWidget {
  const JourneyButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Color(0x9905100C),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: PaperSurface(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: ParchmentColors.ink,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: ParchmentColors.muted,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.game,
    this.backgroundIndex = 0,
    this.nextBackground,
  });
  final GameEngine game;
  final int backgroundIndex;
  final Future<int> Function()? nextBackground;
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  GameEngine get game => widget.game;
  late int background = widget.backgroundIndex % menuBackgrounds.length;
  bool entering = false;
  @override
  void initState() {
    super.initState();
    game.addListener(refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        menuAudio();
        unawaited(offerAnalytics(context));
      }
    });
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void menuAudio() {
    MusicScope.of(context)?.setMapOpen(true);
    SoundsScope.of(context)?.setMapOpen(true);
  }

  @override
  void dispose() {
    game.removeListener(refresh);
    super.dispose();
  }

  Future<void> enter() async {
    if (entering) return;
    setState(() => entering = true);
    game.beginJourney();
    await game.saveSettled;
    if (!mounted) return;
    if (game.saveFailed) {
      setState(() => entering = false);
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'camp'),
        builder: (_) => CampScreen(engine: game),
      ),
    );
    if (!mounted) return;
    final next =
        await (widget.nextBackground?.call() ??
            Future.value((background + 1) % menuBackgrounds.length));
    if (!mounted) return;
    setState(() {
      background = next;
      entering = false;
    });
    menuAudio();
  }

  Future<void> newJourney() async {
    if (entering) return;
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'menu'),
        builder: (_) => progression.NewJourneyScreen(game: game),
      ),
    );
    if (!mounted) return;
    menuAudio();
    if (confirmed == true) await enter();
  }

  Future<void> profile() async {
    final runId = game.metrics.id;
    final started = game.journeyStarted;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'menu'),
        builder: (_) => progression.ProfileScreen(game: game),
      ),
    );
    if (!mounted) return;
    menuAudio();
    if (game.metrics.id != runId ||
        (!started && game.journeyStarted) ||
        result == true) {
      await enter();
    }
  }

  Future<void> guide() async {
    final command = await showDialog<String>(
      context: context,
      routeSettings: const RouteSettings(name: 'survival_guide_dialog'),
      builder: (_) => SurvivalGuideDialog(game: game),
    );
    if (mounted && command == 'workshop') await enter();
  }

  void settings() => showDialog<void>(
    context: context,
    routeSettings: const RouteSettings(name: 'settings'),
    builder: (_) => const CanopyDialog(
      title: 'Settings',
      art: 'journal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MusicControls(),
          SoundControls(),
          HapticControls(),
          AnalyticsControls(),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: MenuBackdrop(
      asset: menuBackgrounds[background],
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LostCanopyTitle(),
                        const SizedBox(height: 200),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (game.journeyStarted) ...[
                              PaperSurface(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const ParchmentLabel(
                                        'YOUR JOURNEY',
                                        size: 10,
                                        color: ParchmentColors.muted,
                                      ),
                                      const SizedBox(height: 4),
                                      ParchmentLabel(
                                        'Day ${game.state.day} · ${game.world.find(game.state.locationId)?.name ?? 'Camp'}',
                                        size: 15,
                                      ),
                                      const SizedBox(height: 4),
                                      ParchmentLabel(
                                        game.completedRun != null
                                            ? 'Journey ended · Summary saved'
                                            : 'Your progress is saved',
                                        size: 11,
                                        weight: FontWeight.w500,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            JourneyButton(
                              key: const ValueKey('menu-enter-journey'),
                              label: entering
                                  ? 'LOADING JOURNEY…'
                                  : !game.journeyStarted
                                  ? 'BEGIN YOUR JOURNEY'
                                  : game.completedRun != null
                                  ? 'VIEW JOURNEY SUMMARY'
                                  : 'CONTINUE JOURNEY',
                              onPressed: entering ? null : enter,
                            ),
                            if (game.journeyStarted) ...[
                              const SizedBox(height: 8),
                              parchmentButton(
                                'NEW JOURNEY',
                                entering ? null : newJourney,
                                secondary: true,
                                key: const ValueKey('main-menu-new-journey'),
                              ),
                            ] else ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Build a camp. Explore the jungle. Survive the night.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: menuCream,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (game.saveFailed) ...[
                              const SizedBox(height: 10),
                              progression.saveNotice(game),
                            ],
                            const SizedBox(height: 14),
                            PaperSurface(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final (id, icon, label, callback)
                                      in <
                                        (String, IconData, String, VoidCallback)
                                      >[
                                        (
                                          'profile',
                                          Icons.menu_book_rounded,
                                          'SURVIVOR PROFILE',
                                          profile,
                                        ),
                                        (
                                          'settings',
                                          Icons.tune_rounded,
                                          'SETTINGS',
                                          settings,
                                        ),
                                        (
                                          'guide',
                                          Icons.help_outline_rounded,
                                          'HOW TO SURVIVE',
                                          guide,
                                        ),
                                      ])
                                    TextButton(
                                      key: ValueKey('main-menu-$id'),
                                      onPressed: entering ? null : callback,
                                      style: TextButton.styleFrom(
                                        foregroundColor: ParchmentColors.ink,
                                        minimumSize: const Size(
                                          double.infinity,
                                          48,
                                        ),
                                        shape: const RoundedRectangleBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(icon, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'LOST CANOPY · SURVIVAL JOURNAL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.3,
                                color: menuCream,
                              ),
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
      ),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.failed = false, this.onRetry});
  final bool failed;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: MenuBackdrop(
      asset: splashBackground,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 55,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const LostCanopyTitle(large: true),
                    const SizedBox(height: 280),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'A WILDERNESS SURVIVAL JOURNEY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: menuCream,
                            fontSize: 11,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (failed) ...[
                          const Text(
                            'Your journey could not be loaded.',
                            style: TextStyle(color: menuCream),
                          ),
                          const SizedBox(height: 12),
                          parchmentButton(
                            'TRY AGAIN',
                            onRetry,
                            key: const ValueKey('retry-load'),
                          ),
                        ] else ...[
                          const SizedBox(
                            width: 150,
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              color: Color(0xFFE6BA69),
                              backgroundColor: Color(0x33294E36),
                              semanticsLabel: 'Loading your journey',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Preparing your journey…',
                            style: TextStyle(color: menuCream, fontSize: 11),
                          ),
                        ],
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
