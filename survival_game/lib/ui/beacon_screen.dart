import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/rescue_progress.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'camp_character.dart';
import 'canopy_theme.dart';
import 'scene_layout.dart';

class BeaconScreen extends StatelessWidget {
  const BeaconScreen({super.key, required this.game, this.campVariant = 0});
  final GameEngine game;
  final int campVariant;

  @override
  Widget build(BuildContext context) {
    final assembled = game.state.tools.contains('emergency_beacon');
    final sent = game.state.rescueStage != RescueStage.searching;
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final block = assembled
        ? game.activateBeaconBlockReason
        : game.craftBlockReason('emergency_beacon');
    final shortBlock = assembled || block == null
        ? block
        : game.state.campTier < 3
        ? 'Needs Rescue Base'
        : game.heldBeaconComponents < 5
        ? 'Collect the missing parts'
        : game.state.resource('metal_scrap') < 2
        ? 'Needs 2 Metal Scrap'
        : block;
    return SceneLayout(
      state: game.state,
      background: campArt(game.state.campTier, variant: campVariant),
      backgroundAlignment: campAlignment(game.state.campTier),
      foregroundBuilder: (context, rect) => CampCharacter(
        artworkRect: rect,
        tier: game.state.campTier,
        variant: campVariant,
      ),
      panel: SituationPanel(
        eyebrow: 'RESCUE SIGNAL',
        title: sent
            ? 'Help is on the way'
            : assembled
            ? 'The beacon is ready'
            : 'Build a way home',
        description:
            'Recover four working parts at the Plane Wreck and the Beacon Core beneath the Ancient Ruins. Assemble them at the Rescue Base. After you send the signal, prepare supplies: tomorrow brings the final rescue storm.',
        collapsedDescription: true,
        note: sent
            ? 'Prepare supplies before you sleep. Rescue comes tomorrow.'
            : assembled
            ? 'Activation: 1 time · Final storm starts next dawn'
            : '${game.heldBeaconComponents}/5 components · ${game.state.campTier < 3 ? 'Rescue Base required' : 'Rescue Base ready'}',
        sceneArt: 2,
      ),
      beforeCards: CampPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in beaconComponents.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    ResourceIcon(entry.key, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            entry.key == 'beacon_core'
                                ? 'Ancient Ruins · stone seal'
                                : 'Plane Wreck',
                            style: const TextStyle(
                              fontSize: 10,
                              color: CanopyColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      assembled || game.state.resource(entry.key) > 0
                          ? '1/1'
                          : '0/1',
                      style: TextStyle(
                        color: assembled || game.state.resource(entry.key) > 0
                            ? CanopyColors.leaf
                            : CanopyColors.gold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      assembled || game.state.resource(entry.key) > 0
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: assembled || game.state.resource(entry.key) > 0
                          ? CanopyColors.leaf
                          : CanopyColors.muted,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                TextButton(
                  key: const ValueKey('beacon-map'),
                  onPressed: () => Navigator.pop(context, 'map'),
                  child: const Text('MAP'),
                ),
                TextButton(
                  key: const ValueKey('beacon-workshop'),
                  onPressed: () => Navigator.pop(context, 'workshop'),
                  child: const Text('WORKSHOP'),
                ),
              ],
            ),
          ],
        ),
      ),
      cards: [
        ActionCard(
          key: const ValueKey('beacon-primary'),
          title: sent
              ? 'Prepare supplies'
              : assembled
              ? 'Send the signal'
              : 'Assemble beacon',
          description: sent
              ? 'Food, water & shelter'
              : shortBlock ?? (assembled ? '1 time' : '2 time'),
          art: sent ? 'inventory' : 'emergency_beacon',
          compact: true,
          horizontal: large,
          onTap: sent || block == null
              ? () => Navigator.pop(
                  context,
                  sent
                      ? 'inventory'
                      : assembled
                      ? 'activate'
                      : 'assemble',
                )
              : null,
        ),
        ActionCard(
          key: const ValueKey('beacon-back'),
          title: 'Back to camp',
          art: 'back',
          tone: CardTone.river,
          compact: true,
          horizontal: large,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
