import 'package:flutter/material.dart';
import '../game/run_state.dart';
import 'ecology_art.dart';
import 'parchment_components.dart';

class ConditionStrip extends StatelessWidget {
  const ConditionStrip({super.key, required this.state});
  final RunState state;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 5,
    runSpacing: 4,
    children: [
      for (final condition in state.conditions)
        Semantics(
          label: '${condition.label}, ${condition.remaining} time remaining',
          button: true,
          child: InkWell(
            key: ValueKey('condition-${condition.kind.name}'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: PaperSurface(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ParchmentLabel(
                                  condition.label.toUpperCase(),
                                  size: 18,
                                ),
                              ),
                              ParchmentClose(
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ParchmentLabel(
                            '${condition.remaining} time remaining',
                            size: 13,
                          ),
                          const SizedBox(height: 12),
                          ParchmentLabel(
                            condition.description,
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                          const SizedBox(height: 12),
                          const ParchmentLabel(
                            'Time passes only when you act. Reading and opening menus are safe.',
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: PaperSurface(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: EcologyArt(condition.kind.name, icon: true),
                    ),
                    const SizedBox(width: 3),
                    ParchmentLabel(
                      '${condition.kind == ConditionKind.poisoned && condition.severity == 2 ? 'II · ' : ''}${condition.remaining}',
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
