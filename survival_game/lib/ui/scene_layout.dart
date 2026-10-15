import 'package:flutter/material.dart';

import '../game/run_state.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_components.dart';
import 'canopy_theme.dart';
import 'card_art.dart';

class SceneLayout extends StatelessWidget {
  const SceneLayout({
    super.key,
    required this.state,
    required this.background,
    required this.panel,
    required this.cards,
    this.beforeCards,
    this.guide,
    this.backgroundAlignment = const Alignment(0, .1),
    this.dark = false,
    this.backgroundTint,
    this.backgroundTop = 0,
    this.cardCarousel = false,
    this.foregroundBuilder,
  });
  final RunState state;
  final String background;
  final Alignment backgroundAlignment;
  final bool dark;
  final Color? backgroundTint;
  final double backgroundTop;
  final Widget panel;
  final List<Widget> cards;
  final Widget? beforeCards;
  final Widget? guide;
  final bool cardCarousel;
  final Widget Function(BuildContext context, Rect artworkRect)?
  foregroundBuilder;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: CanopyBackdrop(
        background: background,
        dark: dark,
        tint: backgroundTint,
        alignment: backgroundAlignment,
        imageTop: backgroundTop,
        foregroundBuilder: foregroundBuilder,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: CanopySceneBody(
                header: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CanopyHud(state: state),
                    const SizedBox(height: 12),
                    panel,
                    if (guide != null) ...[const SizedBox(height: 8), guide!],
                  ],
                ),
                footer: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (beforeCards != null) ...[
                      beforeCards!,
                      const SizedBox(height: 8),
                    ],
                    if (cardCarousel)
                      CardCarousel(cards: cards)
                    else
                      CardDeck(cards: cards),
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

/// Kept for callers which only need the stats, using the same HUD tiles.
class SceneStats extends StatelessWidget {
  const SceneStats({super.key, required this.state, required this.columns});
  final RunState state;
  final int columns;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < SurvivalStat.values.length; i += columns) ...[
        if (i > 0) const SizedBox(height: 4),
        Row(
          children: [
            for (
              var j = i;
              j < i + columns && j < SurvivalStat.values.length;
              j++
            ) ...[
              if (j > i) const SizedBox(width: 4),
              Expanded(
                child: StatTile(
                  stat: SurvivalStat.values[j],
                  value: state.value(SurvivalStat.values[j]),
                ),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}

/// The situation card: where, what is happening, and what it will cost.
class SituationPanel extends StatelessWidget {
  const SituationPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.sceneArt,
    this.heroImage,
    this.note,
    this.extra,
    this.collapsedDescription = false,
  });
  final String eyebrow, title, description;
  final String? heroImage, note;
  final int sceneArt;
  final Widget? extra;
  final bool collapsedDescription;

  @override
  Widget build(BuildContext context) => CampPanel(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!collapsedDescription)
              SizedBox(
                width: 44,
                height: 44,
                child: heroImage == null
                    ? CardArt(
                        sceneArt == 1
                            ? 'forage'
                            : sceneArt == 3
                            ? 'torch'
                            : 'map',
                        size: 44,
                      )
                    : Image.asset(
                        heroImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const CardArt('trail', size: 44),
                      ),
              ),
            if (!collapsedDescription) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: .7,
                      color: CanopyColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (collapsedDescription)
              IconButton(
                key: const ValueKey('scene-details'),
                tooltip: 'Read the situation',
                icon: const Icon(Icons.info_outline_rounded, size: 22),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => CanopyDialog(
                    title: title,
                    art: sceneArt == 3 ? 'torch' : 'map',
                    subtitle: eyebrow,
                    child: Text(
                      description,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (!collapsedDescription) ...[
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, height: 1.35)),
        ],
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(
            note!,
            style: const TextStyle(fontSize: 12, color: CanopyColors.muted),
          ),
        ],
        if (extra != null) ...[const SizedBox(height: 8), extra!],
      ],
    ),
  );
}
