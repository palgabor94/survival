import 'package:flutter/material.dart';

import '../game/event_catalog.dart';
import '../game/game_engine.dart';
import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'choice_icon.dart';
import 'scene_layout.dart';

/// A situation: the scene behind it, what is happening, and one card per
/// thing the survivor can do about it given their stats and gear.
/// Pops with the id of the chosen card.
class EventScene extends StatelessWidget {
  const EventScene({super.key, required this.game});
  final GameEngine game;

  String _background(GameEvent event, RunState state) {
    if (event.background != null) return event.background!;
    if (event.id == 'jaguar_trail') {
      return 'assets/art/jaguar_encounter_isometric.png';
    }
    if (state.phase == RunPhase.night) {
      return state.campTier == 0
          ? 'assets/art/starter_camp_night.png'
          : campArt(state.campTier);
    }
    final locationBackground = game.world.find(state.locationId)?.background;
    if (locationBackground != null) return locationBackground;
    if (state.locationId == 'riverbank') {
      return 'assets/art/riverbank_isometric.png';
    }
    return campArt(state.campTier);
  }

  String _eyebrow(GameEvent event, RunState state) {
    final place = game.world.find(state.locationId)?.name.toUpperCase();
    final cost = game.pendingCost;
    if (event.trigger == 'night') return 'NIGHT EVENT';
    if (event.trigger == 'encounter') return 'DANGER · ${place ?? 'THE TRAIL'}';
    if (state.locationId != 'camp' && place != null) {
      return '$place · $cost TIME';
    }
    final action = game.pendingAction;
    return action == null
        ? 'EVENT'
        : '${action.label.toUpperCase()} · $cost TIME';
  }

  @override
  Widget build(BuildContext context) {
    final event = game.pendingEvent!;
    final state = game.state;
    final encounter = event.trigger == 'encounter';
    final scene = switch (event.scene) {
      'forage' => 1,
      'fire' => 3,
      _ => 2,
    };
    return SceneLayout(
      state: state,
      background: _background(event, state),
      cardCarousel: true,
      backgroundAlignment: state.locationId == 'riverbank'
          ? const Alignment(-.2, -.15)
          : const Alignment(0, .1),
      dark: state.phase == RunPhase.night || event.trigger == 'encounter',
      panel: SituationPanel(
        eyebrow: _eyebrow(event, state),
        title: event.title,
        description: event.description,
        collapsedDescription: encounter,
        heroImage: event.heroImage,
        sceneArt: scene,
      ),
      cards: [
        for (final choice in game.visibleChoices) _choiceCard(context, choice),
      ],
    );
  }

  // Keep the visible heading brief; the tooltip retains the full action.
  // These are wording changes only and never depend on a hidden outcome.
  static const _shortTitles = {
    'Pick the familiar berries': 'Pick berries',
    'Dig roots and herbs': 'Dig roots & herbs',
    'Collect and boil water': 'Boil water',
    'Search the riverbank': 'Search bank',
    'Cut riverside herbs': 'Cut herbs',
    'Crack the coconuts': 'Crack coconuts',
    'Bundle the branches': 'Bundle wood',
    'Chop the fallen tree': 'Chop tree',
    'Search the open pocket': 'Search pocket',
    'Climb for the whole bag': 'Climb for bag',
    'Take the long way around': 'Go around',
    'Salvage the loose ropes': 'Salvage ropes',
    'Bring water back to boil': 'Boil water',
    'Drink from the rock': 'Drink water',
    'Return to the clearing': 'Return to camp',
    'Rekindle with your torch': 'Rekindle torch',
    'Steady your breathing': 'Breathe slowly',
    'Stay perfectly still': 'Stay still',
    'Hold up your torch': 'Raise torch',
    'Look beyond the firelight': 'Check shadows',
    'Tie down fresh leaves': 'Repair shelter',
    'Gather fishing supplies': 'Gather supplies',
    'Collect branches, vines and bait': 'Gather supplies',
    'Gather coconuts and water': 'Collect supplies',
    'Back away slowly': 'Back away',
    'Stand perfectly still': 'Stand still',
    'Scramble up a branch': 'Climb branch',
    'Take what has fallen': 'Gather fallen wood',
    'Cut herbs and roots': 'Cut herbs & roots',
    'Rest in the quiet': 'Rest quietly',
    'Catch fish by hand': 'Catch by hand',
    'Collect smooth stones': 'Gather stones',
  };

  Widget _choiceCard(BuildContext context, EventChoice choice) {
    final usable = game.canChoose(choice);
    final requirements = <String>[
      for (final id in choice.requiresTools)
        'Needs ${game.recipes.find(id)?.name ?? itemName(id)}',
      for (final r in choice.requires.entries)
        'Needs ${r.value} ${itemName(r.key).toLowerCase()}',
      for (final r in choice.requiresStats.entries)
        'Needs ${r.key.label} ${r.value}+',
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final baseHeight = 152.0 + (textScale > 1 ? (textScale - 1) * 94 : 0);
    final requiredHeight =
        CardCarousel.cardWidthFor(context) /
            ActionCard.illustrationAspectRatio +
        60 * textScale +
        12;
    final height = baseHeight > requiredHeight ? baseHeight : requiredHeight;
    return Tooltip(
      message: [choice.label, ...requirements].join('. '),
      child: ActionCard(
        key: ValueKey('choice-${choice.id}'),
        title: _shortTitles[choice.label] ?? choice.label,
        compact: true,
        fixedHeight: height,
        titleMaxLines: 2,
        descriptionMaxLines: 2,
        description: requirements.isEmpty ? null : requirements.join(' · '),
        showStatus: false,
        icon: choiceIcon(choice),
        art: choice.requiresTools.isNotEmpty
            ? choice.requiresTools.first
            : choice.requires.isNotEmpty
            ? choice.requires.keys.first
            : switch (choice.icon) {
                'retreat' => 'back',
                'fire' => 'firewood',
                'spear' => 'stone_spear',
                'torch' => 'torch',
                'wood' => 'wood',
                'stone' => 'stone',
                'water' => 'water',
                'food' => 'forage',
                'herb' => 'herb',
                'fiber' => 'fiber',
                'bait' => 'bait',
                'health' => 'health',
                'sanity' => 'sanity',
                _ => null,
              },
        image: choice.cardImage,
        tone: !usable
            ? CardTone.sand
            : choice.icon == 'retreat'
            ? CardTone.river
            : CardTone.leaf,
        onTap: usable ? () => Navigator.pop(context, choice.id) : null,
      ),
    );
  }
}
