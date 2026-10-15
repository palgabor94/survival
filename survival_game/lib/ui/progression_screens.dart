import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../game/run_progression.dart';
import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'card_art.dart';
import 'camp_widgets.dart' show campArt;

import 'parchment_components.dart';
import 'inventory_panels.dart' show InventoryPicture;

const ink = ParchmentColors.ink;
const leaf = ParchmentColors.leaf;
const cream = ParchmentColors.cream;
const muted = ParchmentColors.muted;
const rust = ParchmentColors.rust;
void noop() {}
Widget gap([double h = 12]) => SizedBox(height: h);
Widget column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: children,
);
Widget label(String text, {double size = 13, Color color = ink}) =>
    ParchmentLabel(text, size: size, weight: FontWeight.w600, color: color);
Widget section(String text) => Padding(
  padding: const EdgeInsets.only(top: 12, bottom: 8),
  child: label(text, size: 11, color: muted),
);
Widget button(
  String text, {
  bool secondary = false,
  VoidCallback? action,
  bool enabled = true,
  Key? key,
}) => parchmentButton(
  text,
  enabled ? action ?? noop : null,
  secondary: secondary,
  key: key,
);
Widget line(
  String name,
  String value, {
  String? art,
  Color color = ink,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    children: [
      if (art != null) ...[CardArt(art, size: 26), const SizedBox(width: 10)],
      Expanded(child: label(name, size: 12)),
      const SizedBox(width: 12),
      Flexible(child: label(value, size: 13, color: color)),
    ],
  ),
);
Widget notice(String text, {bool warning = false}) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: warning ? const Color(0x148F4E37) : const Color(0x14294E36),
    border: Border(left: BorderSide(color: warning ? rust : leaf, width: 3)),
  ),
  child: label(text, size: 12),
);
Widget progress({required int total}) {
  final rank = rankFor(total), floor = rankThreshold(rank);
  final next = rank == 10 ? null : rankThreshold(rank + 1);
  return column([
    line('RANK $rank · ${rankNames[rank - 1].toUpperCase()}', '$total XP'),
    LinearProgressIndicator(
      value: next == null ? 1 : (total - floor) / (next - floor),
      minHeight: 10,
      color: leaf,
      backgroundColor: const Color(0xFFCABE98),
    ),
    gap(6),
    label(
      next == null
          ? 'MAX RANK'
          : '${next - total} XP to next rank · $next XP total',
      size: 11,
      color: muted,
    ),
  ]);
}

