import 'package:flutter/material.dart';

import '../game/crafting.dart';
import '../game/game_engine.dart';
import '../game/run_state.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';

class RescuedScreen extends StatelessWidget {
  const RescuedScreen({super.key, required this.game});
  final GameEngine game;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: CanopyBackdrop(
        background: 'assets/art/rescue_arrival_camp_style_v1.png',
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: CanopySceneBody(
                header: const CampPanel(
                  child: Column(
                    children: [
                      Text(
                        'RESCUED',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: CanopyColors.gold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You kept the signal alive. Help has arrived.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                footer: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CampPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'YOUR JOURNEY',
                            style: TextStyle(
                              color: CanopyColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _line('Days survived', '${game.state.day}'),
                          _line(
                            'Final camp',
                            campTierName(game.recipes, game.state.campTier),
                          ),
                          _line(
                            'Beacon components found',
                            '${game.state.foundComponents.length}/5',
                          ),
                          _line(
                            'Storm challenges survived',
                            '${game.state.rescueStep}/3',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              for (final stat in SurvivalStat.values)
                                Text(
                                  '${stat.label} ${game.state.value(stat)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ActionCard(
                      key: const ValueKey('rescue-new-run'),
                      title: 'New run',
                      art: 'shelter',
                      horizontal: true,
                      tone: CardTone.river,
                      onTap: () async {
                        final restart = await showDialog<bool>(
                          context: context,
                          builder: (context) => const CanopyConfirmation(
                            title: 'Begin a new journey?',
                            message:
                                'Your successful run will be replaced by a fresh start.',
                            confirm: 'New run',
                            cancel: 'Keep summary',
                            art: 'shelter',
                            confirmKey: ValueKey('confirm-rescue-new-run'),
                          ),
                        );
                        if (restart == true && context.mounted) {
                          Navigator.pop(context, 'restart');
                        }
                      },
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

  Widget _line(String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 2,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 12, color: CanopyColors.muted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
