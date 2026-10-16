import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import 'first_day_guide.dart';
import 'canopy_components.dart';
import 'camp_widgets.dart';
import 'parchment_components.dart';
import 'fishing_screen.dart';

class SurvivalGuideDialog extends StatelessWidget {
  const SurvivalGuideDialog({super.key, this.game});
  final GameEngine? game;
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: 'How to survive',
    art: 'journal',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParchmentLabel(
          'Time moves when you decide. Your run saves automatically.',
          size: 13,
          weight: FontWeight.w500,
        ),
        const SizedBox(height: 10),
        CampPanel(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              if (game != null)
                ParchmentMenuRow(
                  key: const ValueKey('guide-first-day'),
                  title: 'First-day guide',
                  art: 'journal',
                  onTap: () => showDialog<void>(
                    context: context,
                    routeSettings: const RouteSettings(
                      name: 'first_day_reference',
                    ),
                    builder: (_) => FirstDayReference(game: game!),
                  ),
                ),
              const ParchmentMenuRow(
                title: '6 time each day',
                art: 'sun',
                onTap: null,
                trailing: '',
              ),
              const ParchmentMenuRow(
                title: 'Each time: 4 water, 3 food',
                art: 'water',
                onTap: null,
                trailing: '',
              ),
              ParchmentMenuRow(
                key: const ValueKey('guide-workshop'),
                title: 'Build tools and shelter',
                art: 'craft',
                onTap: () => Navigator.pop(context, 'workshop'),
              ),
              const ParchmentMenuRow(
                title: 'Prepare for nightfall',
                art: 'moon',
                onTap: null,
                trailing: '',
              ),
              ParchmentMenuRow(
                key: const ValueKey('guide-fishing'),
                title: 'Fishing tutorial',
                art: 'basic_rod',
                onTap: () => showDialog<void>(
                  context: context,
                  routeSettings: const RouteSettings(name: 'fishing_tutorial'),
                  builder: (_) => const FishingTutorial(),
                ),
              ),
              for (final (id, title, art) in [
                ('chopping', 'Wood chopping tutorial', 'stone_axe'),
                ('plants', 'Plant gathering tutorial', 'herb'),
                ('hunting', 'Hunting tutorial', 'stone_spear'),
                ('ruins', 'Stone seal tutorial', 'stone'),
              ])
                ParchmentMenuRow(
                  key: ValueKey('guide-$id'),
                  title: title,
                  art: art,
                  onTap: () => showDialog<void>(
                    context: context,
                    routeSettings: const RouteSettings(
                      name: 'skill_guide_dialog',
                    ),
                    builder: (_) => SkillGuideDialog(kind: id),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SkillGuideDialog extends StatelessWidget {
  const SkillGuideDialog({super.key, required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) {
    final (title, art, steps) = switch (kind) {
      'chopping' => (
        'WOOD CHOPPING',
        'stone_axe',
        [
          'Start one attempt for 1 daylight. Bring a usable Stone Axe.',
          'Tap Chop when the marker reaches the middle of the timing bar.',
          'Land three strikes before the timer ends. Accurate hits improve your result.',
        ],
      ),
      'plants' => (
        'PLANT GATHERING',
        'herb',
        [
          'Start one attempt for 1 daylight.',
          'Choose up to three different plants before time runs out.',
          'Gathering stores portions in Items; it does not feed you immediately. Eat later at camp or a calm expedition stop.',
          'Species always have the same properties. Study an unknown sample at camp for 1 time. Ember berries are safe; some roots need preparation.',
          'Antidotes clear poison. Bandages clear injury. Rest helps fatigue; shelter and a campfire dry wet clothes.',
        ],
      ),
      'hunting' => (
        'HUNTING',
        'stone_spear',
        [
          'Bring a usable Stone Spear. Start costs 1 daylight.',
          'Watch the moving timing marker.',
          'Tap Throw once at the centre. You discover the outcome after the attempt.',
        ],
      ),
      _ => (
        'STONE SEAL',
        'stone',
        [
          'Read the symbol sequence carved above the altar.',
          'Tap a stone disc to rotate its symbol. Match all three to the carved sequence.',
          'Choose Align to check the seal. Each attempt costs 1 daylight; leaving preserves the puzzle.',
        ],
      ),
    };
    return CanopyDialog(
      title: title,
      art: art,
      subtitle: 'HOW IT WORKS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampPanel(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ParchmentLabel(
                          '${i + 1}',
                          size: 18,
                          color: ParchmentColors.leaf,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ParchmentLabel(
                            steps[i],
                            size: 13,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const ParchmentLabel(
            'Reading this guide costs no daylight.',
            size: 12,
            color: ParchmentColors.muted,
          ),
        ],
      ),
    );
  }
}
