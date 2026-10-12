import 'package:flutter/material.dart';

import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';

class OutcomeDialog extends StatelessWidget {
  const OutcomeDialog({
    super.key,
    required this.report,
    required this.nightNext,
    this.expeditionNext = false,
    this.runEnded = false,
  });
  final ActionReport report;
  final bool nightNext, expeditionNext;
  final bool runEnded;
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: report.title,
    art: 'journal',
    subtitle: 'WHAT HAPPENED',
    actions: [
      ActionCard(
        key: const ValueKey('continue-outcome'),
        title: runEnded
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final change in report.changes.entries)
              CampPanel(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResourceIcon(change.key.toLowerCase(), size: 28),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${change.value > 0 ? '+' : ''}${change.value} ${itemName(change.key)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: change.value > 0
                              ? CanopyColors.leaf
                              : CanopyColors.food,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
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
