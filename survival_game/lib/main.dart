import 'analytics/analytics_controller.dart';
import 'analytics/analytics_ui.dart';
import 'analytics/firebase_sink.dart';
import 'analytics/game_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'audio/music_controller.dart';
import 'audio/music_scope.dart';
import 'audio/sounds_controller.dart';
import 'audio/sounds_scope.dart';
import 'feedback/haptics_controller.dart';
import 'feedback/haptics_scope.dart';
import 'package:flutter/services.dart';

import 'game/crafting.dart';
import 'game/event_catalog.dart';
import 'game/game_engine.dart';
import 'game/run_storage.dart';
import 'game/world_catalog.dart';
import 'ui/camp_screen.dart';
import 'ui/main_menu_screen.dart';
import 'ui/canopy_theme.dart';
import 'ui/action_card.dart';
import 'ui/camp_widgets.dart';
import 'ui/canopy_components.dart';
import 'ui/card_art.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: CanopyColors.background,
    ),
  );
  runApp(const LostCanopyApp());
}

class LostCanopyApp extends StatefulWidget {
  const LostCanopyApp({
    super.key,
    this.engine,
    this.storage,
    this.music,
    this.sounds,
    this.haptics,
    this.enableAudio = true,
    this.enableHaptics = true,
    this.enableAnalytics = true,
    this.analytics,
    this.showMainMenu,
  });
  final GameEngine? engine;
  final MusicController? music;
  final SoundsController? sounds;
  final HapticsController? haptics;
  final bool enableAudio;
  final bool enableHaptics;
  final bool enableAnalytics;
  final AnalyticsController? analytics;

  /// Injected gameplay fixtures bypass startup unless explicitly requested.
  final bool? showMainMenu;

  /// Where the run is autosaved. Defaults to device storage unless an
  /// [engine] is injected (tests), which then runs without saving.
  final RunStorage? storage;
  @override
  State<LostCanopyApp> createState() => _LostCanopyAppState();
}

class _LostCanopyAppState extends State<LostCanopyApp> {
  late final MusicController? _music =
      widget.music ??
      (widget.engine == null && widget.enableAudio
          ? MusicController.device()
          : null);
  late final SoundsController? _sounds =
      widget.sounds ??
      (widget.engine == null && widget.enableAudio
          ? SoundsController.device()
          : null);
  late final _musicNavigation = MusicNavigationObserver(
    _music,
    onMapOpen: (value) => _sounds?.setMapOpen(value),
  );
  late final HapticsController? _haptics =
      widget.haptics ??
      (widget.engine == null && widget.enableHaptics
          ? HapticsController.device()
          : null);
  late AnalyticsController? _analytics = widget.analytics;
  GameAnalytics? _gameAnalytics;
  late final _analyticsNavigation = AnalyticsNavigationObserver(
    _analytics,
    home: _useMenu ? 'main_menu' : 'camp',
  );
  AppLifecycleListener? _lifecycle;
  late Future<GameEngine> _engine = _load();
  bool get _useMenu => widget.showMainMenu ?? widget.engine == null;
  int _menuBackground = 0;
  final _rotation = MenuBackgroundRotation();

