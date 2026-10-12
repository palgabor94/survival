import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final tools = game.recipes.crafts.where((r) => r.isOwnedBy(state)).toList();
    final items = tab == 2
        ? tools.map((r) => r.id).toList()
        : tab == 1
        ? GameEngine.consumables.toList()
        : <String>{
            'wood',
            'stone',
            'fiber',
            'bait',
            for (final id in state.resources.keys)
              if (!GameEngine.consumables.contains(id)) id,
          }.toList();
    final chosen = items.contains(selected)
        ? selected
        : (items.isEmpty ? null : items.first);
    final consumable =
        chosen != null && GameEngine.consumables.contains(chosen);
    final foodId = consumable ? chosen : null;
    final effect = foodId != null
        ? (game.consumeEffect(foodId).summary.split(' · ')
                ..removeWhere((part) => part.contains(foodId)))
              .join(' · ')
        : null;
    final recipe = chosen == null ? null : game.recipes.find(chosen);
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    return CanopyDialog(
      title: 'Camp inventory',
      art: 'inventory',
      actions: [
        if (foodId != null)
          ActionCard(
            key: ValueKey('consume-$chosen'),
            title: chosen == 'herb' ? 'Brew tea' : 'Cook & eat',
            art: chosen,
            horizontal: true,
            tag: 'USE 1',
            description: effect,
            onTap: game.canConsume(foodId)
                ? () => Navigator.pop(context, 'consume:$chosen')
                : null,
          )
        else
          ActionCard(
            key: const ValueKey('open-workshop'),
            title: 'Workshop',
            art: 'craft',
            tone: CardTone.sand,
            horizontal: true,
            onTap: () => Navigator.pop(context, 'workshop'),
          ),
        ActionCard(
          key: const ValueKey('close-inventory'),
          title: 'Back to camp',
          art: 'back',
          tone: CardTone.river,
          horizontal: true,
          onTap: () => Navigator.pop(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < 3; i++)
                OutlinedButton(
                  key: ValueKey('inventory-tab-$i'),
                  onPressed: () => setState(() {
                    tab = i;
                    selected = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: tab == i ? CanopyColors.panelLight : null,
                    side: BorderSide(
                      color: tab == i ? CanopyColors.leaf : CanopyColors.border,
                    ),
                  ),
                  child: Text(
                    ['MATERIALS', 'FOOD', 'GEAR'][i],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Nothing crafted yet.')
          else
            CardDeck(
              columns: large
                  ? 1
                  : MediaQuery.sizeOf(context).width < 380
                  ? 2
                  : 3,
              cards: [
                for (final id in items)
                  ActionCard(
                    key: ValueKey('inventory-$id'),
                    title: game.recipes.find(id)?.name ?? itemName(id),
                    art: id,
                    compact: true,
                    horizontal: large,
                    tone: tab == 2 ? CardTone.sand : CardTone.leaf,
                    selected: id == chosen,
                    tag: tab == 2 ? 'OWNED' : '${state.resource(id)}',
                    onTap: () => setState(() => selected = id),
                  ),
              ],
            ),
          if (chosen != null) ...[
            const SizedBox(height: 12),
            CanopyTitle(
              title: recipe?.name ?? itemName(chosen),
              art: chosen,
              subtitle: consumable
                  ? '$effect · consumes 1 · no daylight'
                  : recipe?.effect,
            ),
          ],
        ],
      ),
    );
  }
}
