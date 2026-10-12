import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/crafting.dart';
import 'game/event_catalog.dart';
import 'game/game_engine.dart';
import 'game/run_storage.dart';
import 'game/world_catalog.dart';
import 'ui/camp_screen.dart';
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
  const LostCanopyApp({super.key, this.engine, this.storage});
  final GameEngine? engine;

  /// Where the run is autosaved. Defaults to device storage unless an
  /// [engine] is injected (tests), which then runs without saving.
  final RunStorage? storage;
  @override
  State<LostCanopyApp> createState() => _LostCanopyAppState();
}

class _LostCanopyAppState extends State<LostCanopyApp> {
  late Future<GameEngine> _engine = _load();

  @override
  void didUpdateWidget(LostCanopyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engine != oldWidget.engine ||
        widget.storage != oldWidget.storage) {
      _engine = _load();
    }
  }

  Future<GameEngine> _load() async {
    final storage =
        widget.storage ??
        (widget.engine == null ? PreferencesRunStorage() : null);
    final engine =
        widget.engine ??
        GameEngine(
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
      if (saved != null) engine.restore(saved);
      engine.onChanged = () => storage.save(engine.toJson());
    }
    return engine;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lost Canopy',
    debugShowCheckedModeBanner: false,
    theme: canopyTheme,
    home: FutureBuilder<GameEngine>(
      future: _engine,
      builder: (context, snapshot) {
        if (snapshot.hasData) return CampScreen(engine: snapshot.requireData);
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
      background: 'assets/art/starter_camp.png',
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
