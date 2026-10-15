import 'package:flutter/material.dart';
import '../game/fishing_catalog.dart';
import '../game/fishing_session.dart';
import '../game/game_engine.dart';
import 'fishing_art.dart';
import 'parchment_components.dart';
import 'canopy_components.dart';
import 'card_art.dart';

class FishingLoadout extends StatelessWidget {
  const FishingLoadout({
    super.key,
    required this.game,
    required this.onChanged,
    required this.onCast,
    required this.onLeave,
    required this.onPractice,
  });
  final GameEngine game;
  final VoidCallback onChanged, onCast, onLeave, onPractice;
  @override
  Widget build(BuildContext context) {
    final session = game.fishing!;
    final rod = fishingRods[session.rodId]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaperSurface(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CardArt(rod.id, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ParchmentLabel(rod.name.toUpperCase(), size: 12),
                      ParchmentLabel(
                        'Condition ${game.state.toolCondition(rod.id)} / ${rod.durability}',
                        size: 10,
                        color: ParchmentColors.muted,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => CanopyDialog(
                        title: 'Fishing gear',
                        art: 'basic_rod',
                        child: ParchmentCardGrid(
                          children: [
                            for (final item in fishingRods.values)
                              ParchmentCard(
                                title: item.name,
                                art: item.id,
                                info:
                                    'Zone +${((item.zoneScale - 1) * 100).round()}%',
                                status: !game.state.tools.contains(item.id)
                                    ? 'LOCKED'
                                    : !game.state.toolUsable(item.id)
                                    ? 'REPAIR'
                                    : session.rodId == item.id
                                    ? 'EQUIPPED'
                                    : 'EQUIP',
                                selected: session.rodId == item.id,
                                onTap: game.state.toolUsable(item.id)
                                    ? () {
                                        game.equipFishingRod(item.id);
                                        Navigator.pop(context);
                                        onChanged();
                                      }
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('CHANGE'),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 7),
          child: Text(
            'CHOOSE BAIT · tap for details',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ParchmentColors.cream,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ),
        ParchmentCardGrid(
          children: [
            for (final bait in fishingBaits.values)
              ParchmentCard(
                key: ValueKey('fishing-bait-${bait.id}'),
                title: bait.name,
                art: bait.id,
                info: 'In pack · ${game.state.availableResource(bait.id)}',
                status: session.baitId == bait.id
                    ? 'SELECTED'
                    : game.state.availableResource(bait.id) > 0
                    ? 'AVAILABLE'
                    : 'EMPTY',
                selected: session.baitId == bait.id,
                onTap: () async {
                  final selected = await showDialog<bool>(
                    context: context,
                    builder: (context) => CanopyDialog(
                      title: bait.name,
                      art: bait.id,
                      subtitle: 'BAIT PREFERENCES',
                      actions: [
                        parchmentButton(
                          'SELECT ${bait.name.toUpperCase()}',
                          game.state.availableResource(bait.id) > 0
                              ? () => Navigator.pop(context, true)
                              : null,
                          key: ValueKey('select-bait-${bait.id}'),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.5,
                            child: FishingArt(bait.id),
                          ),
                          const SizedBox(height: 10),
                          Text(bait.description),
                          const SizedBox(height: 10),
                          const Text(
                            'Bait changes which fish may bite. It never guarantees a rare catch. Your rod must be strong enough to land the species.',
                          ),
                        ],
                      ),
                    ),
                  );
                  if (selected == true) {
                    game.selectFishingBait(bait.id);
                    onChanged();
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        PaperSurface(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ParchmentLabel(
                  'Journey already paid · cast uses 1 bait',
                  size: 10,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 7),
                const ParchmentLabel(
                  'White bar = you. Green zone = fish.',
                  size: 10,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 7),
                parchmentButton(
                  'CAST LINE',
                  game.state.availableResource(session.baitId) > 0 &&
                          game.state.toolUsable(rod.id)
                      ? onCast
                      : null,
                  key: const ValueKey('cast-line'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('fishing-practice'),
                        onPressed: onPractice,
                        child: const Text('Try it first'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('fishing-return'),
                        onPressed: onLeave,
                        child: const Text('Leave'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FishingCatchDialog extends StatelessWidget {
  const FishingCatchDialog({
    super.key,
    required this.record,
    required this.isNew,
    required this.quality,
    required this.onKeep,
    required this.onRelease,
    required this.onClose,
  });
  final FishCatch record;
  final bool isNew;
  final CatchQuality quality;
  final VoidCallback onKeep, onRelease, onClose;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: PaperSurface(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CardArt(record.speciesId, size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ParchmentLabel('CATCH LANDED', size: 18),
                          ParchmentLabel(
                            '${record.species.rarity.toUpperCase()} · ${isNew ? 'FIRST DISCOVERY' : 'KNOWN SPECIES'}',
                            size: 10,
                            color: ParchmentColors.muted,
                          ),
                        ],
                      ),
                    ),
                    ParchmentClose(onPressed: onClose),
                  ],
                ),
                const Divider(height: 20),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: FishingArt(record.speciesId),
                ),
                const SizedBox(height: 12),
                ParchmentLabel(
                  record.species.name.toUpperCase(),
                  size: 20,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in [
                      ('LENGTH', '${record.lengthCm} cm'),
                      ('WEIGHT', record.weightLabel),
                      ('SIZE', record.sizeLabel),
                    ])
                      Container(
                        width: 92,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFB7A981)),
                        ),
                        child: Column(
                          children: [
                            ParchmentLabel(value.$2, size: 16),
                            ParchmentLabel(
                              value.$1,
                              size: 9,
                              color: ParchmentColors.muted,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (quality == CatchQuality.perfect)
                  const ParchmentLabel(
                    'PERFECT LANDING',
                    size: 11,
                    color: ParchmentColors.leaf,
                    align: TextAlign.center,
                  ),
                if (record.species.hazardous)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: ParchmentColors.rust,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ParchmentLabel(
                            'PREPARATION REQUIRED',
                            size: 12,
                            color: ParchmentColors.rust,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  record.species.handling,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (record.species.hazardous)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Catching and keeping this fish does not poison you.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),
                parchmentButton(
                  'KEEP CATCH',
                  onKeep,
                  key: const ValueKey('keep-fish-catch'),
                ),
                const SizedBox(height: 7),
                parchmentButton(
                  'RELEASE',
                  onRelease,
                  secondary: true,
                  key: const ValueKey('release-fish-catch'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FishJournalDialog extends StatelessWidget {
  const FishJournalDialog({super.key, required this.game});
  final GameEngine game;
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: 'River field guide',
    art: 'journal',
    subtitle:
        '${game.state.knownFish.length} / ${fishSpecies.length} SPECIES DISCOVERED',
    child: ParchmentCardGrid(
      children: [
        for (final species in fishSpecies.values)
          ParchmentCard(
            title: game.state.knownFish.contains(species.id)
                ? species.name
                : 'Unknown species',
            art: species.id,
            info: game.state.knownFish.contains(species.id)
                ? species.rarity
                : 'Keep exploring',
            status: game.state.knownFish.contains(species.id)
                ? 'KNOWN'
                : 'UNKNOWN',
            onTap: game.state.knownFish.contains(species.id)
                ? () => showDialog<void>(
                    context: context,
                    builder: (context) => CanopyDialog(
                      title: species.name,
                      art: species.id,
                      subtitle: species.rarity.toUpperCase(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.5,
                            child: FishingArt(species.id),
                          ),
                          const SizedBox(height: 12),
                          Text(species.handling),
                          const SizedBox(height: 12),
                          Text(species.habitat),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
      ],
    ),
  );
}

class FishPreparationDialog extends StatelessWidget {
  const FishPreparationDialog({
    super.key,
    required this.game,
    required this.id,
  });
  final GameEngine game;
  final String id;
  @override
  Widget build(BuildContext context) {
    final fish = fishSpecies[id]!;
    Widget line(String icon, String label, String count) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CardArt(icon, size: 25),
          const SizedBox(width: 9),
          Expanded(child: ParchmentLabel(label, size: 13)),
          ParchmentLabel(count, size: 13),
        ],
      ),
    );
    return CanopyDialog(
      title: 'Prepare ${fish.name}',
      art: 'stone_knife',
      subtitle: 'CAMP WORKSHOP · CONFIRM',
      actions: [
        parchmentButton(
          'PREPARE FISH · 1 TIME',
          game.prepareFishBlockReason(id) == null
              ? () => Navigator.pop(context, true)
              : null,
          key: const ValueKey('confirm-prepare-fish'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1.5, child: FishingArt(fish.preparedId)),
          const SizedBox(height: 12),
          const Text(
            'Clean and cook the fish safely. The prepared portion is stored in Items, not eaten automatically.',
          ),
          const SizedBox(height: 12),
          const ParchmentLabel(
            'MATERIALS · HAVE / NEED',
            size: 11,
            color: ParchmentColors.muted,
          ),
          line(id, fish.name, '${game.state.availableResource(id)} / 1'),
          line(
            'wood',
            'Firewood',
            '${game.state.availableResource('wood')} / 1',
          ),
          if (fish.requiresKnife) line('stone_knife', 'Knife', 'REQUIRED'),
          const Divider(height: 20),
          line('sun', 'Daylight', '1 time'),
          const Text(
            'Other active conditions still take their normal time cost.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
