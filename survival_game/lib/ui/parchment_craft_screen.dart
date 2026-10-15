import '../game/tool_catalog.dart';
import 'tool_art.dart';
import 'tool_panels.dart';
import '../game/run_state.dart';
import 'package:flutter/material.dart';
import '../game/crafting.dart';
import '../game/game_engine.dart';
import '../game/world_catalog.dart';
import 'card_art.dart';
import 'ecology_art.dart';
import 'fishing_art.dart';
import 'card_illustration.dart';
import 'parchment_components.dart';

/// First parchment screen. Confirmation returns the recipe to the camp,
/// which still owns crafting, autosave and outcome presentation.
class ParchmentCraftScreen extends StatefulWidget {
  const ParchmentCraftScreen({
    super.key,
    required this.game,
    required this.onCamp,
    required this.onCraft,
    this.showCamp = false,
  });
  final GameEngine game;
  final VoidCallback onCamp, onCraft;
  final bool showCamp;
  @override
  State<ParchmentCraftScreen> createState() => _ParchmentCraftScreenState();
}

class _ParchmentCraftScreenState extends State<ParchmentCraftScreen> {
  String? selected;
  String filter = 'ALL';
  bool owned(Recipe r) =>
      r.isOwnedBy(widget.game.state) && !widget.game.canRepairTool(r.id);
  String status(Recipe r) => owned(r)
      ? 'OWNED'
      : widget.game.craftBlockReason(r.id) != null
      ? 'LOCKED'
      : widget.game.canRepairTool(r.id)
      ? 'REPAIR'
      : 'READY';

