import 'first_day_guide.dart';
import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../game/inventory_catalog.dart';
import '../game/world_catalog.dart';
import '../game/tool_catalog.dart';
import '../game/fishing_catalog.dart';
import 'parchment_components.dart';
import 'card_art.dart';
import 'card_illustration.dart';
import 'fishing_art.dart';
import 'ecology_art.dart';
import 'canopy_components.dart';

/// Short labels keep card titles within their shared two-line header.
/// Quantity and item detail dialogs still show the full species name.
String inventoryCardName(String id) {
  final source = preparedFishSource(id);
  final fishId = source ?? id;
  final short = const {
    'small_fish': 'Silverfish',
    'redfin_perch': 'Redfin Perch',
    'mud_whisker': 'Mud Whisker',
    'spiny_sunlurker': 'Sunlurker',
    'goldspot_riverfish': 'Goldspot',
  }[fishId];
  return short == null
      ? itemName(id)
      : source == null
      ? short
      : 'Cooked $short';
}

String inventorySlotsLabel(int n) => '$n ${n == 1 ? 'slot' : 'slots'}';

class PackCapacity extends StatelessWidget {
  const PackCapacity({super.key, required this.used, required this.maximum});
  final int used, maximum;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.backpack_outlined, color: ParchmentColors.leaf),
            const SizedBox(width: 8),
            const Expanded(child: ParchmentLabel('PACK SPACE', size: 11)),
            ParchmentLabel(
              '$used / $maximum',
              size: 16,
              color: used > maximum
                  ? ParchmentColors.rust
                  : ParchmentColors.ink,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < maximum; i++)
              Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i == maximum - 1 ? 0 : 3),
                  color: i < used
                      ? ParchmentColors.leaf
                      : const Color(0xFFCDC098),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class InventoryPicture extends StatelessWidget {
  const InventoryPicture(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.5,
    child: hasFishingArt(id)
        ? FishingArt(id)
        : hasEcologyArt(id)
        ? EcologyArt(id)
        : Image.asset(
            cardIllustrationFor(id) ?? 'assets/art/card_inventory_scene_v1.png',
            fit: BoxFit.cover,
          ),
  );
}

class ItemQuantityDialog extends StatefulWidget {
  const ItemQuantityDialog({
    super.key,
    required this.id,
    required this.maximum,
    required this.current,
    this.caption = 'CHOOSE AMOUNT',
  });
  final String id, caption;
  final int maximum, current;
  @override
  State<ItemQuantityDialog> createState() => _ItemQuantityDialogState();
}

