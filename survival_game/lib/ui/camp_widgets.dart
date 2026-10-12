import 'package:flutter/material.dart';

import '../game/run_state.dart';
import 'canopy_theme.dart';
import 'action_card.dart';
import 'card_art.dart';

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
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: .98),
          CanopyColors.background.withValues(alpha: .98),
        ],
      ),
      border: Border.all(
        color: CanopyColors.border.withValues(alpha: .65),
        width: 1.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          offset: Offset(0, 4),
          blurRadius: 8,
        ),
      ],
    ),
    child: child,
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
  Widget build(BuildContext context) {
    final color = statColors[stat]!;
    return Semantics(
      label: stat.label,
      value: '$value out of 100',
      child: ExcludeSemantics(
        child: Tooltip(
          message: '${stat.label}: $value/100',
          child: CampPanel(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HudArt(stat.index, size: 18),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: value <= 20
                              ? CanopyColors.health
                              : CanopyColors.cream,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FractionallySizedBox(
                  widthFactor: .8,
                  alignment: Alignment.centerRight,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: value / 100),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    builder: (context, amount, _) => LinearProgressIndicator(
                      value: amount,
                      color: color,
                      backgroundColor: Colors.black26,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResourceStrip extends StatelessWidget {
  const ResourceStrip({super.key, required this.state});
  final RunState state;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 4,
    runSpacing: 4,
    children: [
      for (final entry in {'wood': 4, 'stone': 5, 'fiber': 6}.entries)
        Tooltip(
          message: '${entry.key}: ${state.resource(entry.key)}',
          child: Semantics(
            label: '${entry.key}: ${state.resource(entry.key)}',
            child: ExcludeSemantics(
              child: CampPanel(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HudArt(entry.value, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${state.resource(entry.key)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
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

/// Background art for each camp tier; tier 0 is the accepted starter master.
String campArt(int tier) => tier == 0
    ? 'assets/art/starter_camp.png'
    : 'assets/art/camp_tier_$tier.png';

/// Shared painted material and consumable illustrations.
class ResourceIcon extends StatelessWidget {
  const ResourceIcon(this.id, {super.key, this.size = 24});
  final String id;
  final double size;
  @override
  Widget build(BuildContext context) => CardArt(id, size: size);
}
