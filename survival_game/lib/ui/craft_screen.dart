import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/crafting.dart';
import '../game/game_engine.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';
import 'card_art.dart';

const recipeIcons = {
  'basic_rod': Icons.phishing_rounded,
  'stone_knife': Icons.content_cut_rounded,
  'stone_axe': Icons.carpenter_rounded,
  'torch': Icons.local_fire_department_rounded,
  'stone_spear': Icons.call_made_rounded,
  'leaf_bed': Icons.bed_rounded,
  'water_filter': Icons.filter_alt_rounded,
  'rain_collector': Icons.umbrella_rounded,
  'drying_rack': Icons.set_meal_rounded,
};

/// Selection only: the camp retains ownership of crafting transactions.
class CraftScreen extends StatefulWidget {
  const CraftScreen({super.key, required this.game, this.showCamp = false});
  final GameEngine game;
  final bool showCamp;
  @override
  State<CraftScreen> createState() => _CraftScreenState();
}

class _CraftScreenState extends State<CraftScreen> {
  late bool _camp = widget.showCamp;
  String? _selected;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GameEngine get game => widget.game;
  List<Recipe> get _recipes =>
      _camp ? game.recipes.campTiers : game.recipes.crafts.toList();

  Recipe _current() {
    final list = _recipes;
    for (final recipe in list) {
      if (recipe.id == _selected) return recipe;
    }
    for (final recipe in list) {
      if (!recipe.isOwnedBy(game.state) &&
          game.craftBlockReason(recipe.id) == null) {
        return recipe;
      }
    }
    return list.firstWhere(
      (recipe) => !recipe.isOwnedBy(game.state),
      orElse: () => list.first,
    );
  }

  Widget _tab(bool camp) => Expanded(
    child: Semantics(
      selected: _camp == camp,
      child: OutlinedButton(
        key: ValueKey(camp ? 'tab-camp' : 'tab-craft'),
        onPressed: () => setState(() {
          _camp = camp;
          _selected = null;
          if (_scroll.hasClients) _scroll.jumpTo(0);
        }),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: _camp == camp
              ? CanopyColors.workshop
              : CanopyColors.panel,
          side: BorderSide(
            color: _camp == camp ? CanopyColors.gold : CanopyColors.border,
            width: 2,
          ),
          padding: const EdgeInsets.all(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CardArt(camp ? 'shelter' : 'craft', size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                camp ? 'CAMP' : 'CRAFT',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final current = _current();
    final large =
        MediaQuery.textScalerOf(context).scale(14) > 19 ||
        MediaQuery.sizeOf(context).width < 360;
    final owned = current.isOwnedBy(game.state);
    final block = game.craftBlockReason(current.id);
    final costs = current.costs.entries
        .map((cost) => '${cost.value} ${itemName(cost.key).toLowerCase()}')
        .join(' · ');
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          CanopyHud(state: game.state),
          const SizedBox(height: 10),
          Row(children: [_tab(false), const SizedBox(width: 8), _tab(true)]),
        ],
      ),
    );
    final content = <Widget>[
      _RecipeDetail(game: game, recipe: current),
      const SizedBox(height: 8),
      _RecipeStrip(
        game: game,
        recipes: _recipes,
        selected: current.id,
        onSelect: (id) => setState(() => _selected = id),
      ),
      const SizedBox(height: 220),
      if (_camp)
        Align(
          alignment: Alignment.centerRight,
          child: CampPanel(
            padding: const EdgeInsets.all(8),
            child: Text(
              'PREVIEW · ${current.name}\nCurrent: ${campTierName(game.recipes, game.state.campTier)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: CanopyColors.gold),
            ),
          ),
        ),
      const SizedBox(height: 8),
    ];
    final footer = Padding(
      padding: const EdgeInsets.all(12),
      child: CardDeck(
        cards: [
          ActionCard(
            key: ValueKey('craft-${current.id}'),
            title: _camp ? 'Build ${current.name}' : 'Craft',
            art: _camp ? 'shelter' : 'craft',
            tone: CardTone.leaf,
            compact: true,
            horizontal: large,
            description: owned ? 'Already yours' : block,
            lines: owned
                ? const []
                : [
                    CardLine(costs, color: CanopyColors.cream),
                    CardLine(
                      '${current.timeCost} time',
                      icon: Icons.schedule_rounded,
                    ),
                  ],
            tag: owned
                ? 'OWNED'
                : block == null
                ? 'READY'
                : 'LOCKED',
            onTap: !owned && block == null
                ? () => Navigator.pop(context, current.id)
                : null,
          ),
          ActionCard(
            key: const ValueKey('craft-back'),
            title: 'Back',
            art: 'back',
            tone: CardTone.river,
            compact: true,
            horizontal: large,
            description: 'Return to camp',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    return Scaffold(
      body: CanopyBackdrop(
        background: _camp
            ? campArt(current.tier!)
            : 'assets/art/workshop_scene.png',
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(
                builder: (context, viewport) {
                  if (large || viewport.maxHeight < 700) {
                    return SingleChildScrollView(
                      controller: _scroll,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: content,
                            ),
                          ),
                          footer,
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      Expanded(
                        child: ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: content,
                        ),
                      ),
                      footer,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeDetail extends StatelessWidget {
  const _RecipeDetail({required this.game, required this.recipe});
  final GameEngine game;
  final Recipe recipe;
  @override
  Widget build(BuildContext context) {
    final owned = recipe.isOwnedBy(game.state);
    final block = game.craftBlockReason(recipe.id);
    final tier = recipe.kind == RecipeKind.campTier;
    return CampPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 66,
                height: 66,
                child: tier
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          campArt(recipe.tier!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : CardArt(recipe.id, size: 66),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.effect,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                    if (owned)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'OWNED',
                          style: TextStyle(
                            color: CanopyColors.leaf,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!owned) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cost in recipe.costs.entries)
                  Semantics(
                    label:
                        '${itemName(cost.key)}: ${game.state.resource(cost.key)} of ${cost.value} needed',
                    child: CampPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ResourceIcon(cost.key, size: 22),
                          const SizedBox(width: 5),
                          Text(
                            '${game.state.resource(cost.key)}/${cost.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color: game.state.resource(cost.key) >= cost.value
                                  ? CanopyColors.leaf
                                  : CanopyColors.food,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                CampPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  child: Text(
                    '${recipe.timeCost} time',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CanopyColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            if (block != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  block,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CanopyColors.food,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecipeStrip extends StatelessWidget {
  const _RecipeStrip({
    required this.game,
    required this.recipes,
    required this.selected,
    required this.onSelect,
  });
  final GameEngine game;
  final List<Recipe> recipes;
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 19;
      final width = large
          ? math.min(280.0, constraints.maxWidth)
          : (constraints.maxWidth - 16) / 3;
      // Natural card height avoids clipping labels at larger accessibility sizes.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < recipes.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                SizedBox(width: width, child: _tile(recipes[i], large)),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _tile(Recipe recipe, bool large) {
    final owned = recipe.isOwnedBy(game.state);
    final block = game.craftBlockReason(recipe.id);
    return ActionCard(
      key: ValueKey('recipe-${recipe.id}'),
      title: recipe.name,
      art: recipe.id,
      compact: true,
      horizontal: large,
      tone: CardTone.sand,
      selected: recipe.id == selected,
      locked: !owned && block != null,
      tag: owned
          ? 'OWNED'
          : block == null
          ? 'READY'
          : 'LOCKED',
      onTap: () => onSelect(recipe.id),
    );
  }
}
