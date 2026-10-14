import 'package:flutter/material.dart';
import '../feedback/haptics_scope.dart';

import 'canopy_theme.dart';
import 'card_art.dart';
import 'card_illustration.dart';

enum CardTone { leaf, sand, river, danger }

class CardLine {
  const CardLine(this.text, {this.color = CanopyColors.gold, this.icon});
  final String text;
  final Color color;
  final IconData? icon;
}

/// One shared silhouette for actions, recipes, upgrades and popup choices.
class ActionCard extends StatelessWidget {
  static const maxPortraitWidth = 160.0;
  static const illustrationAspectRatio = 3 / 2;

  const ActionCard({
    super.key,
    required this.title,
    this.icon = Icons.arrow_forward_rounded,
    this.description,
    this.image,
    this.art,
    this.artWidget,
    this.tag,
    this.tagColor = CanopyColors.leaf,
    this.lines = const [],
    this.onTap,
    this.horizontal = false,
    this.tone = CardTone.leaf,
    this.locked = false,
    this.selected = false,
    this.compact = false,
    this.illustrationSize,
    this.fixedHeight,
    this.titleMaxLines,
    this.descriptionMaxLines,
    this.showStatus = true,
  });
  final String title;
  final IconData icon;
  final String? description, image, art, tag;
  final Widget? artWidget;
  final Color tagColor;
  final List<CardLine> lines;
  final VoidCallback? onTap;
  final bool horizontal, locked, selected, compact;
  final CardTone tone;
  final double? illustrationSize;
  final double? fixedHeight;
  final int? titleMaxLines, descriptionMaxLines;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final haptics = HapticsScope.of(context);
    final VoidCallback? activate = onTap == null
        ? null
        : () {
            haptics?.tap();
            onTap!();
          };
    final unavailable = locked || onTap == null;
    final (top, bottom, rim) = switch (tone) {
      CardTone.leaf => (
        const Color(0xFF507E36),
        const Color(0xFF203F2B),
        const Color(0xFFB5D480),
      ),
      CardTone.sand => (
        const Color(0xFFB28C55),
        const Color(0xFF65492F),
        const Color(0xFFE5C68D),
      ),
      CardTone.river => (
        const Color(0xFF4B8196),
        const Color(0xFF22485C),
        const Color(0xFFADD9E1),
      ),
      CardTone.danger => (
        const Color(0xFF985744),
        const Color(0xFF612F29),
        const Color(0xFFE1A088),
      ),
    };
    final border = unavailable
        ? CanopyColors.border
        : (selected ? CanopyColors.cream : rim);
    final illustrationHeight = horizontal ? 64.0 : (compact ? 80.0 : 104.0);
    final footerColor = unavailable
        ? const Color(0xFFB4B9A8)
        : switch (tone) {
            CardTone.leaf => const Color(0xFFC5DF98),
            CardTone.sand => const Color(0xFFE5CD9F),
            CardTone.river => const Color(0xFFBBDDE0),
            CardTone.danger => const Color(0xFFE4B9A4),
          };
    final footerInk = horizontal ? CanopyColors.cream : const Color(0xFF243D2A);
    final subject = art ?? artForIcon(icon);
    final illustrationPath = image ?? cardIllustrationFor(subject);
    final rawIllustration = SizedBox(
      height: illustrationHeight,
      width: horizontal ? 64 * illustrationAspectRatio : double.infinity,
      child: ClipRRect(
        borderRadius: horizontal ? BorderRadius.circular(9) : BorderRadius.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: top,
                image: const DecorationImage(
                  image: AssetImage('assets/art/card_foliage_backdrop_v1.png'),
                  fit: BoxFit.cover,
                  // Dim only the foliage; keep the foreground object vivid.
                  colorFilter: ColorFilter.mode(
                    Color(0x5A000000),
                    BlendMode.srcOver,
                  ),
                ),
              ),
            ),
            if (artWidget != null)
              artWidget!
            else if (illustrationPath != null)
              Image.asset(
                illustrationPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                cacheWidth: 720,
                cacheHeight: 480,
                errorBuilder: (context, error, stackTrace) =>
                    CardArt(subject, size: 160),
              )
            else
              Padding(
                padding: const EdgeInsets.all(4),
                child: CardArt(
                  // A pile reads clearly in the large card illustration;
                  // small HUD resource icons still use the single log.
                  !horizontal && subject == 'wood' ? 'firewood' : subject,
                  size: illustrationSize ?? (horizontal ? 64 : 160),
                ),
              ),
          ],
        ),
      ),
    );
    final illustration = unavailable
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              .2126,
              .7152,
              .0722,
              0,
              0,
              .2126,
              .7152,
              .0722,
              0,
              0,
              .2126,
              .7152,
              .0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: rawIllustration,
          )
        : rawIllustration;
    final status = unavailable && tag != 'OWNED' ? 'LOCKED' : tag;
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          title.toUpperCase(),
          maxLines: titleMaxLines,
          overflow: titleMaxLines == null ? null : TextOverflow.ellipsis,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 12 : 15,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: .2,
            color: footerInk,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            maxLines: descriptionMaxLines,
            overflow: descriptionMaxLines == null
                ? null
                : TextOverflow.ellipsis,
            textAlign: horizontal ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              fontSize: horizontal ? 12 : 11,
              height: 1.2,
              color: footerInk,
            ),
          ),
        ],
        for (final line in lines) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (line.icon != null) ...[
                Icon(
                  line.icon,
                  size: 14,
                  color: horizontal ? line.color : footerInk,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  line.text,
                  textAlign: horizontal ? TextAlign.start : TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: horizontal ? line.color : footerInk,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showStatus && (tag != null || unavailable)) ...[
          const SizedBox(height: 7),
          Container(
            width: horizontal ? null : double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: horizontal ? Colors.black26 : bottom,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (unavailable ? CanopyColors.muted : tagColor).withValues(
                  alpha: .55,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (unavailable && tag != 'OWNED') ...[
                  const Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: CanopyColors.muted,
                  ),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    status!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: horizontal
                          ? (unavailable ? CanopyColors.muted : tagColor)
                          : CanopyColors.cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    final card = Semantics(
      button: true,
      enabled: onTap != null,
      onTap: activate,
      selected: selected,
      label: [
        title,
        ?tag,
        ?description,
        for (final l in lines) l.text,
        if (unavailable) 'unavailable',
      ].join('. '),
      child: SizedBox(
        height: fixedHeight,
        child: ExcludeSemantics(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: unavailable ? CanopyColors.panelLight : bottom,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: border, width: selected ? 3 : 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: activate,
                child: Padding(
                  padding: horizontal
                      ? const EdgeInsets.all(6)
                      : EdgeInsets.zero,
                  child: horizontal
                      ? Row(
                          children: [
                            illustration,
                            const SizedBox(width: 10),
                            Expanded(child: details),
                          ],
                        )
                      : fixedHeight != null
                      ? Column(
                          children: [
                            AspectRatio(
                              aspectRatio: illustrationAspectRatio,
                              child: illustration,
                            ),
                            Expanded(
                              child: ColoredBox(
                                color: footerColor,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: details,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: illustrationAspectRatio,
                                child: illustration,
                              ),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    minHeight: illustrationHeight,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  color: footerColor,
                                  child: Center(child: details),
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
      ),
    );
    final cappedCard = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: horizontal ? 320 : maxPortraitWidth,
      ),
      child: card,
    );
    // Deck and carousel slots already cap the width. Preserve their tight
    // height so every surface fills the tallest card instead of centering
    // a shorter surface inside the equally sized slot.
    if (context.dependOnInheritedWidgetOfExactType<_EqualHeightCards>() !=
        null) {
      return cappedCard;
    }
    // Standalone cards still need to loosen a full-width parent slot.
    return Align(widthFactor: 1, heightFactor: 1, child: cappedCard);
  }
}

class _EqualHeightCards extends InheritedWidget {
  const _EqualHeightCards({required super.child});

  @override
  bool updateShouldNotify(_EqualHeightCards oldWidget) => false;
}

/// Equal rows, with a vertical alternative for large text and small widths.
class CardDeck extends StatelessWidget {
  const CardDeck({super.key, required this.cards, this.columns});
  final List<Widget> cards;
  final int? columns;
  @override
  Widget build(BuildContext context) {
    final large =
        MediaQuery.textScalerOf(context).scale(14) > 19 ||
        MediaQuery.sizeOf(context).width < 360;
    final count = large
        ? 1
        : (columns ?? (cards.length == 4 ? 2 : cards.length.clamp(1, 3)));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i += count)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            // A single card must measure at its capped width. An intrinsic
            // row can predict a shorter height before the width cap applies,
            // clipping wrapped costs and requirements at large text sizes.
            child: count == 1
                ? cards[i]
                : Align(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            count * ActionCard.maxPortraitWidth +
                            (count - 1) * 8,
                      ),
                      child: _EqualHeightCards(
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var j = i; j < i + count; j++) ...[
                                if (j > i) const SizedBox(width: 8),
                                Expanded(
                                  child: j < cards.length
                                      ? cards[j]
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

/// One natural-height row, fitting as many readable cards as the width allows.
class CardCarousel extends StatefulWidget {
  const CardCarousel({super.key, required this.cards});
  final List<Widget> cards;

  static double cardWidthFor(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width.clamp(24.0, 560.0) - 24;
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final count = ((available + 8) / 120).floor().clamp(1, 4);
    final width = large ? available : (available - 8 * (count - 1)) / count;
    return width.clamp(0.0, ActionCard.maxPortraitWidth);
  }

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _page(double step) {
    if (!_scroll.hasClients) return;
    final target = (_scroll.offset + step).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width.clamp(0.0, 560.0) - 24;
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final visibleCount = ((available + 8) / 120).floor().clamp(1, 4);
    final width = CardCarousel.cardWidthFor(context);
    final step = width + 8;
    return Semantics(
      container: true,
      label: 'Event choices. Swipe or use the arrows to browse.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (large || widget.cards.length > visibleCount)
            AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) {
                final attached =
                    _scroll.hasClients && _scroll.position.hasContentDimensions;
                final offset = attached ? _scroll.offset : 0.0;
                final canGoBack = offset > 1;
                final canGoNext = !attached
                    ? widget.cards.length > 1
                    : offset < _scroll.position.maxScrollExtent - 1;
                final index = (offset / step).round().clamp(
                  0,
                  widget.cards.length - 1,
                );
                return Row(
                  children: [
                    IconButton(
                      key: const ValueKey('encounter-previous'),
                      tooltip: 'Previous choice',
                      onPressed: canGoBack ? () => _page(-step) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'SWIPE · ${index + 1} / ${widget.cards.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: CanopyColors.cream,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('encounter-next'),
                      tooltip: 'Next choice',
                      onPressed: canGoNext ? () => _page(step) : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                );
              },
            ),
          SingleChildScrollView(
            key: const ValueKey('encounter-card-rail'),
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: _EqualHeightCards(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      SizedBox(width: width, child: widget.cards[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
