import 'dart:math';
import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key, required this.game});
  final GameEngine game;
  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  String selectedId = 'riverbank';
  GameEngine get game => widget.game;
  @override
  Widget build(BuildContext context) {
    final selected = game.world.find(selectedId);
    return Scaffold(
      body: CanopyBackdrop(
        background: 'assets/art/explore_map.png',
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CanopyHud(state: game.state),
                        const SizedBox(height: 10),
                        const CampPanel(
                          padding: EdgeInsets.all(8),
                          child: CanopyTitle(
                            title: 'Explore',
                            art: 'map',
                            subtitle: 'Choose a destination',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (MediaQuery.textScalerOf(context).scale(14) > 19 ||
                            c.maxWidth < 360)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final location in game.world.locations)
                                SizedBox(
                                  width: (c.maxWidth - 32) / 2,
                                  child: _node(location),
                                ),
                            ],
                          )
                        else
                          SizedBox(
                            height: max(260, c.maxHeight - 520),
                            child: LayoutBuilder(
                              builder: (context, area) {
                                final width = area.maxWidth;
                                final left = (area.maxWidth - width) / 2;
                                return Stack(
                                  children: [
                                    for (final location in game.world.locations)
                                      Positioned(
                                        left:
                                            (left +
                                                    (location.id == 'riverbank'
                                                            ? .24
                                                            : location.x) *
                                                        width -
                                                    55)
                                                .clamp(
                                                  0,
                                                  max(0, area.maxWidth - 110),
                                                )
                                                .toDouble(),
                                        top:
                                            (((location.y - .25) / .65) *
                                                        area.maxHeight -
                                                    24)
                                                .clamp(
                                                  0,
                                                  max(0, area.maxHeight - 48),
                                                )
                                                .toDouble(),
                                        width: 110,
                                        child: _node(location),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (selected != null) _details(selected),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _node(WorldLocation location) {
    final unlocked = location.isUnlocked(game.state);
    final selected = selectedId == location.id;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        key: ValueKey('map-node-${location.id}'),
        onPressed: () => setState(() => selectedId = location.id),
        style: OutlinedButton.styleFrom(
          backgroundColor: CanopyColors.panel,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          minimumSize: const Size(48, 48),
          side: BorderSide(
            color: selected ? CanopyColors.water : CanopyColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              unlocked
                  ? (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked)
                  : Icons.lock_rounded,
              size: 14,
              color: selected ? CanopyColors.water : CanopyColors.muted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(WorldLocation location) {
    final block = game.travelBlockReason(location.id);
    final needsRod =
        location.id == 'fishing_pond' &&
        !game.state.tools.contains('basic_rod');
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampPanel(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CanopyTitle(
                title: location.name,
                art: location.id == 'fishing_pond' ? 'basic_rod' : 'map',
                subtitle: location.description,
              ),
              const SizedBox(height: 5),
              Text(
                location.loot,
                style: const TextStyle(fontSize: 12, color: CanopyColors.gold),
              ),
              if (block != null)
                Text(
                  block,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CanopyColors.food,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CardDeck(
          cards: [
            ActionCard(
              key: const ValueKey('travel-destination'),
              title: location.id == 'camp'
                  ? 'Back to camp'
                  : location.id == 'fishing_pond'
                  ? 'Go fishing'
                  : 'Travel',
              art: location.id == 'fishing_pond' ? 'basic_rod' : 'map',
              tone: CardTone.river,
              compact: true,
              horizontal: large,
              lines: [
                if (location.timeCost > 0)
                  CardLine(
                    '${location.timeCost} time · −${location.timeCost * 4} Water · −${location.timeCost * 3} Food',
                    color: CanopyColors.cream,
                  ),
              ],
              onTap: location.id == 'camp'
                  ? () => Navigator.pop(context)
                  : block == null
                  ? () => Navigator.pop(context, location.id)
                  : null,
            ),
            if (needsRod)
              ActionCard(
                title: 'Craft a Basic Rod',
                art: 'basic_rod',
                tone: CardTone.sand,
                compact: true,
                horizontal: large,
                onTap: () => Navigator.pop(context, 'workshop'),
              ),
            if (location.id != 'camp')
              ActionCard(
                title: 'Back',
                art: 'back',
                tone: CardTone.river,
                compact: true,
                horizontal: large,
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ],
    );
  }
}
