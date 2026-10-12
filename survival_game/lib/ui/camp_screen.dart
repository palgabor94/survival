import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'camp_widgets.dart';
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

class CampScreen extends StatefulWidget {
  const CampScreen({super.key, required this.engine});
  final GameEngine engine;
  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen> {
  GameEngine get game => widget.engine;
  bool _presenting = false;
  bool _openingMap = false;
  bool _openingInventory = false;
  bool _openingWorkshop = false;

  @override
  void initState() {
    super.initState();
    // A restored run may resume mid-event, mid-report or at the pond.
    if (game.isBusy || game.state.phase == RunPhase.gameOver) {
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
        if (game.report != null) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => PopScope(
              canPop: false,
              child: OutcomeDialog(
                report: game.report!,
                runEnded: game.state.phase == RunPhase.gameOver,
                nightNext:
                    game.state.timeLeft == 0 &&
                    game.state.phase == RunPhase.day &&
                    game.expedition == null,
                expeditionNext: game.expedition != null && game.state.isAlive,
              ),
            ),
          );
          if (!mounted) return;
          setState(game.continueFromReport);

          continue;
        }
        if (game.state.phase == RunPhase.gameOver) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => PopScope(
              canPop: false,
              child: GameOverDialog(day: game.state.day),
            ),
          );
          if (!mounted) return;
          setState(game.restart);
          return;
        }
        if (game.fishing != null) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (context) => FishingScreen(game: game)),
          );
          if (!mounted) return;
          setState(() {});
        } else if (game.pendingEvent != null) {
          final choice = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => EventScene(game: game)),
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
    final night = state.phase == RunPhase.night;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            campArt(state.campTier),
            key: ValueKey('camp-art-${state.campTier}'),
            fit: BoxFit.cover,
            alignment: const Alignment(0, .18),
            excludeFromSemantics: true,
          ),
          AnimatedOpacity(
            opacity: night ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 650),
            child: state.campTier == 0
                ? Image.asset(
                    'assets/art/starter_camp_night.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, .18),
                    excludeFromSemantics: true,
                  )
                : Image.asset(
                    campArt(state.campTier),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, .18),
                    color: const Color(0xFF4A5F8E),
                    colorBlendMode: BlendMode.multiply,
                    excludeFromSemantics: true,
                  ),
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
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _inventoryButton(),
                          _workshopButton(),
                          CanopyShortcut(
                            key: const ValueKey('camp-menu'),
                            label: 'MENU',
                            art: 'journal',
                            onPressed: _showMenu,
                          ),
                          _mapButton(),
                        ],
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
    if (next == null) {
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
          onTap: next == null ? null : () => _showWorkshop(camp: true),
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
    label: 'INVENTORY',
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
      MaterialPageRoute(builder: (context) => ExploreMapScreen(game: game)),
    );
    _openingMap = false;
    if (!mounted || destination == null) return;
    if (destination == 'workshop') {
      await _showWorkshop();
    } else {
      _run(() => game.travelTo(destination));
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
    if (command == 'workshop') {
      await _showWorkshop();
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

  Future<void> _confirmNewRun() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const CanopyConfirmation(
        title: 'Start a new run?',
        message:
            'Your current camp, supplies and saved progress will be replaced.',
        confirm: 'New run',
        cancel: 'Keep playing',
        art: 'shelter',
        destructive: true,
        confirmKey: ValueKey('confirm-new-run'),
      ),
    );
    if (confirmed == true && mounted && !game.isBusy) setState(game.restart);
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
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => CanopyDialog(
        title: 'Camp menu',
        art: 'journal',
        actions: [
          ActionCard(
            key: const ValueKey('close-menu'),
            title: 'Close',
            art: 'back',
            tone: CardTone.river,
            horizontal: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
        child: Column(
          children: [
            for (final (id, title, art) in [
              ('journal', 'Survival journal', 'journal'),
              ('guide', 'How to survive', 'map'),
              ('new-run', 'Start a new run', 'shelter'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActionCard(
                  key: ValueKey('menu-$id'),
                  title: title,
                  art: art,
                  horizontal: true,
                  tone: id == 'new-run' ? CardTone.sand : CardTone.river,
                  onTap: () => Navigator.pop(context, id),
                ),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'journal') _showJournal();
    if (choice == 'guide') _showGuide();
    if (choice == 'new-run') await _confirmNewRun();
  }

  void _showJournal() => showDialog<void>(
    context: context,
    builder: (context) => CanopyDialog(
      title: 'Survival journal',
      art: 'journal',
      actions: [
        ActionCard(
          key: const ValueKey('close-journal'),
          title: 'Back to camp',
          art: 'back',
          tone: CardTone.river,
          horizontal: true,
          onTap: () => Navigator.pop(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in game.journal)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CampPanel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardArt('journal', size: 28),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  void _showGuide() => showDialog<void>(
    context: context,
    builder: (context) => CanopyDialog(
      title: 'Make daylight count',
      art: 'journal',
      actions: [
        ActionCard(
          key: const ValueKey('close-guide'),
          title: 'Back to camp',
          art: 'back',
          tone: CardTone.river,
          horizontal: true,
          onTap: () => Navigator.pop(context),
        ),
      ],
      child: const SingleChildScrollView(
        child: Text(
          'Each day gives you 6 time. Forage costs 1, explore 2, and rest 1.\n\n'
          'Each time spent uses 4 water and 3 food. At zero water you lose 12 health per time; '
          'at zero food you lose 6. Health at zero ends your run.\n\n'
          'Forage for food, water, or firewood. Explore opens the map. A Riverbank trip costs 2 time, '
          'and brings water, rod materials or bait. Rest restores 8 health and 12 sanity after its time cost.\n\n'
          'Open CRAFT to build tools and camp items. A Basic Rod costs 2 wood, 3 fiber and 1 time; '
          'a Stone Knife cuts herbs, a Stone Axe chops extra wood and a Torch helps at night. '
          'Upgrade your camp from the CAMP tab: every tier improves sleep and unlocks more. '
          'Herbs brewed as tea restore 15 health and 6 sanity.\n\n'
          'The Fishing Pond opens on day 2 or after you craft the rod. A fishing trip costs 2 time '
          'including the return journey; each cast uses 1 bait. Hook on a bite, then hold to reel right '
          'and release to drift left. Keep the marker in the green zone. A perfect catch gives 2 fish. '
          'Cook and eat fish from the inventory for +25 food without spending daylight.\n\n'
          'Some choices can fail. Low sanity makes risky decisions less reliable. '
          'You discover the outcome after choosing.\n\n'
          'At dusk, resolve a night event, then sleep. Sleep uses 10 water and 8 food, '
          'costs 3 sanity, and restores 10 health if you are fed and hydrated. '
          'Empty supplies also cause damage during sleep.\n\n'
          'Event cards show what you can do and what equipment or supplies you need. '
          'After choosing, a popup explains what happened and shows the actual total changes. '
          'Time only passes when you decide. Your run is saved automatically.',
        ),
      ),
    ),
  );
}
