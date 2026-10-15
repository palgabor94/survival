import 'first_day_guide.dart';
import '../game/crafting.dart';
import '../game/inventory_catalog.dart';
import 'inventory_panels.dart';
import '../game/tool_catalog.dart';
import 'tool_art.dart';
import 'tool_panels.dart';
import '../game/ecology_catalog.dart';
import '../game/fishing_catalog.dart';
import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../game/run_state.dart';
import '../game/world_catalog.dart';
import 'card_art.dart';
import 'canopy_components.dart';
import 'fishing_art.dart';
import 'fishing_panels.dart';
import 'parchment_components.dart';

class InventoryDialog extends StatefulWidget {
  const InventoryDialog({super.key, required this.game});
  final GameEngine game;
  @override
  State<InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends State<InventoryDialog> {
  late int tab = widget.game.state.inField ? 1 : 0;
  String? selected;
  GameEngine get game => widget.game;
  Future<void> details(String id) async {
    setState(() => selected = id);
    final command = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8507130F),
      builder: (context) => _ItemDetails(game: game, id: id),
    );
    if (!mounted || command == null) return;
    if (command.startsWith('prepare-fish:') ||
        command.startsWith('equip-rod:') ||
        command.startsWith('equip-tool:') ||
        command.startsWith('repair-tool:') ||
        command.startsWith('study:') ||
        command == 'dry' ||
        command == 'roots' ||
        command == 'chew' ||
        command == 'workshop' ||
        command == 'map' ||
        (command == 'consume:$id' && game.canConsume(id))) {
      Navigator.pop(context, command);
    }
  }

  Future<void> dryDetails() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CanopyDialog(
        title: 'Dry by the fire',
        art: 'firewood',
        subtitle: 'RECOVERY',
        actions: [
          parchmentButton(
            'DRY CLOTHES · 1 TIME',
            () => Navigator.pop(context, true),
            key: const ValueKey('confirm-dry-fire'),
          ),
        ],
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ParchmentLabel(
              'Use 1 wood and 1 daylight at camp. Wet is removed before time passes. Other active conditions still take their normal time cost.',
              size: 14,
              weight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
    if (mounted && confirmed == true) Navigator.pop(context, 'dry');
  }

  @override
  Widget build(BuildContext context) {
    final tools = game.recipes.crafts
        .where(
          (r) =>
              r.isOwnedBy(game.state) &&
              (r.kind == RecipeKind.tool || r.id == 'leaf_rain_cape') &&
              (!game.state.inField || game.state.availableTools.contains(r.id)),
        )
        .toList();
    final source = tab == 1
        ? game.state.packResources
        : game.state.storedResources;
    final items = tab == 2
        ? tools.map((r) => r.id).toList()
        : source.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    return Dialog(
      shape: const RoundedRectangleBorder(),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 390,
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: PaperSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FirstDayCoach(game: game, place: 'items'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                child: Row(
                  children: [
                    const CardArt('inventory', size: 36),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ParchmentLabel(
                            'CAMP INVENTORY',
                            size: 11,
                            color: ParchmentColors.muted,
                          ),
                          ParchmentLabel('ITEMS', size: 25),
                        ],
                      ),
                    ),
                    ParchmentClose(
                      key: const ValueKey('close-dialog'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: parchmentButton(
                          ['STORAGE', 'BACKPACK', 'GEAR'][i],
                          game.state.inField && i == 0
                              ? null
                              : () => setState(() {
                                  tab = i;
                                  selected = null;
                                }),
                          secondary: tab != i,
                          key: ValueKey('inventory-tab-$i'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('dialog-content-scroll'),
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: ParchmentLabel(
                          'Tap an item to view details.',
                          size: 12,
                          color: ParchmentColors.muted,
                          align: TextAlign.center,
                        ),
                      ),
                      if (tab == 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: PackCapacity(
                            used: game.state.usedPackSlots,
                            maximum: game.state.packCapacity,
                          ),
                        ),
                      if (tab == 0)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: ParchmentLabel(
                            'Safe at camp · unlimited storage',
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        ),
                      if (game.state.hasCondition(ConditionKind.wet))
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: parchmentButton(
                            'DRY BY FIRE · 1 WOOD · 1 TIME',
                            game.canAct(CampAction.rest) &&
                                    game.state.availableResource('wood') > 0
                                ? dryDetails
                                : null,
                            secondary: true,
                          ),
                        ),

                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: ParchmentLabel(
                            tab == 2
                                ? 'Nothing equipped yet.'
                                : 'No items here yet.',
                            size: 13,
                          ),
                        )
                      else
                        ParchmentCardGrid(
                          children: [
                            for (final id in items)
                              ParchmentCard(
                                key: ValueKey('inventory-$id'),
                                title:
                                    game.recipes.find(id)?.name ??
                                    inventoryCardName(id),
                                art: id,
                                info: tab == 2
                                    ? 'View equipment'
                                    : tab == 1
                                    ? '${source[id] ?? 0} carried · ${inventorySlotsLabel(packSlots({id: source[id] ?? 0}))}'
                                    : '${source[id] ?? 0} stored',
                                status: tab == 2
                                    ? (fieldTools.containsKey(id) &&
                                              game.state.activeFieldTool(
                                                    fieldTools[id]!.family,
                                                  ) ==
                                                  id
                                          ? 'EQUIPPED'
                                          : 'OWNED')
                                    : '${source[id] ?? 0}',
                                selected: selected == id,
                                onTap: () => details(id),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: parchmentButton(
                  tab == 1 && !game.state.inField
                      ? 'PREPARE PACK'
                      : 'OPEN WORKSHOP',
                  game.state.inField
                      ? null
                      : () => Navigator.pop(
                          context,
                          tab == 1 ? 'map' : 'workshop',
                        ),
                  secondary: true,
                  key: const ValueKey('open-workshop'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.game, required this.id});
  final GameEngine game;
  final String id;
  @override
  Widget build(BuildContext context) {
    final recipe = game.recipes.find(id);
    final fish = fishSpecies[id];
    final consumable = GameEngine.consumables.contains(id);
    final effect = consumable
        ? (game.consumeEffect(id).summary.split(' · ')
                ..removeWhere((part) => part.contains(id)))
              .join(' · ')
        : null;
    final canUse = consumable && game.canConsume(id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
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
                      CardArt(id, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ParchmentLabel(
                          (recipe?.name ?? itemName(id)).toUpperCase(),
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
                        if (fieldTools.containsKey(id)) ...[
                          AspectRatio(aspectRatio: 1.5, child: ToolArt(id)),
                          const SizedBox(height: 12),
                          FieldToolSummary(game: game, id: id),
                          const SizedBox(height: 12),
                        ],
                        if (fish != null || preparedFishSource(id) != null) ...[
                          AspectRatio(aspectRatio: 1.5, child: FishingArt(id)),
                          const SizedBox(height: 12),
                        ],
                        if (recipe != null) ...[
                          ParchmentLabel(
                            recipe.description,
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                          const SizedBox(height: 8),
                          ParchmentLabel(
                            recipe.effect,
                            size: 13,
                            color: ParchmentColors.muted,
                            weight: FontWeight.w500,
                          ),
                        ],
                        if (recipe != null &&
                            RunState.toolDurability.containsKey(id))
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: ParchmentLabel(
                              'Condition ${game.state.toolCondition(id)}/${RunState.toolDurability[id]}',
                              size: 14,
                            ),
                          ),
                        if (recipe == null) ...[
                          ParchmentLabel(
                            'IN STOCK · ${game.state.availableResource(id)}',
                            size: 14,
                          ),
                          const SizedBox(height: 14),
                          ParchmentLabel(
                            fish != null
                                ? fish.handling
                                : preparedFishSource(id) != null
                                ? 'Safely prepared fish. Ready to eat at camp or a calm expedition stop.'
                                : jungleFoods.containsKey(id)
                                ? (game.state.knownSpecies.contains(id)
                                      ? jungleFoods[id]!.description
                                      : 'Unstudied species. Its properties are consistent, but you have not identified it yet.')
                                : consumable
                                ? (id == 'antidote'
                                      ? 'Clears poison. Does not restore lost health.'
                                      : id == 'bandage'
                                      ? 'Clears injury, then restores a little health.'
                                      : effect!)
                                : _description(id),
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                        ],
                        if (consumable) ...[
                          const SizedBox(height: 14),
                          const ParchmentLabel(
                            'Consumes 1 · No daylight cost',
                            size: 13,
                            color: ParchmentColors.muted,
                          ),
                          if (!canUse)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ParchmentLabel(
                                game.state.availableResource(id) == 0
                                    ? 'No ${itemName(id).toLowerCase()} available.'
                                    : 'Cannot use this item right now.',
                                size: 13,
                                color: ParchmentColors.rust,
                              ),
                            ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (fieldTools.containsKey(id) && !game.state.inField)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: parchmentButton(
                            'EQUIP TOOL',
                            game.state.toolUsable(id)
                                ? () => Navigator.pop(context, 'equip-tool:$id')
                                : null,
                            secondary: true,
                            key: ValueKey('equip-tool-$id'),
                          ),
                        ),
                        if (game.canRepairTool(id))
                          SizedBox(
                            width: double.infinity,
                            child: parchmentButton('REPAIR TOOL', () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    ToolRepairDialog(game: game, id: id),
                              );
                              if (result == true && context.mounted) {
                                Navigator.pop(context, 'repair-tool:$id');
                              }
                            }, secondary: true),
                          ),
                      ],
                    ),
                  ),
                if (fishingRods.containsKey(id) && !game.state.inField)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: parchmentButton(
                      'EQUIP ROD',
                      game.state.toolUsable(id)
                          ? () => Navigator.pop(context, 'equip-rod:$id')
                          : null,
                      secondary: true,
                    ),
                  ),
                if (fish != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: parchmentButton(
                      'PREPARE SAFELY · 1 WOOD · 1 TIME',
                      game.prepareFishBlockReason(id) == null
                          ? () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    FishPreparationDialog(game: game, id: id),
                              );
                              if (confirmed == true && context.mounted) {
                                Navigator.pop(context, 'prepare-fish:$id');
                              }
                            }
                          : null,
                      secondary: true,
                    ),
                  ),
                if (fish != null && game.prepareFishBlockReason(id) != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ParchmentLabel(
                      game.prepareFishBlockReason(id)!,
                      size: 12,
                      color: ParchmentColors.rust,
                    ),
                  ),
                if (id == 'herb' &&
                    game.state.condition(ConditionKind.poisoned) != null &&
                    game.state.condition(ConditionKind.poisoned)!.remaining >
                        1 &&
                    game.state.availableResource('herb') > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: parchmentButton(
                      'CHEW BITTER LEAVES · USE 1',
                      game.canUseSupplies
                          ? () => Navigator.pop(context, 'chew')
                          : null,
                      secondary: true,
                    ),
                  ),
                if (jungleFoods.containsKey(id) &&
                    !game.state.knownSpecies.contains(id))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: parchmentButton(
                      'STUDY SAMPLE · 1 TIME',
                      game.canUseSupplies &&
                              game.state.locationId == 'camp' &&
                              game.state.timeLeft > 0 &&
                              game.state.phase == RunPhase.day &&
                              game.state.availableResource(id) > 0
                          ? () => Navigator.pop(context, 'study:$id')
                          : null,
                      secondary: true,
                    ),
                  ),
                if (id == 'ribbon_root')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: parchmentButton(
                      'PREPARE UP TO 3 · 1 WOOD · 1 TIME',
                      game.canAct(CampAction.rest) &&
                              game.state.availableResource(id) > 0 &&
                              game.state.availableResource('wood') > 0
                          ? () => Navigator.pop(context, 'roots')
                          : null,
                      secondary: true,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: consumable
                      ? parchmentButton(
                          id == 'herb'
                              ? 'BREW TEA · USE 1'
                              : id == 'antidote' || id == 'bandage'
                              ? 'USE TREATMENT · 1'
                              : fish?.hazardous == true
                              ? 'EAT UNPREPARED · UNSAFE'
                              : preparedFishSource(id) != null
                              ? 'EAT · USE 1'
                              : jungleFoods.containsKey(id)
                              ? 'EAT · USE 1'
                              : 'COOK & EAT · USE 1',
                          canUse
                              ? () async {
                                  if (fish?.hazardous == true) {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => CanopyConfirmation(
                                        title: 'Eat without preparing?',
                                        destructive: true,
                                        art: id,
                                        message:
                                            '${fish!.handling} Use a knife and prepare it safely instead.',
                                        confirm: 'Eat unprepared',
                                        cancel: 'Keep fish',
                                        confirmKey: const ValueKey(
                                          'confirm-unsafe-fish',
                                        ),
                                      ),
                                    );
                                    if (confirmed != true || !context.mounted) {
                                      return;
                                    }
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context, 'consume:$id');
                                  }
                                }
                              : null,
                          key: ValueKey('consume-$id'),
                        )
                      : parchmentButton(
                          'OPEN WORKSHOP',
                          () => Navigator.pop(context, 'workshop'),
                          secondary: true,
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

String _description(String id) => switch (id) {
  'wood' => 'Used to build shelter, craft tools and fuel your fire.',
  'stone' => 'Used for stone tools and camp construction.',
  'fiber' => 'Plant fibers used for bindings, tools and shelter.',
  'bait' => 'Use one bait to cast your fishing line.',
  'hardwood' => 'Strong timber for advanced camp upgrades.',
  'metal_scrap' => 'Salvaged metal used for camp upgrades and crafting.',
  'battery' || 'wire' || 'metal_parts' || 'radio_module' || 'beacon_core' =>
    'A rescue component needed to assemble the emergency beacon.',
  _ => 'A crafting material. View recipes in the workshop to find its uses.',
};
