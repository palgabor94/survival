import 'parchment_components.dart';
import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_theme.dart';
import 'scene_layout.dart';

/// The push-your-luck moment: carry what you have home, or go deeper for
/// better finds with a danger that grows every step. Pops with `return` or
/// `deeper`.
class ExpeditionScene extends StatelessWidget {
  const ExpeditionScene({super.key, required this.game});
  final GameEngine game;

  @override
  Widget build(BuildContext context) {
    final trip = game.expedition!;
    final state = game.state;
    final place = game.world.find(trip.locationId);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
    final loot = trip.loot.entries.where((e) => e.value > 0).toList();
    final chance = (game.nextEncounterChance * 100).round();
    final canGo = game.canGoDeeper;

    return SceneLayout(
      state: state,
      background: place?.background ?? campArt(state.campTier),
      backgroundAlignment: trip.locationId == 'riverbank'
          ? const Alignment(-.2, -.15)
          : const Alignment(0, .1),
      panel: SituationPanel(
        eyebrow:
            '${(place?.name ?? 'THE JUNGLE').toUpperCase()} · '
            'STEP ${trip.depth + 1}',
        title: 'Push on, or head home?',
        description: loot.isEmpty
            ? 'You have found nothing worth carrying yet. Going deeper costs '
                  'daylight, and the jungle gets less friendly.'
            : 'Your pack is heavy with what you found. Dropping it to run '
                  'would be a hard thing to do.',
        sceneArt: 2,
        collapsedDescription: true,
        note: canGo
            ? 'Tap a card to view costs and confirm.'
            : 'Not enough daylight to go deeper.',
      ),
      beforeCards: CampPanel(
        child: Column(
          children: [
            parchmentButton(
              'USE ITEMS',
              () => Navigator.pop(context, 'items'),
              secondary: true,
            ),
            const SizedBox(height: 8),
            if (loot.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in loot)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ResourceIcon(item.key, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            '${item.value} ${itemName(item.key)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            _DangerMeter(depth: trip.depth),
          ],
        ),
      ),
      cards: [
        ActionCard(
          confirmDetails: true,
          key: const ValueKey('expedition-return'),
          title: 'Return to camp',
          tone: CardTone.river,
          art: 'shelter',
          description: 'Keep carried loot.',
          icon: Icons.home_rounded,
          tag: 'SAFE',
          lines: [
            if (loot.isEmpty)
              const CardLine('Nothing gathered', color: CanopyColors.gold),
          ],
          compact: true,
          horizontal: largeText,
          onTap: () => Navigator.pop(context, 'return'),
        ),
        ActionCard(
          confirmDetails: true,
          key: const ValueKey('expedition-deeper'),
          available: {
            'time': state.timeLeft,
            'water': state.value(SurvivalStat.water),
            'food': state.value(SurvivalStat.food),
          },
          title: 'Go deeper',
          tone: CardTone.danger,
          art: 'trail',
          description: 'Better loot · danger rises',
          icon: Icons.trending_up_rounded,
          tag: chance == 0 ? 'CALM' : '$chance% DANGER',
          tagColor: chance == 0 ? CanopyColors.leaf : CanopyColors.food,
          lines: [
            CardLine(
              canGo ? '−1 time · −4 water · −3 food' : 'No daylight left',
              color: canGo ? CanopyColors.leaf : CanopyColors.muted,
              icon: canGo ? Icons.arrow_upward_rounded : Icons.lock_rounded,
            ),
          ],
          compact: true,
          horizontal: largeText,
          onTap: canGo ? () => Navigator.pop(context, 'deeper') : null,
        ),
      ],
    );
  }
}

class _DangerMeter extends StatelessWidget {
  const _DangerMeter({required this.depth});
  final int depth;

  @override
  Widget build(BuildContext context) {
    final level = (depth + 1).clamp(1, 4);
    return Semantics(
      label: 'Danger level $level of 4',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DANGER',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: CanopyColors.muted,
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 1; i <= 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: i <= level
                      ? CanopyColors.health
                      : CanopyColors.border.withValues(alpha: .4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
