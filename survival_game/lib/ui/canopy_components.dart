import '../analytics/analytics_ui.dart';
import 'condition_strip.dart';
import 'package:flutter/material.dart';
import '../feedback/haptics_scope.dart';

import '../game/run_state.dart';
import 'action_card.dart';
import 'camp_widgets.dart';
import 'canopy_theme.dart';
import 'card_art.dart';
import 'scene_artwork.dart';
import 'parchment_components.dart';

/// Keeps controls at the bottom, and scrolls naturally when text grows.
/// Avoid a page-wide intrinsic-height calculation: card widths are capped,
/// so their actual text wrapping must determine the scroll content height.
class CanopySceneBody extends StatelessWidget {
  const CanopySceneBody({
    super.key,
    required this.header,
    required this.footer,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget header, footer;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, const SizedBox(height: 140), footer],
          ),
        ),
      ),
    ),
  );
}

class CanopyHud extends StatelessWidget {
  const CanopyHud({super.key, required this.state});
  final RunState state;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final night = state.phase == RunPhase.night;
    final day = CampPanel(
      padding: const EdgeInsets.all(7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!night && state.weather != 'Sunny')
            Icon(
              state.weather == 'Storm'
                  ? Icons.thunderstorm_rounded
                  : Icons.water_drop_rounded,
              color: CanopyColors.water,
              size: 24,
            )
          else
            CardArt(night ? 'moon' : 'sun', size: 24),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DAY ${state.day}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  night ? 'Night' : state.weather,
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  '${state.timeLeft}/${RunState.dayLength} time',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CanopyColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < SurvivalStat.values.length; i += large ? 2 : 4) ...[
          if (i > 0) const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = i; j < i + (large ? 2 : 4); j++) ...[
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
        const SizedBox(height: 4),
        ResourceStrip(state: state),
        if (state.conditions.isNotEmpty) ...[
          const SizedBox(height: 4),
          ConditionStrip(state: state),
        ],
      ],
    );
    return large
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              right,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: day),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 88, child: day),
              const SizedBox(width: 6),
              Expanded(child: right),
            ],
          );
  }
}

class CanopyBackdrop extends StatelessWidget {
  const CanopyBackdrop({
    super.key,
    required this.child,
    required this.background,
    this.dark = false,
    this.alignment = Alignment.center,
    this.imageTop = 0,
    this.tint,
    this.foregroundBuilder,
  });
  final Widget child;
  final String background;
  final bool dark;
  final Alignment alignment;
  final double imageTop;
  final Color? tint;
  final Widget Function(BuildContext context, Rect artworkRect)?
  foregroundBuilder;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: CanopyColors.background),
      Positioned.fill(
        top: imageTop,
        child: SceneArtwork(
          asset: background,
          alignment: alignment,
          tint: tint,
          foregroundBuilder: foregroundBuilder,
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(dark ? 0x8810232E : 0x66102926),
              Colors.transparent,
              const Color(0xBB102926),
            ],
            stops: const [0, .45, 1],
          ),
        ),
      ),
      child,
    ],
  );
}

class CanopyTitle extends StatelessWidget {
  const CanopyTitle({
    super.key,
    required this.title,
    this.art = 'journal',
    this.subtitle,
  });
  final String title, art;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CardArt(art, size: 28),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: CanopyColors.muted),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class CanopyDialog extends StatelessWidget {
  const CanopyDialog({
    super.key,
    required this.title,
    required this.child,
    this.art = 'journal',
    this.actions = const [],
    this.subtitle,
  });
  final String title, art;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final scrollActions = MediaQuery.sizeOf(context).height < 500;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // CampPanel supplies the single visible frame. The themed Dialog shape
      // would otherwise draw a second border behind the scrollable content.
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 368,
          maxHeight:
              MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom -
              48,
        ),
        child: CampPanel(
          padding: const EdgeInsets.all(7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CanopyTitle(
                      title: title,
                      art: art,
                      subtitle: subtitle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CanopyDialogCloseButton(),
                ],
              ),
              const Divider(height: 14, color: CanopyColors.border),
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('dialog-content-scroll'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      child,
                      if (scrollActions && actions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        CardDeck(
                          cards: [
                            for (final action in actions)
                              if (action is ActionCard)
                                parchmentButton(
                                  action.title.toUpperCase(),
                                  action.onTap,
                                  key: action.key,
                                )
                              else
                                action,
                          ],
                          columns: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!scrollActions && actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                CardDeck(
                  cards: [
                    for (final action in actions)
                      if (action is ActionCard)
                        parchmentButton(
                          action.title.toUpperCase(),
                          action.onTap,
                          key: action.key,
                        )
                      else
                        action,
                  ],
                  columns: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CanopyDialogCloseButton extends StatelessWidget {
  const CanopyDialogCloseButton({super.key});

  @override
  Widget build(BuildContext context) => ParchmentClose(
    key: const ValueKey('close-dialog'),
    onPressed: () {
      HapticsScope.of(context)?.tap();
      Navigator.pop(context);
    },
  );
}

class CanopyConfirmation extends StatelessWidget {
  const CanopyConfirmation({
    super.key,
    required this.title,
    required this.message,
    required this.confirm,
    this.cancel = 'Stay',
    this.destructive = false,
    this.art = 'back',
    this.confirmKey,
  });
  final String title, message, confirm, cancel, art;
  final bool destructive;
  final Key? confirmKey;
  @override
  Widget build(BuildContext context) => CanopyDialog(
    title: title,
    art: art,
    actions: [
      ActionCard(
        title: cancel,
        art: 'back',
        tone: CardTone.river,
        horizontal: true,
        onTap: () => Navigator.pop(context, false),
      ),
      ActionCard(
        key: confirmKey,
        title: confirm,
        art: art,
        horizontal: true,
        tone: destructive ? CardTone.danger : CardTone.river,
        onTap: () => Navigator.pop(context, true),
      ),
    ],
    child: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
  );
}

class CanopyShortcut extends StatelessWidget {
  const CanopyShortcut({
    super.key,
    required this.label,
    required this.art,
    required this.onPressed,
  });
  final String label, art;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => AnalyticsTarget(
    'shortcut:$art',
    child: OutlinedButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticsScope.of(context)?.tap();
              onPressed!();
            },
      style: OutlinedButton.styleFrom(
        backgroundColor: CanopyColors.panel.withValues(alpha: .96),
        foregroundColor: CanopyColors.cream,
        side: const BorderSide(color: CanopyColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: const Size(52, 52),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardArt(art, size: 26),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}