Widget metrics(List<(String, String)> values) => LayoutBuilder(
  builder: (context, box) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        SizedBox(
          width: (box.maxWidth - 16) / 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            color: const Color(0x12294E36),
            child: Column(
              children: [
                label(v.$2, size: 19),
                gap(2),
                label(v.$1, size: 10, color: muted),
              ],
            ),
          ),
        ),
    ],
  ),
);
Widget page(
  String title,
  String subtitle,
  List<Widget> body, {
  String art = 'journal',
  List<Widget> actions = const [],
  bool close = true,
  VoidCallback? onClose,
}) => Builder(
  builder: (context) => Scaffold(
    backgroundColor: const Color(0xFF102A28),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: PaperSurface(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        CardArt(art, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: column([
                            label(subtitle, size: 10, color: muted),
                            gap(2),
                            label(title, size: 21),
                          ]),
                        ),
                        if (close)
                          ParchmentClose(
                            onPressed:
                                onClose ?? () => Navigator.maybePop(context),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: column(body),
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: column([
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) gap(8),
                          actions[i],
                        ],
                      ]),
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

class _Watch extends StatefulWidget {
  const _Watch({required this.game, required this.builder});
  final GameEngine game;
  final Widget Function() builder;
  @override
  State<_Watch> createState() => _WatchState();
}

class _WatchState extends State<_Watch> {
  void update() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.game.addListener(update);
  }

  @override
  void dispose() {
    widget.game.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder();
}

Future<T?> _open<T>(BuildContext context, Widget screen) =>
    Navigator.push<T>(context, MaterialPageRoute(builder: (_) => screen));
Widget saveNotice(GameEngine game) => game.saveFailed
    ? column([
        notice(
          'Could not save your record. Your previous save is preserved.',
          warning: true,
        ),
        gap(8),
        button(
          'RETRY SAVE',
          action: () => game.retrySave(),
          key: const ValueKey('retry-record-save'),
        ),
      ])
    : game.saving
    ? label('Saving your record…', size: 12)
    : const SizedBox.shrink();
String causeLabel(String? source) {
  if (source == null || source == 'action') return 'Your health reached zero.';
  if (source.startsWith('poisoned:')) {
    return 'Poisoned ${source.endsWith('2') ? 'II' : 'I'} caused the final health loss.';
  }
  if (source == 'deprivation') {
    return 'Lack of food or water caused the final health loss.';
  }
  if (source.startsWith('encounter:')) {
    return 'The ${source.substring(10).replaceAll('_', ' ')} encounter caused the final health loss.';
  }
  return 'An event caused the final health loss.';
}

String recordLabel(RunMetrics m) => m.legacyEnded
    ? 'Legacy record · no XP awarded'
    : m.partialSince != null
    ? 'Partial record · tracking began on Day ${m.partialSince}'
    : 'Journey record';

class RunResultScreen extends StatelessWidget {
  const RunResultScreen({
    super.key,
    required this.game,
    this.summary,
    this.historical = false,
  });
  final GameEngine game;
  final RunSummary? summary;
  final bool historical;
  @override
  Widget build(BuildContext context) => _Watch(
    game: game,
    builder: () {
      final s = summary ?? game.completedRun;
      if (s == null) return const SizedBox.shrink();
      final m = s.metrics;
      final rescued = s.outcome == 'rescued';
      final background = rescued
          ? 'assets/art/rescue_arrival_camp_style_v1.png'
          : s.location == 'camp'
          ? campArt(m.campTier)
          : game.world.find(s.location)?.background ??
                'assets/art/riverbank_camp_style_v2.png';
      return page(
        rescued
            ? 'RESCUED'
            : s.outcome == 'abandoned'
            ? 'JOURNEY ENDED'
            : 'JOURNEY ENDED',
        'REACHED DAY ${s.day} · ${recordLabel(m).toUpperCase()}',
        [
          AspectRatio(
            aspectRatio: 1.65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  background,
                  fit: BoxFit.cover,
                  alignment: rescued
                      ? const Alignment(0, -.8)
                      : const Alignment(0, .2),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD7102A28)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 14,
                  right: 16,
                  child: column([
                    label(
                      '${m.nights} NIGHTS SURVIVED',
                      size: 23,
                      color: cream,
                    ),
                    label(
                      rescued
                          ? 'Rescued on Day ${s.day}'
                          : 'Your record stays with you.',
                      size: 12,
                      color: cream,
                    ),
                  ]),
                ),
              ],
            ),
          ),
          gap(),
          notice(
            rescued
                ? 'You kept the beacon alive through ${m.stormSteps}/3 storm challenges.'
                : s.outcome == 'abandoned'
                ? 'You ended this journey. Earned achievements are recorded.'
                : causeLabel(m.fatalCause),
            warning: !rescued,
          ),
          if (m.contributing.isNotEmpty) ...[
            gap(8),
            label('Also active: ${m.contributing.join(' · ')}', size: 12),
          ],
          gap(),
          metrics([
            ('Locations', '${m.locations.length}/6'),
            ('Fish caught', '${m.fishCaught}'),
            ('Items made', '${m.crafted}'),
            ('Camp tier', '${m.campTier}'),
            ('Components', '${m.components.length}/5'),
            ('Storm steps', '${m.stormSteps}/3'),
          ]),
          gap(),
          line(
            game.saving || game.saveFailed
                ? 'SURVIVAL XP · AWAITING SAVE'
                : 'SURVIVAL XP RECORDED',
            '+${s.earned} XP',
          ),
          label(
            '${s.xpBefore} → ${s.xpAfter} total XP · Rank ${rankFor(s.xpAfter)}',
            size: 12,
          ),
          gap(),
          button(
            'VIEW XP BREAKDOWN',
            secondary: true,
            action: () => _open(context, XpScreen(game: game, summary: s)),
          ),
          saveNotice(game),
        ],
        art: rescued ? 'shelter' : 'health',
        close: historical,
        actions: [
          if (!historical)
            button(
              'VIEW PROFILE',
              key: const ValueKey('view-profile'),
              action: () async {
                final restarted = await openProfile(context, game);
                if (restarted == true && context.mounted) {
                  Navigator.pop(context, 'restarted');
                }
              },
            ),
          Row(
            children: [
              Expanded(
                child: button(
                  'JOURNEY DETAILS',
                  secondary: true,
                  action: () => _open(
                    context,
                    JourneyDetailsScreen(game: game, summary: s),
                  ),
                ),
              ),
              if (!historical) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: button(
                    'NEW JOURNEY',
                    secondary: true,
                    key: ValueKey(
                      rescued ? 'rescue-new-run' : 'result-new-run',
                    ),
                    enabled: game.canStartNewRun,
                    action: () async {
                      final yes = await _open<bool>(
                        context,
                        NewJourneyScreen(
                          game: game,
                          confirmKey: ValueKey(
                            rescued
                                ? 'confirm-rescue-new-run'
                                : 'confirm-new-run',
                          ),
                        ),
                      );
                      if (yes == true && context.mounted) {
                        Navigator.pop(context, 'restarted');
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}

class XpScreen extends StatelessWidget {
  const XpScreen({super.key, required this.game, required this.summary});
  final GameEngine game;
  final RunSummary summary;
  @override
  Widget build(BuildContext context) => page(
    'SURVIVAL XP',
    'DAY ${summary.day} · ${recordLabel(summary.metrics)}',
    [
      label('+${summary.earned} XP', size: 34),
      section('WHAT YOU ACHIEVED'),
      for (final e in summary.xp.entries) line(e.key, '+${e.value}'),
      const Divider(),
      line('TOTAL THIS JOURNEY', '+${summary.earned} XP'),
      gap(),
      progress(total: summary.xpAfter),
      gap(),
      notice(
        'Each unique recipe, species, place and encounter earns its category bonus once per journey. Practice gives no XP.',
      ),
    ],
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.game});
  final GameEngine game;
  @override
  Widget build(BuildContext context) => _Watch(
    game: game,
    builder: () {
      final p = game.profile;
      return page(
        'SURVIVOR PROFILE',
        'LOCAL RECORD · SAVED ON THIS DEVICE',
        [
          label(
            'RANK ${p.rank} · ${rankNames[p.rank - 1].toUpperCase()}',
            size: 26,
          ),
          gap(),
          progress(total: p.xp),
          if (p.journeys == 0) ...[
            gap(),
            notice('Finish a journey to start your record.'),
          ],
          section('YOUR RECORD'),
          metrics([
            ('Journeys', '${p.journeys}'),
            ('Rescues', '${p.rescues}'),
            ('Best nights', '${p.bestNights}'),
            ('Fish caught', '${p.fishCaught}'),
            ('Items made', '${p.crafted}'),
            ('Places seen', '${p.locations.length}/6'),
          ]),
          gap(),
          line('Lost / Abandoned', '${p.lost} / ${p.abandoned}'),
          line(
            'Fastest rescue',
            p.fastestRescue == null
                ? 'Not rescued yet'
                : 'Day ${p.fastestRescue}',
          ),
          line('Fish species recorded', '${p.fishSpecies.length}/5'),
          section('NEXT JOURNEY'),
          line(
            'Starting option',
            optionById(p.nextOption).name,
            art: 'inventory',
          ),
          button(
            'CHOOSE STARTING OPTION',
            secondary: true,
            key: const ValueKey('profile-options'),
            action: () => _open(context, StartingOptionsScreen(game: game)),
          ),
          gap(),
          button(
            'JOURNEY ARCHIVE · ${p.archive.length}',
            secondary: true,
            key: const ValueKey('profile-archive'),
            action: () => _open(context, ArchiveScreen(game: game)),
          ),
          gap(),
          notice(
            'XP and records persist. Camp, gear and supplies start fresh each journey.',
          ),
          gap(),
          saveNotice(game),
        ],
        actions: [
          button(
            'NEW JOURNEY',
            enabled: game.canStartNewRun,
            key: const ValueKey('profile-new-run'),
            action: () async {
              final yes = await _open<bool>(
                context,
                NewJourneyScreen(game: game),
              );
              if (yes == true && context.mounted) Navigator.pop(context, true);
            },
          ),
        ],
      );
    },
  );
}

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, required this.game});
  final GameEngine game;
  @override
  Widget build(BuildContext context) =>
      page('YOUR JOURNEYS', 'LATEST 20 · LIFETIME RECORDS ARE KEPT', [
        if (game.profile.archive.isEmpty)
          notice('Finish a journey to start your record.'),
        for (final s in game.profile.archive) ...[
          PaperSurface(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: column([
                label('DAY ${s.day} · ${s.outcome.toUpperCase()}', size: 18),
                gap(6),
                label(
                  '${s.metrics.nights} nights · ${recordLabel(s.metrics)}',
                  size: 12,
                ),
                line('SURVIVAL XP', '+${s.earned} XP'),
                button(
                  'VIEW JOURNEY',
                  secondary: true,
                  key: ValueKey('archive-${s.id}'),
                  action: () => _open(
                    context,
                    RunResultScreen(game: game, summary: s, historical: true),
                  ),
                ),
              ]),
            ),
          ),
          gap(),
        ],
      ]);
}

class JourneyDetailsScreen extends StatelessWidget {
  const JourneyDetailsScreen({
    super.key,
    required this.game,
    required this.summary,
  });
  final GameEngine game;
  final RunSummary summary;
  @override
  Widget build(BuildContext context) => page(
    'JOURNEY DETAILS',
    'DAY ${summary.day} · ${summary.outcome.toUpperCase()}',
    [
      if (summary.outcome == 'lost')
        notice(causeLabel(summary.metrics.fatalCause), warning: true),
      section(recordLabel(summary.metrics).toUpperCase()),
      if (summary.metrics.milestones.isEmpty)
        notice('No detailed milestones were recorded for this journey.'),
      for (final m in summary.metrics.milestones) ...[
        line(
          'DAY ${m.day} · ${game.world.find(m.location)?.name ?? m.location}',
          '',
          art: m.art,
        ),
        label(m.title, size: 14),
        gap(16),
      ],
      section('FINAL SURVIVAL STATS'),
      for (final stat in SurvivalStat.values) ...[
        line(stat.label, '${summary.stats[stat] ?? 0}/100', art: stat.name),
        LinearProgressIndicator(
          value: (summary.stats[stat] ?? 0) / 100,
          color: leaf,
        ),
      ],
      gap(),
      line(
        'Fish caught / kept',
        '${summary.metrics.fishCaught} / ${summary.metrics.fishKept}',
      ),
      line('Starting option', optionById(summary.metrics.option).name),
      button(
        'VIEW XP BREAKDOWN',
        secondary: true,
        action: () => _open(context, XpScreen(game: game, summary: summary)),
      ),
    ],
  );
}

class StartingOptionsScreen extends StatelessWidget {
  const StartingOptionsScreen({super.key, required this.game});
  final GameEngine game;
  @override
  Widget build(BuildContext context) => _Watch(
    game: game,
    builder: () => page(
      'STARTING OPTION',
      'CHOOSE 0 OR 1 · NEXT JOURNEY ONLY',
      [
        notice(
          'Choose a small supply trade. Your current journey does not change.',
        ),
        gap(16),
        ParchmentCardGrid(
          children: [
            for (final p in startingOptions)
              ParchmentCard(
                key: ValueKey('option-${p.id}'),
                title: p.name,
                art: p.art,
                info: p.rank == 1
                    ? 'Standard start'
                    : 'Rank ${p.rank} · ${rankThreshold(p.rank)} XP',
                status: !game.profile.canSelect(p.id)
                    ? 'LOCKED'
                    : game.profile.nextOption == p.id
                    ? 'SELECTED'
                    : 'AVAILABLE',
                selected: game.profile.nextOption == p.id,
                onTap: () =>
                    _open(context, OptionDetailsScreen(game: game, option: p)),
              ),
          ],
        ),
        gap(),
        saveNotice(game),
      ],
    ),
  );
}

class OptionDetailsScreen extends StatelessWidget {
  const OptionDetailsScreen({
    super.key,
    required this.game,
    required this.option,
  });
  final GameEngine game;
  final StartingOption option;
  @override
  Widget build(BuildContext context) => _Watch(
    game: game,
    builder: () => page(
      option.name.toUpperCase(),
      'RANK ${option.rank} · ${game.profile.canSelect(option.id) ? 'UNLOCKED' : 'LOCKED'}',
      [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: InventoryPicture(option.art),
            ),
          ),
        ),
        gap(),
        label(option.description, size: 17),
        section('STARTING SUPPLY TRADE'),
        if (option.items.isEmpty)
          notice('Standard starting supplies. No trade.'),
        for (final e in option.items.entries)
          line(
            itemName(e.key),
            '${e.value > 0 ? '+' : ''}${e.value}',
            art: e.key,
            color: e.value < 0 ? rust : leaf,
          ),
        if (option.food != 0)
          line('Food', '${option.food}', art: 'food', color: rust),
        gap(),
        notice(
          'Applies only when a new journey starts. Supplies go into camp storage. Starting backpack: 8 slots.',
        ),
      ],
      art: option.art,
      actions: [
        button(
          game.profile.canSelect(option.id)
              ? 'SELECT FOR NEXT JOURNEY'
              : 'REQUIRES RANK ${option.rank} · ${rankThreshold(option.rank)} XP',
          enabled: game.profile.canSelect(option.id),
          key: const ValueKey('select-next-option'),
          action: () {
            game.selectStartingOption(option.id);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

class NewJourneyScreen extends StatefulWidget {
  const NewJourneyScreen({
    super.key,
    required this.game,
    this.confirmKey = const ValueKey('confirm-new-run'),
  });
  final GameEngine game;
  final Key confirmKey;
  @override
  State<NewJourneyScreen> createState() => _NewJourneyScreenState();
}

class _NewJourneyScreenState extends State<NewJourneyScreen> {
  GameEngine get game => widget.game;
  Key get confirmKey => widget.confirmKey;
  bool _working = false, _resetDone = false;
  @override
  Widget build(BuildContext context) => _Watch(
    game: game,
    builder: () {
      final active = game.completedRun == null;
      final p = optionById(game.profile.nextOption);
      return page(
        active ? 'END THIS JOURNEY?' : 'BEGIN AGAIN?',
        active
            ? 'CURRENT JOURNEY WILL BE ARCHIVED'
            : 'NEXT JOURNEY · FINAL REVIEW',
        [
          if (active)
            notice(
              'Your current camp and supplies will be replaced. Earned XP will be recorded once.',
              warning: true,
            ),
          section('YOUR NEXT START'),
          line('Starting option', p.name, art: 'inventory'),
          for (final id in ['wood', 'stone', 'bait', 'bandage'])
            line(
              'Camp storage · ${itemName(id)}',
              '${(id == 'wood' ? 2 : 0) + (p.items[id] ?? 0)}',
              art: id,
            ),
          line('Starting Food', '${75 + p.food}', art: 'food'),
          line('Backpack', '8 slots · empty', art: 'inventory'),
          button(
            'CHANGE STARTING OPTION',
            secondary: true,
            action: () => _open(context, StartingOptionsScreen(game: game)),
          ),
          section('KEPT IN YOUR PROFILE'),
          line('Lifetime XP', '${game.profile.xp} XP', art: 'journal'),
          label(
            'Ranks, unlocked options, records and archived journeys stay with you.',
          ),
          section('A FRESH JOURNEY'),
          label(
            'Day 1 · Camp Tier 0. Gear, camp upgrades and rescue search start fresh.',
          ),
          gap(),
          saveNotice(game),
        ],
        onClose: _working ? noop : () => Navigator.pop(context, false),
        actions: [
          button(
            _resetDone
                ? 'CONTINUE NEW JOURNEY'
                : active
                ? 'END & START NEW JOURNEY'
                : 'START NEW JOURNEY',
            key: confirmKey,
            enabled: game.canStartNewRun && !_working,
            action: () async {
              if (_working) return;
              setState(() => _working = true);
              if (_resetDone) {
                Navigator.pop(context, true);
                return;
              }
              if (active) {
                game.abandonJourney();
                await game.saveSettled;
              }
              if (!game.canStartNewRun || !context.mounted) {
                if (mounted) setState(() => _working = false);
                return;
              }
              game.restart();
              _resetDone = true;
              await game.saveSettled;
              if (mounted) setState(() => _working = false);
              if (context.mounted && game.canStartNewRun) {
                Navigator.pop(context, true);
              }
            },
          ),
          button(
            active ? 'Keep playing' : 'Keep summary',
            enabled: !_working,
            secondary: true,
            action: () => Navigator.pop(context, false),
          ),
        ],
      );
    },
  );
}

Future<bool?> openProfile(BuildContext context, GameEngine game) async {
  if (game.rankNoticePending && game.completedRun != null) {
    await _open(
      context,
      RankUnlockedScreen(game: game, summary: game.completedRun!),
    );
    game.acknowledgeRank();
  }
  if (!context.mounted) return null;
  return _open<bool>(context, ProfileScreen(game: game));
}

class RankUnlockedScreen extends StatelessWidget {
  const RankUnlockedScreen({
    super.key,
    required this.game,
    required this.summary,
  });
  final GameEngine game;
  final RunSummary summary;
  @override
  Widget build(BuildContext context) {
    final before = rankFor(summary.xpBefore), after = rankFor(summary.xpAfter);
    final unlocked = startingOptions.where(
      (p) => p.rank > before && p.rank <= after,
    );
    return page(
      'RANK $after · ${rankNames[after - 1].toUpperCase()}',
      'NEW RANK RECORDED',
      [
        gap(24),
        const Center(child: CardArt('journal', size: 96)),
        gap(24),
        label('${rankNames[before - 1]} → ${rankNames[after - 1]}', size: 20),
        gap(16),
        progress(total: summary.xpAfter),
        section('NEW STARTING OPTIONS'),
        if (unlocked.isEmpty)
          notice(
            'A new rank recorded. Starting options unlock at ranks 3, 5 and 7.',
          ),
        ParchmentCardGrid(
          children: [
            for (final p in unlocked)
              ParchmentCard(
                title: p.name,
                art: p.art,
                info: 'Rank ${p.rank}',
                status: 'UNLOCKED',
                onTap: () =>
                    _open(context, OptionDetailsScreen(game: game, option: p)),
              ),
          ],
        ),
        gap(16),
        notice(
          'No perk is selected automatically. Choose an option for your next journey.',
        ),
      ],
      actions: [button('VIEW PROFILE', action: () => Navigator.pop(context))],
    );
  }
}
