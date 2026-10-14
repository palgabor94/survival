import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/ruins_puzzle.dart';
import 'action_card.dart';
import 'canopy_theme.dart';
import 'scene_layout.dart';

const _symbols = [
  Icons.wb_sunny_rounded,
  Icons.waves_rounded,
  Icons.eco_rounded,
  Icons.nights_stay_rounded,
];

class RuinsPuzzleScreen extends StatefulWidget {
  const RuinsPuzzleScreen({super.key, required this.game});
  final GameEngine game;

  @override
  State<RuinsPuzzleScreen> createState() => _RuinsPuzzleScreenState();
}

class _RuinsPuzzleScreenState extends State<RuinsPuzzleScreen> {
  @override
  Widget build(BuildContext context) {
    final puzzle = widget.game.ruinsPuzzle!;
    return SceneLayout(
      state: widget.game.state,
      background: 'assets/art/ancient_ruins_camp_style_v1.png',
      panel: SituationPanel(
        eyebrow: 'ANCIENT RUINS · STONE SEAL',
        title: 'Align the carved sequence',
        description:
            'Turn each stone disc to match the sequence carved above the altar. Choose Align to test the seal; each attempt uses 1 daylight. You can leave and return.',
        collapsedDescription: true,
        sceneArt: 2,
        extra: Semantics(
          label:
              'Carved sequence: ${puzzle.pattern.map((s) => RuinsPuzzle.symbolNames[s]).join(', ')}',
          child: ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final symbol in puzzle.pattern)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _symbols[symbol],
                        size: 24,
                        color: CanopyColors.gold,
                      ),
                      Text(
                        RuinsPuzzle.symbolNames[symbol],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      beforeCards: CardDeck(
        columns: 3,
        cards: [
          for (var i = 0; i < puzzle.tiles.length; i++)
            ActionCard(
              key: ValueKey('ruins-disc-$i'),
              title: RuinsPuzzle.symbolNames[puzzle.tiles[i]],
              description: 'Disc ${i + 1}',
              art: ['sun', 'water', 'fiber', 'moon'][puzzle.tiles[i]],
              tag: 'TURN',
              tone: CardTone.sand,
              compact: true,
              showStatus: true,
              horizontal: true,
              onTap: () => setState(() => widget.game.turnRuinsTile(i)),
            ),
        ],
      ),
      cards: [
        ActionCard(
          key: const ValueKey('ruins-submit'),
          asButton: true,
          title: 'Align the seal',
          description: '1 time',
          art: 'beacon_core',
          compact: true,
          horizontal: true,
          onTap: widget.game.state.timeLeft >= 1
              ? () => Navigator.pop(context, 'submit')
              : null,
        ),
        ActionCard(
          key: const ValueKey('ruins-leave'),
          asButton: true,
          title: 'Leave the altar',
          description: 'Return another time',
          art: 'back',
          tone: CardTone.river,
          compact: true,
          horizontal: true,
          onTap: () => Navigator.pop(context, 'leave'),
        ),
      ],
    );
  }
}
