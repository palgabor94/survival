import 'condition_strip.dart';
import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/rescue_progress.dart';
import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'card_art.dart';
import 'parchment_components.dart';
import 'scene_artwork.dart';

/// A saved checkpoint after sleep. Closing it acknowledges the existing
/// report; it never applies sleep, dawn bonuses or a day increment again.
class DayEndScreen extends StatelessWidget {
  const DayEndScreen({super.key, required this.game, required this.summary});
  final GameEngine game;
  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final nextTier = game.recipes.nextTier(state);
    final objective = state.rescueStage == RescueStage.storm
        ? 'Keep the signal alive'
        : state.tools.contains('emergency_beacon')
        ? 'Send the rescue signal'
        : nextTier != null
        ? 'Build ${nextTier.name}'
        : 'Build a rescue signal';
    final highlights = summary.highlights.toSet().toList();
    // Keep permanent achievements visible even on a busy day.
    final featured = [
      ...highlights.where(
        (s) => s.startsWith('Crafted:') || s.startsWith('Camp upgraded:'),
      ),
      ...highlights.where((s) => s.startsWith('Explored ')),
      ...highlights.reversed.where(
        (s) =>
            !s.startsWith('Crafted:') &&
            !s.startsWith('Camp upgraded:') &&
            !s.startsWith('Explored '),
      ),
    ].take(3).toList();
    final materials = [
      'wood',
      'stone',
      'fiber',
      ...state.resources.keys.where(
        (id) =>
            ![
              'wood',
              'stone',
              'fiber',
              'small_fish',
              'raw_meat',
              'herb',
              'bait',
            ].contains(id) &&
            state.resource(id) > 0,
      ),
    ];
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const ValueKey('day-end-screen'),
        backgroundColor: const Color(0xFF0D2225),
        body: Stack(
          children: [
            Positioned.fill(
              child: SceneArtwork(asset: campArt(state.campTier)),
            ),
            const Positioned.fill(child: ColoredBox(color: Color(0xB8071A1E))),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: PaperSurface(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                17,
                                15,
                                17,
                                16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const CardArt('moon', size: 50),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const ParchmentLabel(
                                              'END OF DAY',
                                              size: 11,
                                              color: ParchmentColors.muted,
                                            ),
                                            ParchmentLabel(
                                              'DAY ${summary.day} SURVIVED',
                                              size: 21,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Another night in the canopy. You are still here.',
                                    style: TextStyle(fontSize: 12, height: 1.3),
                                  ),
                                  const Divider(height: 22),
                                  const ParchmentLabel(
                                    'TODAY',
                                    size: 11,
                                    color: ParchmentColors.muted,
                                  ),
                                  const SizedBox(height: 5),
                                  if (featured.isEmpty)
                                    const _ProgressLine(
                                      'shelter',
                                      'Made it through the night',
                                    ),
                                  for (final text in featured)
                                    _ProgressLine(_highlightArt(text), text),
                                  const SizedBox(height: 12),
                                  ParchmentLabel(
                                    'GOING INTO DAY ${state.day}',
                                    size: 11,
                                    color: ParchmentColors.muted,
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final stat in SurvivalStat.values)
                                        SizedBox(
                                          width: _statWidth(context),
                                          child: _StatCell(
                                            stat,
                                            state.value(stat),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (state.conditions.isNotEmpty) ...[
                                    ConditionStrip(state: state),
                                    const SizedBox(height: 10),
                                  ],
                                  const ParchmentLabel(
                                    'CAMP MATERIALS',
                                    size: 10,
                                    color: ParchmentColors.muted,
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 9,
                                    children: [
                                      for (final id in materials)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CardArt(id, size: 22),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: ParchmentLabel(
                                                '${state.resource(id)} ${itemName(id)}',
                                                size: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 13),
                                  const Divider(height: 1),
                                  const SizedBox(height: 11),
                                  Row(
                                    children: [
                                      CardArt(
                                        state.rescueStage == RescueStage.storm
                                            ? 'emergency_beacon'
                                            : 'shelter',
                                        size: 29,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const ParchmentLabel(
                                              'TOMORROW',
                                              size: 10,
                                              color: ParchmentColors.muted,
                                            ),
                                            ParchmentLabel(objective, size: 12),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ActionCard(
                                    key: const ValueKey('continue-outcome'),
                                    title: 'Next day  →',
                                    art: 'sun',
                                    asButton: true,
                                    onTap: () => Navigator.pop(context),
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
            ),
          ],
        ),
      ),
    );
  }

  double _statWidth(BuildContext context) {
    final available =
        (MediaQuery.sizeOf(context).width - 36).clamp(0.0, 390.0) - 38;
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return (available - (scale > 1.4 ? 6 : 18)) / (scale > 1.4 ? 2 : 4);
  }

  String _highlightArt(String text) {
    if (text.startsWith('Explored ')) return 'map';
    for (final recipe in game.recipes.recipes) {
      if (text.endsWith(': ${recipe.name}')) {
        return recipe.tier == null ? recipe.id : 'shelter';
      }
    }
    return 'journal';
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine(this.art, this.text);
  final String art, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: ParchmentColors.leaf, size: 17),
        const SizedBox(width: 7),
        CardArt(art, size: 20),
        const SizedBox(width: 7),
        Expanded(child: ParchmentLabel(text, size: 12)),
      ],
    ),
  );
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.stat, this.value);
  final SurvivalStat stat;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('day-end-stat-${stat.name}'),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    decoration: BoxDecoration(
      color: const Color(0x55E0D3AF),
      border: Border.all(color: const Color(0xFFBAA981)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CardArt(stat.name, size: 22),
            const SizedBox(width: 2),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: ParchmentLabel(
                  '$value',
                  size: 11,
                  align: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Semantics(
          label: stat.label,
          value: '$value out of 100',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value.clamp(0, 100) / 100,
              minHeight: 5,
              backgroundColor: const Color(0xFFD1C5A3),
              color: switch (stat) {
                SurvivalStat.health => const Color(0xFFC14C3E),
                SurvivalStat.water => const Color(0xFF298CA2),
                SurvivalStat.food => const Color(0xFFA86A35),
                SurvivalStat.sanity => const Color(0xFF87639C),
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(8) * 1.25,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ParchmentLabel(
              stat.label.toUpperCase(),
              size: 8,
              color: ParchmentColors.muted,
            ),
          ),
        ),
      ],
    ),
  );
}
