import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../game/gathering_session.dart';
import '../game/tool_catalog.dart';
import '../game/world_catalog.dart';
import 'card_art.dart';
import 'parchment_components.dart';
import 'tool_art.dart';

Widget toolRow(String label, String value, {String? icon}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      if (icon != null) ...[CardArt(icon, size: 24), const SizedBox(width: 8)],
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: ParchmentColors.ink),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(child: ParchmentLabel(value, size: 13, align: TextAlign.right)),
    ],
  ),
);
Widget conditionBar(String label, int current, int maximum) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    toolRow(label, '$current / $maximum'),
    LinearProgressIndicator(
      value: (current / maximum).clamp(0, 1),
      minHeight: 6,
      color: ParchmentColors.leaf,
      backgroundColor: const Color(0xFFCDC098),
    ),
  ],
);

class FieldToolSummary extends StatelessWidget {
  const FieldToolSummary({
    super.key,
    required this.game,
    required this.id,
    this.crafting = false,
  });
  final GameEngine game;
  final String id;
  final bool crafting;
  @override
  Widget build(BuildContext context) {
    final t = fieldTools[id]!;
    final repairing = game.canRepairTool(id);
    final previous = game.recipes.find(id)?.requiresItems.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        conditionBar(
          crafting ? (repairing ? 'After repair' : 'New tool') : 'Condition',
          crafting ? t.durability : game.state.toolCondition(id),
          t.durability,
        ),
        if (crafting && repairing)
          toolRow(
            'Current condition',
            '${game.state.toolCondition(id)} / ${t.durability}',
          ),
        if (crafting && !repairing && previous != null)
          toolRow('Previous tool', '${itemName(previous)} · kept'),
        toolRow('GOOD timing zone', '×${t.goodScale.toStringAsFixed(2)}'),
        if (t.family == 'spear')
          toolRow(
            'Risky spear decisions',
            '+${(t.chanceBonus * 100).round()} percentage points',
          ),
        if (t.family == 'axe' && t.tier > 0)
          toolRow('Successful chopping', '+${t.tier} Wood per attempt'),
        if (t.id == 'salvage_axe')
          const Text(
            'Extra Hardwood with at least two PERFECT strikes.',
            style: TextStyle(fontSize: 12, color: ParchmentColors.ink),
          ),
      ],
    );
  }
}

class ToolRepairDialog extends StatelessWidget {
  const ToolRepairDialog({super.key, required this.game, required this.id});
  final GameEngine game;
  final String id;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(12),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 420,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: PaperSurface(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ParchmentLabel(
                      'REPAIR ${itemName(id).toUpperCase()}',
                      size: 18,
                    ),
                  ),
                  ParchmentClose(onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(aspectRatio: 1.5, child: ToolArt(id)),
              conditionBar(
                'Before repair',
                game.state.toolCondition(id),
                fieldTools[id]!.durability,
              ),
              const SizedBox(height: 12),
              conditionBar(
                'After repair',
                fieldTools[id]!.durability,
                fieldTools[id]!.durability,
              ),
              const SizedBox(height: 16),
              const ParchmentLabel('COST · NEEDED / AVAILABLE', size: 11),
              for (final e in game.craftCosts(id).entries)
                toolRow(
                  itemName(e.key),
                  '${e.value} / ${game.state.resource(e.key)}',
                  icon: e.key,
                ),
              toolRow('Daylight', '1 time'),
              if (game.craftBlockReason(id) != null)
                Text(
                  game.craftBlockReason(id)!,
                  style: const TextStyle(color: ParchmentColors.rust),
                ),
              const SizedBox(height: 12),
              parchmentButton(
                'REPAIR · 1 TIME',
                game.craftBlockReason(id) == null
                    ? () => Navigator.pop(context, true)
                    : null,
                key: ValueKey('confirm-repair-$id'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<String?> chooseFieldTool(
  BuildContext context,
  GameEngine game,
  String family,
) => showDialog<String>(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(10),
    child: PaperSurface(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ParchmentLabel(
                    family == 'axe' ? 'CHOOSE YOUR AXE' : 'CHOOSE YOUR SPEAR',
                    size: 17,
                  ),
                ),
                ParchmentClose(onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            ParchmentCardGrid(
              children: [
                for (final t in fieldTools.values.where(
                  (t) => t.family == family,
                ))
                  ParchmentCard(
                    key: ValueKey('select-${t.id}'),
                    title: t.name,
                    art: t.id,
                    info:
                        '${game.state.toolCondition(t.id)} / ${t.durability} condition',
                    status: game.state.activeFieldTool(family) == t.id
                        ? 'EQUIPPED'
                        : game.state.toolUsable(t.id)
                        ? 'AVAILABLE'
                        : game.state.tools.contains(t.id)
                        ? 'BROKEN'
                        : 'NOT OWNED',
                    selected: game.state.activeFieldTool(family) == t.id,
                    onTap: game.state.toolUsable(t.id)
                        ? () => Navigator.pop(context, t.id)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);

class GatheringToolLoadout extends StatelessWidget {
  const GatheringToolLoadout({
    super.key,
    required this.game,
    required this.onChanged,
    required this.onStart,
    required this.onBack,
    required this.onWorkshop,
    required this.kind,
  });
  final GameEngine game;
  final GatheringKind kind;
  final VoidCallback onChanged, onStart, onBack, onWorkshop;
  @override
  Widget build(BuildContext context) {
    final id = game.gatheringTool(kind);
    final block = game.gatheringBlockReason(kind);
    final selected = kind == GatheringKind.chopping
        ? game.state.equippedAxe
        : game.state.equippedSpear;
    return PaperSurface(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (id != null) ...[
              Row(
                children: [
                  SizedBox(width: 90, height: 60, child: ToolArt(id)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ParchmentLabel(itemName(id), size: 14),
                        conditionBar(
                          'Condition',
                          game.state.toolCondition(id),
                          fieldTools[id]!.durability,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (id != selected)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Selected tool unavailable. Using your best working tool.',
                    style: TextStyle(fontSize: 12, color: ParchmentColors.rust),
                  ),
                ),
              toolRow(
                'GOOD timing zone',
                '×${fieldTools[id]!.goodScale.toStringAsFixed(2)}',
              ),
            ],
            toolRow(
              'Start cost',
              '${game.gatheringCost} time · ${game.gatheringCost * 4} water · ${game.gatheringCost * 3} food base',
            ),
            const Text(
              'Each miss causes extra tool wear. Results are revealed after the attempt.',
              style: TextStyle(fontSize: 12, color: ParchmentColors.ink),
            ),
            if (block != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  block,
                  style: const TextStyle(color: ParchmentColors.rust),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: parchmentButton('CHANGE', () async {
                    final value = await chooseFieldTool(
                      context,
                      game,
                      kind == GatheringKind.chopping ? 'axe' : 'spear',
                    );
                    if (value != null && game.equipFieldTool(value)) {
                      onChanged();
                    }
                  }, secondary: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: parchmentButton(
                    'START',
                    block == null ? onStart : null,
                    key: const ValueKey('gathering-start'),
                  ),
                ),
              ],
            ),
            TextButton(
              key: const ValueKey('gathering-back'),
              onPressed: block == null ? onBack : onWorkshop,
              child: Text(block == null ? 'BACK' : 'WORKSHOP'),
            ),
          ],
        ),
      ),
    );
  }
}
