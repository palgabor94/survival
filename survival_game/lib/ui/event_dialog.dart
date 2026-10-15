import 'package:flutter/material.dart';

import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';
import 'parchment_components.dart';

class OutcomeDialog extends StatelessWidget {
  const OutcomeDialog({
    super.key,
    required this.report,
    required this.nightNext,
    this.expeditionNext = false,
    this.runEnded = false,
    this.runRescued = false,
    this.state,
  });
  final ActionReport report;
  final RunState? state;
  final bool nightNext, expeditionNext;
  final bool runEnded;
  final bool runRescued;
  @override
  Widget build(BuildContext context) {
    final vitals = report.changes.entries.where(_isVital).toList();
    final supplies = report.changes.entries.where((e) => !_isVital(e)).toList();
    return CanopyDialog(
      title: report.title,
      art: 'journal',
      subtitle: 'WHAT HAPPENED',
      actions: [
        ActionCard(
          key: const ValueKey('continue-outcome'),
          title: runRescued
              ? 'View run summary'
              : runEnded
              ? 'Continue'
              : nightNext
              ? 'Night is falling'
              : expeditionNext
              ? 'Press on'
              : 'Back to camp',
          art: nightNext
              ? 'moon'
              : expeditionNext
              ? 'trail'
              : 'back',
          tone: CardTone.river,
          horizontal: true,
          onTap: () => Navigator.pop(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              report.body,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          for (final change in report.conditionChanges)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ParchmentLabel(
                change,
                size: 12,
                color: ParchmentColors.rust,
              ),
            ),
          if (report.changes.isEmpty && report.conditionChanges.isEmpty)
            const ParchmentLabel(
              'No change to your stats or supplies.',
              size: 12,
              color: ParchmentColors.muted,
            ),
          if (vitals.isNotEmpty) _changeGroup('VITALS', vitals),
          if (supplies.isNotEmpty) _changeGroup('SUPPLIES', supplies),
          if (state != null) ...[
            const Divider(height: 18),
            Row(
              children: [
                const ResourceIcon('sun', size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: ParchmentLabel('DAYLIGHT LEFT', size: 11),
                ),
                ParchmentLabel('${state!.timeLeft} / 6', size: 13),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _isVital(MapEntry<String, int> change) => SurvivalStat.values.any(
    (stat) => stat.label.toLowerCase() == change.key.toLowerCase(),
  );

  Widget _changeGroup(String title, List<MapEntry<String, int>> changes) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ParchmentLabel(title, size: 11, color: ParchmentColors.muted),
            const SizedBox(height: 4),
            for (final change in changes) _changeRow(change),
          ],
        ),
      );

  Widget _changeRow(MapEntry<String, int> change) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        ResourceIcon(change.key.toLowerCase(), size: 25),
        const SizedBox(width: 8),
        Expanded(child: ParchmentLabel(itemName(change.key), size: 12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ParchmentLabel(
              '${change.value > 0 ? '+' : ''}${change.value}',
              size: 14,
              color: change.value > 0 ? CanopyColors.leaf : CanopyColors.food,
            ),
            if (state != null)
              ParchmentLabel(
                '${_afterValue(change)} ${change.value < 0 ? 'left' : 'now'}',
                size: 10,
                color: ParchmentColors.muted,
                weight: FontWeight.w600,
              ),
          ],
        ),
      ],
    ),
  );

  int _afterValue(MapEntry<String, int> change) {
    final stat = SurvivalStat.values
        .where((s) => s.label.toLowerCase() == change.key.toLowerCase())
        .firstOrNull;
    return stat == null ? state!.resource(change.key) : state!.value(stat);
  }
}

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({super.key, required this.day});
  final int day;
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: 'The jungle falls silent',
    art: 'shelter',
    subtitle: 'RUN ENDED',
    actions: [
      ActionCard(
        title: 'Begin again',
        art: 'shelter',
        horizontal: true,
        tag: 'NEW RUN',
        onTap: () => Navigator.pop(context),
      ),
    ],
    child: Text(
      'Your journey ended on day $day.\nEvery attempt teaches you how to survive.',
    ),
  );
}
