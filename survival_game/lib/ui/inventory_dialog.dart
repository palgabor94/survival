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
  int tab = 0;
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
        command.startsWith('study:') ||
        command == 'dry' ||
        command == 'roots' ||
        command == 'chew' ||
        command == 'workshop' ||
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
        .where((r) => r.isOwnedBy(game.state))
        .toList();
    final items = tab == 2
        ? tools.map((r) => r.id).toList()
        : tab == 1
        ? GameEngine.consumables
              .where(
                (id) =>
                    ['small_fish', 'raw_meat', 'herb'].contains(id) ||
                    game.state.resource(id) > 0,
              )
              .toList()
        : <String>{
            'wood',
            'stone',
            'fiber',
            'bait',
            for (final id in game.state.resources.keys)
              if (!GameEngine.consumables.contains(id)) id,
          }.toList();
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
                          ['MATERIALS', 'FOOD', 'GEAR'][i],
                          () => setState(() {
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
              const Padding(
                padding: EdgeInsets.all(12),
                child: ParchmentLabel(
                  'Tap an item to view details.',
                  size: 12,
                  color: ParchmentColors.muted,
                  align: TextAlign.center,
                ),
              ),
              if (game.state.hasCondition(ConditionKind.wet))
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: parchmentButton(
                    'DRY BY FIRE · 1 WOOD · 1 TIME',
                    game.canAct(CampAction.rest) &&
                            game.state.resource('wood') > 0
                        ? dryDetails
                        : null,
                    secondary: true,
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('dialog-content-scroll'),
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: ParchmentLabel(
                            'Nothing crafted yet.',
                            align: TextAlign.center,
                            weight: FontWeight.w500,
                          ),
                        )
                      : ParchmentCardGrid(
                          children: [
                            for (final id in items)
                              ParchmentCard(
                                key: ValueKey('inventory-$id'),
                                title:
                                    game.recipes.find(id)?.name ?? itemName(id),
                                art: id,
                                info: tab == 2
                                    ? 'View equipment'
                                    : 'View details',
                                status: tab == 2
                                    ? 'OWNED'
                                    : '${game.state.resource(id)}',
                                selected: selected == id,
                                onTap: () => details(id),
                              ),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: parchmentButton(
                  'OPEN WORKSHOP',
                  () => Navigator.pop(context, 'workshop'),
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
                            'IN STOCK · ${game.state.resource(id)}',
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
                                game.state.resource(id) == 0
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
                if (fishingRods.containsKey(id))
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
                    game.state.resource('herb') > 0)
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
                              game.state.resource(id) > 0
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
                              game.state.resource(id) > 0 &&
                              game.state.resource('wood') > 0
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
