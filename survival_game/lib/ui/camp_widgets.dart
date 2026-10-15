import 'package:flutter/material.dart';

import '../game/run_state.dart';
import 'canopy_theme.dart';
import 'action_card.dart';
import 'card_art.dart';
import 'parchment_components.dart';

/// The original generated atlas is preserved; cells are selected at render time.
class CanopyArt extends StatelessWidget {
  const CanopyArt(this.cell, {super.key, this.size = 80});
  final int cell;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ][cell],
          maxWidth: size * 2,
          maxHeight: size * 2,
          child: Image.asset(
            'assets/art/ui_atlas.png',
            width: size * 2,
            height: size * 2,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    ),
  );
}

/// 4 by 3 transparent atlas, with padding in every cell to prevent bleeding.
class HudArt extends StatelessWidget {
  const HudArt(this.cell, {super.key, this.size = 24});
  final int cell;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(-1 + (cell % 4) * 2 / 3, -1.0 + (cell ~/ 4)),
          maxWidth: size * 4,
          maxHeight: size * 3,
          child: Image.asset(
            'assets/art/hud_atlas.png',
            width: size * 4,
            height: size * 3,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    ),
  );
}

class CampPanel extends StatelessWidget {
  const CampPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = CanopyColors.panel,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => PaperSurface(
    child: Padding(padding: padding, child: child),
  );
}

const statColors = {
  SurvivalStat.health: CanopyColors.health,
  SurvivalStat.water: CanopyColors.water,
  SurvivalStat.food: CanopyColors.food,
  SurvivalStat.sanity: CanopyColors.sanity,
};
const statIcons = {
  SurvivalStat.health: Icons.favorite_rounded,
  SurvivalStat.water: Icons.water_drop_rounded,
  SurvivalStat.food: Icons.restaurant_rounded,
  SurvivalStat.sanity: Icons.psychology_rounded,
};

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.stat, required this.value});
  final SurvivalStat stat;
  final int value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: stat.label,
    value: '$value out of 100',
    child: ExcludeSemantics(
      child: Tooltip(
        message: '${stat.label}: $value/100',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/art/ui_stat_${stat.name}.png',
              width: 43,
              height: 43,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: const Color(0xDBEEE1BA),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: CanopyColors.cream,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 32,
              child: LinearProgressIndicator(
                value: value / 100,
                color: statColors[stat],
                backgroundColor: CanopyColors.border,
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ResourceStrip extends StatelessWidget {
  const ResourceStrip({super.key, required this.state});
  final RunState state;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: CampPanel(
      padding: const EdgeInsets.all(4),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 4,
        children: [
          for (final id in ['wood', 'stone', 'fiber'])
            Semantics(
              label: '$id: ${state.availableResource(id)}',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CardArt(id, size: 19),
                  const SizedBox(width: 4),
                  Text(
                    '${state.availableResource(id)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class CampActionCard extends StatelessWidget {
  const CampActionCard({
    super.key,
    required this.action,
    required this.onPressed,
    this.sleep = false,
    this.horizontal = false,
  });
  final CampAction action;
  final VoidCallback? onPressed;
  final bool sleep, horizontal;
  @override
  Widget build(BuildContext context) => ActionCard(
    title: sleep ? 'Sleep' : action.label,
    art: switch (action) {
      CampAction.forage => 'forage',
      CampAction.explore => 'map',
      CampAction.rest => 'shelter',
    },
    tone: switch (action) {
      CampAction.forage => CardTone.leaf,
      CampAction.explore => CardTone.river,
      CampAction.rest => CardTone.sand,
    },
    lines: [
      CardLine(
        sleep ? 'End night' : '${action.cost} time',
        icon: Icons.schedule_rounded,
        color: CanopyColors.cream,
      ),
    ],
    tag: sleep
        ? 'RECOVERY'
        : action == CampAction.explore
        ? 'TRAVEL'
        : 'SURVIVAL',
    compact: true,
    horizontal: horizontal,
    onTap: onPressed,
  );
}

/// All camps share five separate poses on the supplied empty backgrounds.
const campActivities = ['fire', 'wood', 'craft', 'seated', 'inspect'];
const starterCampActivities = campActivities;
const starterCampBackground = 'assets/art/camp_tier_0_empty_v1.jpg';
const campNightTint = Color(0xFF4A5F8E);

String campArt(int tier, {int variant = 0}) =>
    'assets/art/camp_tier_${tier}_empty_v1.jpg';

/// Higher tiers have their hearth lower in the painting. Lift their art so
/// the foreground and character remain visible above the action cards.
Alignment campAlignment(int tier) => Alignment(0, tier >= 2 ? -.7 : .18);

/// Shared painted material and consumable illustrations.
class ResourceIcon extends StatelessWidget {
  const ResourceIcon(this.id, {super.key, this.size = 24});
  final String id;
  final double size;
  @override
  Widget build(BuildContext context) => CardArt(id, size: size);
}
