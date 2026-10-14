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
  Widget build(BuildContext context) => CanopyDialog(
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
        Text(
          report.changes.isEmpty
              ? 'Your stats and supplies did not change.'
              : 'CHANGES',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: CanopyColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        CampPanel(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              for (final change in report.changes.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      ResourceIcon(change.key.toLowerCase(), size: 26),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ParchmentLabel(_changeLabel(change), size: 12),
                      ),
                      const SizedBox(width: 8),
                      ParchmentLabel(
                        '${change.value > 0 ? '+' : ''}${change.value}',
                        size: 13,
                        color: change.value > 0
                            ? CanopyColors.leaf
                            : CanopyColors.food,
                      ),
                    ],
                  ),
                ),
              if (state != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      const ResourceIcon('sun', size: 26),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: ParchmentLabel('Daylight remaining', size: 12),
                      ),
                      ParchmentLabel('${state!.timeLeft} / 6', size: 13),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
  String _changeLabel(MapEntry<String, int> change) {
    final name = itemName(change.key);
    if (state == null) return name;
    final stat = SurvivalStat.values
        .where((s) => s.label.toLowerCase() == change.key.toLowerCase())
        .firstOrNull;
    final after = stat == null
        ? state!.resource(change.key)
        : state!.value(stat);
    return '$name · ${after - change.value} → $after';
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