  @override
  void initState() {
    super.initState();
    if (_music != null ||
        _sounds != null ||
        _haptics != null ||
        widget.enableAnalytics) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      void foreground(bool value) {
        _analytics?.setForeground(value);
        _music?.setForeground(value);
        _sounds?.setForeground(value);
        _haptics?.setForeground(value);
      }

      foreground(lifecycle == null || lifecycle == AppLifecycleState.resumed);
      _lifecycle = AppLifecycleListener(
        onStateChange: (state) =>
            foreground(state == AppLifecycleState.resumed),
      );
      if (_music != null) unawaited(_music.initialize());
      if (_sounds != null) unawaited(_sounds.initialize());
      if (_haptics != null) unawaited(_haptics.initialize());
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _gameAnalytics?.dispose();
    if (widget.analytics == null) _analytics?.dispose();
    if (widget.music == null) _music?.dispose();
    if (widget.sounds == null) _sounds?.dispose();
    if (widget.haptics == null) _haptics?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LostCanopyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engine != oldWidget.engine ||
        widget.storage != oldWidget.storage) {
      _engine = _load();
    }
  }

  Future<GameEngine> _load() async {
    if (_analytics == null && widget.engine == null && widget.enableAnalytics) {
      try {
        _analytics = AnalyticsController(
          sink: FirebaseAnalyticsSink(),
          preferences: await SharedPreferences.getInstance(),
        );
        await _analytics!.initialize();
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        _analytics!.setForeground(
          lifecycle == null || lifecycle == AppLifecycleState.resumed,
        );
        _analyticsNavigation.controller = _analytics;
        _analytics!.showScreen(_useMenu ? 'main_menu' : 'camp');
        if (mounted) setState(() {});
      } catch (_) {
        /* Loading a journey must work without telemetry. */
      }
    }
    final storage =
        widget.storage ??
        (widget.engine == null ? PreferencesRunStorage() : null);
    final engine =
        widget.engine ??
        GameEngine(
          offerFirstRunGuide: true,
          EventCatalog.fromJson(
            await rootBundle.loadString('assets/data/events.json'),
          ),
          world: WorldCatalog.fromJson(
            await rootBundle.loadString('assets/data/locations.json'),
          ),
          recipes: RecipeCatalog.fromJson(
            await rootBundle.loadString('assets/data/recipes.json'),
          ),
        );
    if (storage != null) {
      final saved = await storage.load();
      if (saved != null && !engine.restore(saved)) {
        final backup = await storage.loadBackup();
        if (backup != null) engine.restore(backup);
      }
      engine.persistSnapshot = storage.save;
      await engine.retrySave();
    }
    if (_useMenu) _menuBackground = await _rotation.next();
    if (mounted) {
      _gameAnalytics?.dispose();
      if (_analytics != null) {
        _gameAnalytics = GameAnalytics(_analytics!, engine);
      }
      _music?.attach(engine);
      _sounds?.attach(engine);
      _haptics?.attach(engine);
    }
    return engine;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lost Canopy',
    debugShowCheckedModeBanner: false,
    theme: canopyTheme,
    navigatorObservers: [_musicNavigation, _analyticsNavigation],
    builder: (context, child) => MusicScope(
      controller: _music,
      child: SoundsScope(
        controller: _sounds,
        child: HapticsScope(
          controller: _haptics,
          child: AnalyticsScope(
            controller: _analytics,
            child: AnalyticsGestures(controller: _analytics, child: child!),
          ),
        ),
      ),
    ),
    home: FutureBuilder<GameEngine>(
      future: _engine,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _useMenu
              ? MainMenuScreen(
                  game: snapshot.requireData,
                  backgroundIndex: _menuBackground,
                  nextBackground: _rotation.next,
                )
              : CampScreen(engine: snapshot.requireData);
        }
        if (_useMenu) {
          return SplashScreen(
            failed: snapshot.hasError,
            onRetry: () => setState(() => _engine = _load()),
          );
        }
        return RunLoadingScreen(
          failed: snapshot.hasError,
          onRetry: () => setState(() => _engine = _load()),
        );
      },
    ),
  );
}

/// Startup has no HUD: a saved run has not been restored yet.
class RunLoadingScreen extends StatelessWidget {
  const RunLoadingScreen({super.key, this.failed = false, this.onRetry});
  final bool failed;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: CanopyBackdrop(
      background: campArt(0),
      dark: true,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: CampPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CardArt(failed ? 'trail' : 'inventory', size: 100),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        failed
                            ? 'THE TRAIL COULD NOT BE LOADED'
                            : 'PREPARING YOUR CAMP',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      failed
                          ? 'Try loading your journey again.'
                          : 'Loading your journey…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    if (failed)
                      ActionCard(
                        key: const ValueKey('retry-load'),
                        title: 'Try again',
                        art: 'back',
                        tone: CardTone.river,
                        horizontal: true,
                        onTap: onRetry,
                      )
                    else
                      const Center(
                        child: SizedBox.square(
                          dimension: 36,
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Loading your journey',
                          ),
                        ),
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