class _ItemQuantityDialogState extends State<ItemQuantityDialog> {
  late int count = widget.current;
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: itemName(widget.id),
    art: widget.id,
    subtitle: widget.caption,
    actions: [
      parchmentButton(
        'USE THIS AMOUNT',
        () => Navigator.pop(context, count),
        key: const ValueKey('confirm-item-quantity'),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: InventoryPicture(widget.id),
          ),
        ),
        const SizedBox(height: 12),
        ParchmentLabel(
          '$count / ${widget.maximum} selected',
          size: 18,
          align: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final delta in [-1, 1, 5, 0]) ...[
              if (delta != -1) const SizedBox(width: 8),
              Expanded(
                child: parchmentButton(
                  delta == 0
                      ? 'ALL'
                      : delta > 0
                      ? '+$delta'
                      : '−1',
                  () => setState(
                    () => count = delta == 0
                        ? widget.maximum
                        : (count + delta).clamp(0, widget.maximum),
                  ),
                  secondary: true,
                  key: ValueKey('quantity-$delta'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        ParchmentLabel(
          '${stackLimit(widget.id)} per slot · ${packSlots({widget.id: count})} slots',
          size: 12,
        ),
      ],
    ),
  );
}

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key, required this.game});
  final GameEngine game;
  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  int tab = 1;
  GameEngine get game => widget.game;
  Future<void> quantity(String id) async {
    final draft = game.packingDraft;
    if (draft == null) return;
    final n = await showDialog<int>(
      context: context,
      routeSettings: const RouteSettings(name: 'item_quantity_dialog'),
      builder: (_) => ItemQuantityDialog(
        id: id,
        maximum: game.state.storedResources[id] ?? 0,
        current: draft.items[id] ?? 0,
        caption: 'FROM CAMP TO BACKPACK',
      ),
    );
    if (n != null && mounted) {
      setState(() => game.updatePacking({...draft.items, id: n}, draft.gear));
    }
  }

  Future<void> chooseGear(String family, List<String> ids) async {
    final draft = game.packingDraft!;
    final selected = await showDialog<String>(
      context: context,
      routeSettings: const RouteSettings(name: 'choose_family'),
      builder: (context) => CanopyDialog(
        title: 'Choose $family',
        art: 'inventory',
        actions: [
          parchmentButton(
            'LEAVE SLOT EMPTY',
            () => Navigator.pop(context, ''),
            secondary: true,
          ),
        ],
        child: ParchmentCardGrid(
          children: [
            for (final id in ids)
              ParchmentCard(
                title: itemName(id),
                art: id,
                info: game.state.tools.contains(id) ? 'Owned' : 'Not owned',
                status: draft.gear.contains(id)
                    ? 'EQUIPPED'
                    : game.state.toolUsable(id)
                    ? 'AVAILABLE'
                    : 'LOCKED',
                selected: draft.gear.contains(id),
                onTap: game.state.toolUsable(id)
                    ? () => Navigator.pop(context, id)
                    : null,
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final gear = {...draft.gear}..removeAll(ids);
    if (selected.isNotEmpty) gear.add(selected);
    setState(() => game.updatePacking(draft.items, gear));
  }

  @override
  Widget build(BuildContext context) {
    final draft = game.packingDraft;
    if (draft == null) return const Scaffold(body: SizedBox.shrink());
    final place = game.world.find(draft.destination);
    final block = game.departureBlockReason(
      draft.destination,
      draft.items,
      draft.gear,
    );
    final items = tab == 0 ? game.state.storedResources : draft.items;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          game.cancelPacking();
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        body: SafeArea(
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
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const CardArt('inventory', size: 32),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const ParchmentLabel(
                                    'PREPARE PACK',
                                    size: 20,
                                  ),
                                  ParchmentLabel(
                                    place?.name.toUpperCase() ??
                                        draft.destination,
                                    size: 11,
                                  ),
                                ],
                              ),
                            ),
                            ParchmentClose(
                              key: const ValueKey('cancel-packing'),
                              onPressed: () {
                                game.cancelPacking();
                                Navigator.pop(context, false);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: parchmentButton(
                                  ['STORAGE', 'BACKPACK', 'GEAR'][i],
                                  () => setState(() => tab = i),
                                  secondary: tab != i,
                                  key: ValueKey('packing-tab-$i'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: PackCapacity(
                          used: packSlots(draft.items),
                          maximum: game.state.packCapacity,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FirstDayCoach(game: game, place: 'packing'),
                              if (game.packingNotice != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ParchmentLabel(
                                    game.packingNotice!,
                                    size: 12,
                                    color: ParchmentColors.rust,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              if (tab < 2) ...[
                                if (items.values.every((n) => n == 0))
                                  const ParchmentLabel(
                                    'Nothing packed yet. Choose items from Storage.',
                                    size: 13,
                                  ),
                                ParchmentCardGrid(
                                  children: [
                                    for (final e in items.entries)
                                      if (e.value > 0)
                                        ParchmentCard(
                                          key: ValueKey(
                                            'packing-item-${e.key}',
                                          ),
                                          title: inventoryCardName(e.key),
                                          art: e.key,
                                          info: tab == 0
                                              ? '${e.value} stored'
                                              : '${e.value} packed · ${inventorySlotsLabel(packSlots({e.key: e.value}))}',
                                          status: tab == 0
                                              ? 'ADD TO PACK'
                                              : 'ADJUST',
                                          onTap: () => quantity(e.key),
                                        ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const ParchmentLabel(
                                  'Tap an item to choose its amount. Equipment uses separate slots.',
                                  size: 12,
                                  weight: FontWeight.w500,
                                ),
                                if (tab == 1)
                                  TextButton(
                                    onPressed: () => setState(() => tab = 0),
                                    child: const Text('ADD ITEMS FROM STORAGE'),
                                  ),
                              ] else ...[
                                for (final group in <(String, List<String>)>[
                                  (
                                    'axe',
                                    fieldTools.values
                                        .where((t) => t.family == 'axe')
                                        .map((t) => t.id)
                                        .toList(),
                                  ),
                                  (
                                    'spear',
                                    fieldTools.values
                                        .where((t) => t.family == 'spear')
                                        .map((t) => t.id)
                                        .toList(),
                                  ),
                                  ('rod', fishingRods.keys.toList()),
                                  ('blade', ['stone_knife', 'machete']),
                                  ('torch', ['torch']),
                                  ('cape', ['leaf_rain_cape']),
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: parchmentButton(
                                      '${group.$1.toUpperCase()}: ${group.$2.where(draft.gear.contains).map(itemName).firstOrNull ?? 'Empty'}',
                                      () => chooseGear(group.$1, group.$2),
                                      secondary: true,
                                    ),
                                  ),
                                const ParchmentLabel(
                                  'Equipped gear stays with you if you drop the pack. Spare tools remain at camp.',
                                  size: 12,
                                  weight: FontWeight.w500,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ParchmentLabel(
                              block ??
                                  'Journey: ${place?.timeCost ?? 0} time · base ${(place?.timeCost ?? 0) * 4} Water · ${(place?.timeCost ?? 0) * 3} Food',
                              size: 12,
                              color: block == null
                                  ? ParchmentColors.ink
                                  : ParchmentColors.rust,
                              weight: FontWeight.w500,
                            ),
                            const SizedBox(height: 8),
                            parchmentButton(
                              'LEAVE CAMP · ${place?.timeCost ?? 0} TIME',
                              block == null
                                  ? () {
                                      if (game.leaveCamp()) {
                                        Navigator.pop(context, true);
                                      }
                                    }
                                  : null,
                              key: const ValueKey('confirm-departure'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HaulResolutionScreen extends StatefulWidget {
  const HaulResolutionScreen({super.key, required this.game});
  final GameEngine game;
  @override
  State<HaulResolutionScreen> createState() => _HaulResolutionScreenState();
}

class _HaulResolutionScreenState extends State<HaulResolutionScreen> {
  late Map<String, int> kept = {...widget.game.haulSelection};
  Future<void> change(String id) async {
    final n = await showDialog<int>(
      context: context,
      routeSettings: const RouteSettings(name: 'item_quantity_dialog'),
      builder: (_) => ItemQuantityDialog(
        id: id,
        maximum: widget.game.haulCandidate[id] ?? 0,
        current: kept[id] ?? 0,
        caption: 'SELECT FINAL AMOUNT',
      ),
    );
    if (n != null && mounted) {
      setState(() {
        kept[id] = n;
        widget.game.updateHaulSelection(kept);
      });
    }
  }

  Future<void> confirm() async {
    final game = widget.game;
    final discarded = {
      for (final e in game.haulCandidate.entries)
        if (e.value > (kept[e.key] ?? 0)) e.key: e.value - (kept[e.key] ?? 0),
    };
    if (discarded.isNotEmpty) {
      final yes = await showDialog<bool>(
        context: context,
        routeSettings: const RouteSettings(name: 'leave_these_items'),
        builder: (context) => CanopyDialog(
          title: 'Leave these items?',
          art: 'inventory',
          subtitle: 'FINAL CONFIRMATION',
          actions: [
            parchmentButton(
              'CONFIRM & KEEP SELECTED',
              () => Navigator.pop(context, true),
              key: const ValueKey('confirm-discard'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final e in discarded.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CardArt(e.key, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ParchmentLabel(itemName(e.key), size: 14),
                      ),
                      ParchmentLabel('${e.value} left behind', size: 13),
                    ],
                  ),
                ),
              if (discarded.keys.any(
                (id) => const {
                  'battery',
                  'wire',
                  'metal_parts',
                  'radio_module',
                  'beacon_core',
                }.contains(id),
              ))
                const ParchmentLabel(
                  'Rescue component: leaving it delays your rescue. You will need to find it again.',
                  size: 13,
                ),
              const SizedBox(height: 12),
              const ParchmentLabel(
                'Left items cannot be collected later. Closing returns to your selection.',
                size: 13,
                weight: FontWeight.w500,
              ),
            ],
          ),
        ),
      );
      if (yes != true) return;
    }
    if (mounted && game.resolveHaul(kept)) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final used = packSlots(kept);
    return Scaffold(
      body: SafeArea(
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
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: ParchmentLabel('MAKE ROOM', size: 22),
                          ),
                          ParchmentClose(
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: PackCapacity(
                        used: used,
                        maximum: game.state.packCapacity,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: ParchmentLabel(
                        'Choose what to keep. Nothing is discarded until you confirm.',
                        size: 13,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: ParchmentCardGrid(
                          children: [
                            for (final e in game.haulCandidate.entries)
                              ParchmentCard(
                                key: ValueKey('haul-item-${e.key}'),
                                title: inventoryCardName(e.key),
                                art: e.key,
                                info: 'Keep ${kept[e.key] ?? 0} / ${e.value}',
                                status: inventorySlotsLabel(
                                  packSlots({e.key: kept[e.key] ?? 0}),
                                ).toUpperCase(),
                                selected:
                                    (game.state.pendingResources[e.key] ?? 0) >
                                    0,
                                onTap: () => change(e.key),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: parchmentButton(
                        used > game.state.packCapacity
                            ? 'MAKE ROOM TO CONTINUE'
                            : 'KEEP CHOSEN ITEMS',
                        used <= game.state.packCapacity ? confirm : null,
                        key: const ValueKey('confirm-haul'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
