import 'first_day_guide.dart';
import 'progression_screens.dart' as progression;
import 'inventory_panels.dart';
import '../game/ecology_catalog.dart';
import 'fishing_panels.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../audio/music_scope.dart';
import '../audio/sounds_scope.dart';
import '../feedback/haptics_scope.dart';
import '../game/run_state.dart';
import '../game/rescue_progress.dart';
import '../game/world_catalog.dart';
import '../game/gathering_session.dart';
import 'camp_widgets.dart';
import 'camp_backdrop.dart';
import 'canopy_components.dart';
import 'action_card.dart';
import 'card_art.dart';
import 'canopy_theme.dart';
import 'craft_screen.dart';
import 'event_dialog.dart';
import 'event_scene.dart';
import 'expedition_scene.dart';
import 'explore_map_screen.dart';
import 'fishing_screen.dart';
import 'inventory_dialog.dart';
import 'beacon_screen.dart';
import 'ruins_puzzle_screen.dart';
import 'rescued_screen.dart';
import 'gathering_screen.dart';
import 'parchment_components.dart';
import 'survival_guide_dialog.dart';
import 'day_end_screen.dart';
import '../game/crafting.dart';

class CampScreen extends StatefulWidget {
  const CampScreen({super.key, required this.engine, this.initialCampVariant});
  final GameEngine engine;
  final int? initialCampVariant;
  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen> {
  GameEngine get game => widget.engine;
  late int _campVariant =
      widget.initialCampVariant ?? CampBackdrop.variantForDay(game.state.day);
  bool _presenting = false;
  bool _openingMap = false;
  bool _openingInventory = false;
  bool _openingWorkshop = false;

  @override
  void initState() {
    super.initState();
    game.ensureRunSummary();
    // A restored run may resume mid-event, mid-report or at the pond.
    if ((game.tutorial.complete &&
            !game.tutorial.completionRead &&
            game.state.isAlive) ||
        game.tutorial.welcomePending ||
        game.isBusy ||
        game.packingDraft != null ||
        game.state.phase == RunPhase.gameOver ||
        game.state.rescued) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showFlow());
      });
    }
  }

  void _run(VoidCallback operation) {
    setState(operation);
    unawaited(_showFlow());
  }

  Future<void> _showFlow() async {
    if (_presenting) return;
    _presenting = true;
    try {
      while (mounted) {
        if (game.tutorial.welcomePending) {
          final accept = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                const PopScope(canPop: false, child: FirstDayWelcome()),
          );
          if (!mounted) return;
          setState(() => game.decideFirstRunGuide(accept == true));
          continue;
        }
        if (game.tutorial.complete &&
            !game.tutorial.completionRead &&
            game.report == null &&
            !game.isBusy &&
            game.state.isAlive) {
          await showDialog<void>(
            context: context,
            builder: (_) => const FirstDayComplete(),
          );
          if (!mounted) return;
          setState(game.acknowledgeGuideCompletion);
          continue;
        }
        if (game.hasPendingHaul) {
          final resolved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => HaulResolutionScreen(game: game)),
          );
          if (!mounted || resolved != true) return;
          setState(() {});
          continue;
        }
        if (game.packingDraft != null) {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => PackingScreen(game: game)),
          );
          if (!mounted) return;
          setState(() {});
          continue;
        }
        if (game.report != null) {
          final summary = game.report!.daySummary;
          if (summary != null) {
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => DayEndScreen(game: game, summary: summary),
              ),
            );
          } else {
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => PopScope(
                canPop: false,
                child: OutcomeDialog(
                  report: game.report!,
                  state: game.state,
                  runEnded: game.state.phase == RunPhase.gameOver,
                  runRescued: game.state.rescued,
                  nightNext:
                      game.state.timeLeft == 0 &&
                      game.state.phase == RunPhase.day &&
                      game.expedition == null,
                  expeditionNext: game.expedition != null && game.state.isAlive,
                ),
              ),
            );
          }
          if (!mounted) return;
          setState(game.continueFromReport);

          continue;
        }
        if (game.state.rescued) {
          final command = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => RescuedScreen(game: game)),
          );
          if (!mounted) return;
          if (command == 'restarted') setState(() {});
          return;
        }
        if (game.state.phase == RunPhase.gameOver ||
            game.completedRun != null) {
          await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => progression.RunResultScreen(game: game),
            ),
          );
          if (mounted) setState(() {});
          return;
        }
        if (game.gathering != null) {
          final command = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => GatheringScreen(game: game)),
          );
          if (!mounted) return;
          setState(() {});
          if (command == 'workshop') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_showWorkshop());
            });
            return;
          }
        } else if (game.ruinsPuzzle != null) {
          final command = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => RuinsPuzzleScreen(game: game),
            ),
          );
          if (!mounted || command == null) return;
          setState(() => game.finishRuinsPuzzle(leave: command == 'leave'));
        } else if (game.fishing != null) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (context) => FishingScreen(game: game)),
          );
          if (!mounted) return;
          setState(() {});
        } else if (game.pendingEvent != null) {
          final choice = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EventScene(game: game, campVariant: _campVariant),
            ),
          );
          if (!mounted || choice == null) return;
          setState(() => game.choose(choice));
        } else if (game.awaitingExpeditionDecision) {
          final decision = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => ExpeditionScene(game: game),
            ),
          );
          if (!mounted || decision == null) return;
          if (decision == 'items') {
            final command = await showDialog<String>(
              context: context,
              builder: (context) => InventoryDialog(game: game),
            );
            if (!mounted) return;
            setState(() {
              if (command?.startsWith('consume:') ?? false) {
                game.consume(command!.substring(8));
              }
              if (command == 'chew') game.chewHerbs();
            });
            continue;
          }
          setState(() {
            if (decision == 'deeper') {
              game.goDeeper();
            } else {
              game.returnHome();
            }
          });
        } else {
          return;
        }
      }
    } finally {
      _presenting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final largeText =
        MediaQuery.textScalerOf(context).scale(14) > 19 ||
        MediaQuery.sizeOf(context).width < 360;
    final shortcutWidth =
        64 *
        (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(
          1.0,
          double.infinity,
        );
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CampBackdrop(
            state: state,
            busy: game.isBusy,
            initialVariant: widget.initialCampVariant,
            onVariantChanged: (variant) => _campVariant = variant,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .18, .5, .82, 1],
                colors: [
                  Color(0x80102926),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xC0102926),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: CanopySceneBody(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  header: _topHud(state, largeText),
                  footer: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!game.isBusy) FirstDayCoach(game: game),
                      if (game.hasPendingHaul)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: parchmentButton(
                            'RESOLVE BACKPACK',
                            () => _run(() {}),
                            key: const ValueKey('resume-haul'),
                          ),
                        ),
                      if (state.value(SurvivalStat.water) <= 20 ||
                          state.value(SurvivalStat.food) <= 20)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CampPanel(
                            child: Text(
                              state.value(SurvivalStat.water) <= 20
                                  ? 'Water is running low. Forage before you rest.'
                                  : 'You need food. Search around the clearing.',
                              style: const TextStyle(
                                color: CanopyColors.food,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            <Widget>[
                                  _inventoryButton(),
                                  _workshopButton(),
                                  CanopyShortcut(
                                    key: const ValueKey('camp-menu'),
                                    label: 'MENU',
                                    art: 'journal',
                                    onPressed: _showMenu,
                                  ),
                                  _mapButton(),
                                ]
                                .map(
                                  (button) => SizedBox(
                                    width: shortcutWidth,
                                    child: button,
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 8),
                      CardDeck(
                        cards: [
                          for (final action in CampAction.values)
                            _action(action, horizontal: largeText),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHud(RunState state, bool largeText) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CanopyHud(state: state),
      const SizedBox(height: 10),
      SizedBox(width: largeText ? 280 : 190, child: _objective(state)),
    ],
  );

  Widget _objective(RunState state) {
    final next = game.recipes.nextTier(state);
    final firstNight = state.day == 1 && next != null && state.campTier == 0;
    final String title, detail;
    if (state.rescueStage == RescueStage.storm) {
      title = 'Keep the signal alive';
      detail = '${state.rescueStep}/3 storm decisions';
    } else if (state.rescueStage == RescueStage.signalSent) {
      title = 'Rescue comes tomorrow';
      detail = 'Prepare before you sleep';
    } else if (state.tools.contains('emergency_beacon')) {
      title = 'Send the rescue signal';
      detail = 'Final storm starts next dawn';
    } else if (state.campTier >= 3) {
      title = 'Build a rescue signal';
      detail = '${game.heldBeaconComponents}/5 parts · Rescue Base required';
    } else if (next == null) {
      title = 'Keep the fire alive';
      detail = '${state.day - 1} nights survived';
    } else if (firstNight && state.phase == RunPhase.night) {
      title = 'Survive the night';
      detail = '0/1 nights';
    } else {
      title = 'Build ${next.name}';
      detail = next.costs.entries
          .map(
            (e) =>
                '${itemName(e.key)} ${state.resource(e.key).clamp(0, e.value)}/${e.value}',
          )
          .join(' · ');
    }
    return CampPanel(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('camp-objective'),
          borderRadius: BorderRadius.circular(14),
          onTap: game.isBusy
              ? null
              : state.campTier >= 3 ||
                    state.rescueStage == RescueStage.signalSent
              ? _showBeacon
              : next == null
              ? null
              : () => _showWorkshop(camp: true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                const HudArt(8, size: 30),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 10,
                          color: CanopyColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _workshopButton() => CanopyShortcut(
    key: const ValueKey('open-workshop'),
    label: 'CRAFT',
    art: 'craft',
    onPressed: game.isBusy ? null : () => _showWorkshop(),
  );
  Widget _inventoryButton() => CanopyShortcut(
    key: const ValueKey('open-inventory'),
    label: 'ITEMS',
    art: 'inventory',
    onPressed: game.isBusy ? null : _showInventory,
  );
  Widget _mapButton() => CanopyShortcut(
    key: const ValueKey('open-map'),
    label: 'MAP',
    art: 'map',
    onPressed: game.isBusy ? null : _showMap,
  );

  Future<void> _showMap() async {
    if (_openingMap || _presenting || game.isBusy) return;
    _openingMap = true;
    final destination = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'map'),
        builder: (context) => ExploreMapScreen(game: game),
      ),
    );
    _openingMap = false;
    if (!mounted || destination == null) return;
    if (destination == 'workshop') {
      await _showWorkshop();
    } else {
      _run(() => game.beginPacking(destination));
    }
  }

  Future<void> _showInventory() async {
    if (_openingInventory || _presenting || game.isBusy) return;
    _openingInventory = true;
    final command = await showDialog<String>(
      context: context,
      builder: (context) => InventoryDialog(game: game),
    );
    _openingInventory = false;
    if (!mounted || command == null) return;
    if (command == 'map') {
      await _showMap();
    } else if (command == 'workshop') {
      await _showWorkshop();
    } else if (command.startsWith('prepare-fish:')) {
      _run(() => game.prepareFish(command.substring(13)));
    } else if (command.startsWith('equip-tool:')) {
      _run(() => game.equipFieldTool(command.substring(11)));
    } else if (command.startsWith('repair-tool:')) {
      _run(() => game.craft(command.substring(12)));
    } else if (command.startsWith('equip-rod:')) {
      _run(() => game.equipFishingRod(command.substring(10)));
    } else if (command == 'dry') {
      _run(game.dryByFire);
    } else if (command == 'roots') {
      _run(game.prepareRoots);
    } else if (command == 'chew') {
      _run(game.chewHerbs);
    } else if (command.startsWith('study:')) {
      _run(() => game.studySpecies(command.substring(6)));
    } else if (command.startsWith('consume:')) {
      _run(() => game.consume(command.substring('consume:'.length)));
    }
  }

  Future<void> _showWorkshop({bool camp = false}) async {
    if (_openingWorkshop || _presenting || game.isBusy) return;
    _openingWorkshop = true;
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CraftScreen(game: game, showCamp: camp),
      ),
    );
    _openingWorkshop = false;
    if (!mounted || id == null) return;
    _run(() => game.craft(id));
  }

  Future<void> _showBeacon() async {
    if (_openingWorkshop || _presenting || game.isBusy) return;
    _openingWorkshop = true;
    final command = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BeaconScreen(game: game, campVariant: _campVariant),
      ),
    );
    _openingWorkshop = false;
    if (!mounted || command == null) return;
    switch (command) {
      case 'assemble':
        _run(() => game.craft('emergency_beacon'));
      case 'activate':
        _run(game.activateBeacon);
      case 'map':
        await _showMap();
      case 'workshop':
        await _showWorkshop(camp: game.state.campTier < 3);
      case 'inventory':
        await _showInventory();
    }
  }

  Future<void> _confirmNewRun() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => progression.NewJourneyScreen(game: game),
      ),
    );
    if (!mounted) return;
    setState(() {});
    if (game.completedRun != null) unawaited(_showFlow());
  }

  Widget _action(CampAction action, {bool horizontal = false}) {
    final sleep =
        action == CampAction.rest && game.state.phase == RunPhase.night;
    return CampActionCard(
      key: ValueKey('action-${action.name}'),
      action: action,
      sleep: sleep,
      horizontal: horizontal,
      onPressed: sleep
          ? (game.canSleep ? () => _run(game.sleep) : null)
          : action == CampAction.explore
          ? (game.isBusy || game.state.phase != RunPhase.day ? null : _showMap)
          : (game.canAct(action)
                ? () => _run(() => game.startAction(action))
                : null),
    );
  }

  Future<void> _showMenu() async {
    final canReturnToMenu = Navigator.of(context).canPop();
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => CanopyDialog(
        title: 'Camp menu',
        art: 'journal',
        actions: [
          parchmentButton(
            'START A NEW RUN',
            () => Navigator.pop(context, 'new-run'),
            key: const ValueKey('menu-new-run'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ParchmentLabel(
              'Progress saves automatically.',
              size: 13,
              weight: FontWeight.w500,
            ),
            const SizedBox(height: 10),
            CampPanel(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final (id, title, art) in [
                    if (canReturnToMenu) ('main-menu', 'Main menu', 'map'),
                    ('gather', 'Gather around camp', 'forage'),
                    ('journal', 'Survival journal', 'journal'),
                    ('profile', 'Survivor profile', 'journal'),
                    ('guide', 'How to survive', 'map'),
                    ('beacon', 'Rescue signal', 'emergency_beacon'),
                  ])
                    ParchmentMenuRow(
                      key: ValueKey('menu-$id'),
                      title: title,
                      art: art,
                      onTap: () => Navigator.pop(context, id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const CampPanel(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [MusicControls(), SoundControls(), HapticControls()],
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'main-menu') {
      await game.saveSettled;
      if (mounted) Navigator.pop(context);
      return;
    }
    if (choice == 'journal') _showJournal();
    if (choice == 'profile') {
      await progression.openProfile(context, game);
      if (!mounted) return;
      setState(() {});
      if (game.completedRun != null) unawaited(_showFlow());
    }
    if (choice == 'gather') await _showGathering();
    if (choice == 'guide') _showGuide();
    if (choice == 'beacon') await _showBeacon();
    if (choice == 'new-run') await _confirmNewRun();
  }

  Future<void> _showGathering() async {
    if (game.isBusy || _presenting) return;
    final kind = await showDialog<GatheringKind>(
      context: context,
      builder: (dialogContext) => CanopyDialog(
        title: 'Gather around camp',
        art: 'forage',
        subtitle: 'SHORT SKILL CHALLENGES',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a nearby activity. Starting an attempt uses 1 daylight.',
            ),
            const SizedBox(height: 12),
            CardDeck(
              columns: 3,
              cards: [
                for (final kind in GatheringKind.values)
                  ActionCard(
                    key: ValueKey('open-gathering-${kind.name}'),
                    title: kind.title,
                    art: kind == GatheringKind.foraging ? 'forage' : kind.art,
                    compact: true,
                    fixedHeight:
                        MediaQuery.textScalerOf(dialogContext).scale(14) > 19
                        ? 240
                        : 180,
                    titleMaxLines: 2,
                    showStatus: false,
                    onTap: game.canAct(CampAction.forage)
                        ? () => Navigator.pop(dialogContext, kind)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || kind == null) return;
    _run(() => game.openGathering(kind));
  }

  Future<void> _showJournal() async {
    final next = game.recipes.campTiers
        .where((r) => r.tier! > game.state.campTier)
        .firstOrNull;
    final command = await showDialog<String>(
      context: context,
      builder: (context) => CanopyDialog(
        title: 'Survival journal',
        art: 'journal',
        subtitle:
            'DAY ${game.state.day} · ${campTierName(game.recipes, game.state.campTier)}',
        actions: [
          parchmentButton(
            'FISH FIELD GUIDE',
            () => showDialog<void>(
              context: context,
              builder: (context) => FishJournalDialog(game: game),
            ),
            secondary: true,
            key: const ValueKey('journal-fish'),
          ),
          parchmentButton(
            'VIEW CAMP UPGRADES',
            () => Navigator.pop(context, 'camp'),
            key: const ValueKey('journal-camp'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ParchmentLabel('JUNGLE KNOWLEDGE', size: 14),
            const SizedBox(height: 8),
            for (final id in game.state.knownSpecies)
              if (jungleFoods.containsKey(id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ParchmentLabel(
                    '${jungleFoods[id]!.name}: ${jungleFoods[id]!.description}',
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
            const ParchmentLabel(
              'Gathering stores food. Use Items to study, prepare or eat it. Antidotes clear poison; bandages treat injuries. Rain exposure and fatigue build only when time passes.',
              size: 12,
              weight: FontWeight.w500,
            ),
            const SizedBox(height: 12),
            if (next != null) ...[
              ParchmentLabel('Build ${next.name}', size: 14),
              const SizedBox(height: 5),
              ParchmentLabel(
                next.costs.entries
                    .map(
                      (e) =>
                          '${itemName(e.key)} ${game.state.resource(e.key)}/${e.value}',
                    )
                    .join(' · '),
                size: 12,
                weight: FontWeight.w500,
              ),
              const SizedBox(height: 10),
            ],
            CampPanel(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final r in game.recipes.campTiers)
                    ParchmentMenuRow(
                      title: r.name,
                      art: 'shelter',
                      onTap: null,
                      trailing: r.isOwnedBy(game.state)
                          ? 'DONE'
                          : r.id == next?.id
                          ? 'CURRENT'
                          : 'LATER',
                    ),
                  ParchmentMenuRow(
                    title: 'Recover rescue parts',
                    art: 'emergency_beacon',
                    onTap: null,
                    trailing: '${game.state.foundComponents.length}/5',
                  ),
                  for (final entry in game.journal)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CardArt('journal', size: 26),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ParchmentLabel(
                              entry,
                              size: 12,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && command == 'camp') await _showWorkshop(camp: true);
  }

  Future<void> _showGuide() async {
    final command = await showDialog<String>(
      context: context,
      builder: (_) => SurvivalGuideDialog(game: game),
    );
    if (mounted && command == 'workshop') await _showWorkshop();
  }
}
