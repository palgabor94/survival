import 'package:flutter/material.dart';

import '../game/event_catalog.dart';
import '../game/run_state.dart';

const _icons = {
  'torch': Icons.local_fire_department_rounded,
  'spear': Icons.arrow_upward_rounded,
  'retreat': Icons.directions_run_rounded,
  'search': Icons.search_rounded,
  'climb': Icons.terrain_rounded,
  'cross': Icons.swap_horiz_rounded,
  'herb': Icons.spa_rounded,
  'calm': Icons.self_improvement_rounded,
  'water': Icons.water_drop_rounded,
  'food': Icons.restaurant_rounded,
  'health': Icons.favorite_rounded,
  'sanity': Icons.psychology_rounded,
  'wood': Icons.forest_rounded,
  'fiber': Icons.grass_rounded,
  'stone': Icons.landscape_rounded,
  'bait': Icons.pest_control_rounded,
  'fire': Icons.fireplace_rounded,
};

/// Choose artwork from the action, never from its hidden reward or outcome.
IconData choiceIcon(EventChoice choice) {
  final key = choice.icon;
  if (key != null && _icons.containsKey(key)) return _icons[key]!;
  final label = choice.label.toLowerCase();
  if (label.contains('berries') ||
      label.contains('fruit') ||
      label.contains('eat')) {
    return Icons.restaurant_rounded;
  }
  if (label.contains('water') || label.contains('flask')) {
    return Icons.water_drop_rounded;
  }
  if (label.contains('herb') || label.contains('roots')) {
    return Icons.spa_rounded;
  }
  if (label.contains('fire') || label.contains('torch')) {
    return Icons.local_fire_department_rounded;
  }
  if (label.contains('wood') || label.contains('branches')) {
    return Icons.forest_rounded;
  }
  if (label.contains('breathe') ||
      label.contains('still') ||
      label.contains('calm')) {
    return Icons.self_improvement_rounded;
  }
  if (label.contains('return') ||
      label.contains('leave') ||
      label.contains('away')) {
    return Icons.directions_run_rounded;
  }
  if (label.contains('search') ||
      label.contains('look') ||
      label.contains('gather')) {
    return Icons.search_rounded;
  }
  return Icons.arrow_forward_rounded;
}

Color statColorFor(SurvivalStat stat) => switch (stat) {
  SurvivalStat.health => const Color(0xFFFF7862),
  SurvivalStat.water => const Color(0xFF62D8ED),
  SurvivalStat.food => const Color(0xFFF8B168),
  SurvivalStat.sanity => const Color(0xFFD2A2F2),
};
