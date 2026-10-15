import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../game/run_state.dart';
import '../game/tutorial_progress.dart';
import 'canopy_components.dart';
import 'parchment_components.dart';

const firstDayLessons = <String, (String, String)>{
  'gather': (
    'Gather something to eat',
    'Choose FORAGE, open a card and confirm your choice. Gathering puts food in Items; it does not feed you yet.',
  ),
  'eat': (
    'Eat what you found',
    'Open ITEMS and choose a safe food, such as Ember Berries. Eating uses a portion; the outcome shows what changed.',
  ),
  'craft': (
    'Make your first tool',
    'Open CRAFT and inspect Torch. If materials are missing, gather more or explore; nothing is spent until you confirm.',
  ),
  'pack': (
    'Pack for a short trip',
    'Open MAP and choose Riverbank. Pack supplies and a usable tool, then confirm departure. Storage stays at camp; gear uses no item slots.',
  ),
  'return': (
    'Bring your supplies home',
    'At an expedition stop choose RETURN TO CAMP. Your carried supplies unload automatically; returning costs no extra daylight.',
  ),
  'night': (
    'Survive the first night',
    'Spend the remaining daylight on useful actions or REST. Resolve the night event, then SLEEP and read your day summary.',
  ),
};

class FirstDayWelcome extends StatelessWidget {
  const FirstDayWelcome({super.key});
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: 'Your first day',
    art: 'journal',
    subtitle: 'LEARN BY SURVIVING',
    actions: [
      parchmentButton(
        'GUIDE MY FIRST DAY',
        () => Navigator.pop(context, true),
        key: const ValueKey('accept-first-day'),
      ),
      parchmentButton(
        'PLAY WITHOUT HELP',
        () => Navigator.pop(context, false),
        secondary: true,
        key: const ValueKey('skip-first-day'),
      ),
    ],
    child: const ParchmentLabel(
      'Find food, make a tool and bring supplies home before nightfall. Your long-term goal is to build a rescue signal.\n\nWould you like a short guide while you play?',
      weight: FontWeight.w500,
    ),
  );
}

/// Lives in the layout, above its controls, rather than obscuring their hit
/// areas. The bounded scroll area also works with large text and landscape.
class FirstDayCoach extends StatefulWidget {
  const FirstDayCoach({super.key, required this.game, this.place = 'camp'});
  final GameEngine game;
  final String place;
  @override
  State<FirstDayCoach> createState() => _FirstDayCoachState();
}

class _FirstDayCoachState extends State<FirstDayCoach> {
  @override
  void initState() {
    super.initState();
    widget.game.addListener(refresh);
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.game.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game, t = g.tutorial;
    if (!t.active || g.report != null) return const SizedBox.shrink();
    final id = widget.place == 'expedition'
        ? 'return'
        : widget.place == 'packing'
        ? 'pack'
        : widget.place == 'craft'
        ? 'craft'
        : widget.place == 'items'
        ? 'eat'
        : widget.place == 'night'
        ? 'night'
        : t.next;
    if (widget.place != 'camp' && t.completed.contains(id)) {
      return const SizedBox.shrink();
    }
    final (title, text) = firstDayLessons[id]!;
    return Padding(
      key: const ValueKey('first-day-coach'),
      padding: const EdgeInsets.only(bottom: 8),
      child: PaperSurface(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height < 500 ? 110 : 174,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: ParchmentLabel(
                            'FIRST-DAY GUIDE · ${t.completed.length}/6',
                            size: 11,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => g.collapseGuide(!t.collapsed),
                        child: Text(t.collapsed ? 'Show' : 'Later'),
                      ),
                    ],
                  ),
                  if (!t.collapsed) ...[
                    ParchmentLabel(title, size: 15),
                    const SizedBox(height: 4),
                    ParchmentLabel(
                      g.state.timeLeft == 0 && g.state.phase == RunPhase.day
                          ? 'Daylight is gone. Finish reading the outcome, resolve the night event and choose SLEEP. You can continue learning tomorrow.'
                          : text,
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('skip-active-guide'),
                        onPressed: g.skipGuide,
                        child: const Text('Skip guide'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FirstDayReference extends StatelessWidget {
  const FirstDayReference({super.key, required this.game});
  final GameEngine game;
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: 'First-day guide',
    art: 'journal',
    subtitle: 'YOUR SURVIVAL NOTES',
    actions: [
      if (game.tutorial.accepted && !game.tutorial.complete)
        parchmentButton('RESUME GUIDE', () {
          game.resumeGuide();
          Navigator.pop(context);
        }),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in TutorialProgress.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ParchmentLabel(
                  '${game.tutorial.completed.contains(id) ? '✓ Learned · ' : ''}${firstDayLessons[id]!.$1}',
                ),
                const SizedBox(height: 4),
                ParchmentLabel(
                  firstDayLessons[id]!.$2,
                  size: 13,
                  weight: FontWeight.w500,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class FirstDayComplete extends StatelessWidget {
  const FirstDayComplete({super.key});
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: 'You survived your first day',
    art: 'sun',
    subtitle: '6 / 6 LESSONS LEARNED',
    actions: [
      parchmentButton(
        'KEEP SURVIVING',
        () => Navigator.pop(context),
        key: const ValueKey('finish-first-day'),
      ),
    ],
    child: const ParchmentLabel(
      'You gathered food, ate, made a tool, packed a bag and returned home. You survived the night.\n\nKeep exploring, improve your shelter and work towards a rescue signal. Your survival notes remain in MENU → GUIDE.',
      weight: FontWeight.w500,
    ),
  );
}