  Future<void> details(Recipe recipe) async {
    setState(() => selected = recipe.id);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8507130F),
      builder: (context) => _CraftDetails(game: widget.game, recipe: recipe),
    );
    if (!mounted) return;
    if (confirmed == true &&
        !owned(recipe) &&
        widget.game.craftBlockReason(recipe.id) == null) {
      Navigator.pop(context, recipe.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipes = widget.showCamp
        ? widget.game.recipes.campTiers
        : widget.game.recipes.crafts
              .where(
                (r) =>
                    filter == 'ALL' ||
                    fieldTools[r.id]?.family ==
                        (filter == 'AXES' ? 'axe' : 'spear'),
              )
              .toList();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.showCamp
                ? 'assets/art/camp_tier_${widget.game.state.campTier}_empty_v1.jpg'
                : 'assets/art/workshop_camp_style_v1.png',
            fit: BoxFit.fitWidth,
          ),
          const ColoredBox(color: Color(0x800B2019)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: PaperSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                          child: Row(
                            children: [
                              CardArt(
                                widget.showCamp ? 'shelter' : 'craft',
                                size: 36,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ParchmentLabel(
                                      'WORKSHOP',
                                      size: 11,
                                      color: ParchmentColors.muted,
                                    ),
                                    ParchmentLabel(
                                      widget.showCamp
                                          ? 'CAMP UPGRADES'
                                          : 'CRAFT',
                                      size: 25,
                                    ),
                                  ],
                                ),
                              ),
                              ParchmentClose(
                                key: const ValueKey('craft-back'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: parchmentButton(
                                  'CRAFT',
                                  widget.onCraft,
                                  secondary: widget.showCamp,
                                  key: const ValueKey('tab-craft'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: parchmentButton(
                                  'CAMP',
                                  widget.onCamp,
                                  secondary: !widget.showCamp,
                                  key: const ValueKey('tab-camp'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ParchmentColors.leaf.withValues(
                                alpha: .07,
                              ),
                              border: Border.all(
                                color: const Color(0xFFB7A981),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                for (final id in ['wood', 'stone', 'fiber'])
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CardArt(id, size: 23),
                                      const SizedBox(width: 5),
                                      ParchmentLabel(
                                        '${widget.game.state.resource(id)}',
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      color: ParchmentColors.ink,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 5),
                                    ParchmentLabel(
                                      '${widget.game.state.timeLeft} time',
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!widget.showCamp)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              children: [
                                for (final value in [
                                  'ALL',
                                  'AXES',
                                  'SPEARS',
                                ]) ...[
                                  if (value != 'ALL') const SizedBox(width: 8),
                                  Expanded(
                                    child: parchmentButton(
                                      value,
                                      () => setState(() => filter = value),
                                      secondary: filter != value,
                                      key: ValueKey('tools-filter-$value'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                            child: Column(
                              children: [
                                ParchmentCardGrid(
                                  children: [
                                    for (final r in recipes)
                                      ParchmentCard(
                                        key: ValueKey('recipe-${r.id}'),
                                        title: r.name,
                                        art: r.id,
                                        info: '${r.timeCost} time · Details',
                                        status: status(r),
                                        selected: selected == r.id,
                                        onTap: () => details(r),
                                      ),
                                  ],
                                ),
                                if (widget.showCamp) ...[
                                  const SizedBox(height: 20),
                                  ParchmentLabel(
                                    'CURRENT CAMP · TIER ${widget.game.state.campTier}',
                                    size: 11,
                                    color: ParchmentColors.muted,
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 1.35,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.asset(
                                          'assets/art/camp_tier_${widget.game.state.campTier}_empty_v1.jpg',
                                          fit: BoxFit.cover,
                                          alignment: const Alignment(0, .15),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
                          child: ParchmentLabel(
                            'Tap a card to view costs and confirm.',
                            size: 12,
                            color: ParchmentColors.muted,
                            align: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CraftDetails extends StatelessWidget {
  const _CraftDetails({required this.game, required this.recipe});
  final GameEngine game;
  final Recipe recipe;
  @override
  Widget build(BuildContext context) {
    final owned =
        recipe.isOwnedBy(game.state) && !game.canRepairTool(recipe.id);
    final block = game.craftBlockReason(recipe.id);
    final ready = !owned && block == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        10,
        10,
        10,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
          maxWidth: 560,
        ),
        child: PaperSurface(
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                  child: Row(
                    children: [
                      if (fieldTools.containsKey(recipe.id))
                        SizedBox(
                          width: 64,
                          height: 48,
                          child: ToolArt(recipe.id, icon: true),
                        )
                      else if (hasFishingArt(recipe.id))
                        SizedBox(
                          width: 64,
                          height: 48,
                          child: FishingArt(recipe.id),
                        )
                      else if (hasEcologyArt(recipe.id))
                        SizedBox(
                          width: 64,
                          height: 48,
                          child: EcologyArt(recipe.id),
                        )
                      else
                        Image.asset(
                          cardIllustrationFor(recipe.id) ??
                              'assets/art/card_trail_scene_v1.png',
                          width: 64,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ParchmentLabel(
                          recipe.name.toUpperCase(),
                          size: 19,
                        ),
                      ),
                      ParchmentClose(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (fieldTools.containsKey(recipe.id)) ...[
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: AspectRatio(
                                aspectRatio: 1.5,
                                child: ToolArt(recipe.id),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FieldToolSummary(
                            game: game,
                            id: recipe.id,
                            crafting: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!fieldTools.containsKey(recipe.id))
                          ParchmentLabel(
                            recipe.description,
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                        const SizedBox(height: 8),
                        if (!fieldTools.containsKey(recipe.id))
                          ParchmentLabel(
                            recipe.effect,
                            size: 13,
                            color: ParchmentColors.muted,
                            weight: FontWeight.w500,
                          ),
                        const SizedBox(height: 18),
                        const ParchmentLabel(
                          'COST · NEEDED / AVAILABLE',
                          size: 11,
                          color: ParchmentColors.muted,
                        ),
                        const SizedBox(height: 8),
                        for (final cost in game.craftCosts(recipe.id).entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                CardArt(cost.key, size: 27),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: ParchmentLabel(
                                    itemName(cost.key),
                                    size: 14,
                                  ),
                                ),
                                ParchmentLabel(
                                  '${cost.value} / ${game.state.resource(cost.key)}',
                                  size: 14,
                                  color:
                                      game.state.resource(cost.key) >=
                                          cost.value
                                      ? ParchmentColors.leaf
                                      : ParchmentColors.rust,
                                ),
                              ],
                            ),
                          ),
                        if (recipe.waterCost > 0)
                          ParchmentLabel(
                            'Water ${game.state.value(SurvivalStat.water)} / ${recipe.waterCost} · recipe ingredient',
                            size: 14,
                          ),
                        const Divider(color: Color(0xFFB7A981)),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: ParchmentColors.ink,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            ParchmentLabel('${recipe.timeCost} time', size: 14),
                          ],
                        ),
                        if (recipe.minCampTier > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ParchmentLabel(
                              'Camp tier ${recipe.minCampTier} required',
                              size: 13,
                              color: ParchmentColors.muted,
                            ),
                          ),
                        if (recipe.requiresItems.isNotEmpty &&
                            !game.canRepairTool(recipe.id))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ParchmentLabel(
                              'Requires: ${recipe.requiresItems.map(itemName).join(', ')}',
                              size: 13,
                              color: ParchmentColors.muted,
                            ),
                          ),
                        if (block != null && !owned)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ParchmentLabel(
                              block,
                              size: 13,
                              color: ParchmentColors.rust,
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: parchmentButton(
                    owned
                        ? 'ALREADY OWNED'
                        : ready
                        ? game.canRepairTool(recipe.id)
                              ? 'REPAIR · ${recipe.timeCost} TIME'
                              : '${recipe.tier != null ? 'BUILD' : 'CRAFT'} · ${recipe.timeCost} TIME'
                        : 'UNAVAILABLE',
                    ready ? () => Navigator.pop(context, true) : null,
                    key: ValueKey('craft-${recipe.id}'),
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
