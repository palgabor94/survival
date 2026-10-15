import '../game/tool_catalog.dart';
import 'tool_art.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../feedback/haptics_scope.dart';
import 'canopy_theme.dart';
import 'card_art.dart';
import 'card_illustration.dart';
import 'parchment_components.dart';

enum CardTone { leaf, sand, river, danger }

class CardLine {
  const CardLine(this.text, {this.color = CanopyColors.gold, this.icon});
  final String text;
  final Color color;
  final IconData? icon;
}

class ActionCard extends StatelessWidget {
  static const maxPortraitWidth = 112.0;
  static const illustrationAspectRatio = 1.5;
  const ActionCard({
    super.key,
    required this.title,
    this.icon = Icons.arrow_forward_rounded,
    this.description,
    this.image,
    this.art,
    this.artWidget,
    this.detailContent,
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
    this.confirmDetails = false,
    this.asButton = false,
    this.available,
  });
  final String title;
  final IconData icon;
  final String? description, image, art, tag;
  final Widget? artWidget, detailContent;
  final Color tagColor;
  final List<CardLine> lines;
  final VoidCallback? onTap;
  final bool horizontal, locked, selected, compact;
  final CardTone tone;
  final double? illustrationSize;
  final double? fixedHeight;
  final int? titleMaxLines, descriptionMaxLines;
  final bool showStatus, confirmDetails, asButton;
  final Map<String, int>? available;

  @override
  Widget build(BuildContext context) {
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(12) / 12,
    );
    final subject = art ?? artForIcon(icon);
    final details = confirmDetails;
    final unavailable = locked || onTap == null;
    void perform() {
      HapticsScope.of(context)?.tap();
      onTap?.call();
    }

    Future<void> activate() async {
      if (!details) {
        if (!unavailable) perform();
        return;
      }
      HapticsScope.of(context)?.tap();
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x8507130F),
        builder: (context) =>
            _ActionDetails(card: this, subject: subject, enabled: !unavailable),
      );
      if (confirmed == true && context.mounted && !unavailable) perform();
    }

    if (asButton) {
      return parchmentButton(title.toUpperCase(), unavailable ? null : perform);
    }
    if (horizontal) {
      return PaperSurface(
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: unavailable ? null : perform,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  artWidget ?? CardArt(subject, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ParchmentLabel(
                          title.toUpperCase(),
                          size: 13,
                          color: unavailable
                              ? ParchmentColors.muted
                              : ParchmentColors.ink,
                        ),
                        if (description != null)
                          ParchmentLabel(
                            description!,
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        for (final line in lines)
                          ParchmentLabel(
                            line.text,
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    unavailable
                        ? Icons.lock_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                    color: ParchmentColors.leaf,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final rawInfo = lines.isNotEmpty ? lines.first.text : description ?? '';
    final info = details
        ? 'View details'
        : rawInfo.length <= 24
        ? rawInfo
        : 'Tap to begin';
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: 112 * scale,
        height: 172 * scale,
        child: ParchmentCard(
          title: title,
          art: subject,
          image: image,
          artWidget: artWidget,
          info: info,
          status: unavailable && tag != 'OWNED'
              ? 'LOCKED'
              : tag ?? (tone == CardTone.danger ? 'RISKY' : 'READY'),
          selected: selected,
          onTap: activate,
        ),
      ),
    );
  }
}

class _ActionDetails extends StatelessWidget {
  const _ActionDetails({
    required this.card,
    required this.subject,
    required this.enabled,
  });
  final ActionCard card;
  final String subject;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: PaperSurface(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                child: Row(
                  children: [
                    if (fieldTools.containsKey(subject))
                      SizedBox(
                        width: 66,
                        height: 52,
                        child: ToolArt(subject, icon: true),
                      )
                    else
                      Image.asset(
                        card.image ??
                            cardIllustrationFor(subject) ??
                            'assets/art/card_trail_scene_v1.png',
                        width: 66,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ParchmentLabel(card.title.toUpperCase(), size: 19),
                    ),
                    ParchmentClose(onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (card.detailContent != null) ...[
                        card.detailContent!,
                        const SizedBox(height: 14),
                      ],
                      if (card.description != null) ...[
                        ParchmentLabel(
                          card.description!,
                          size: 14,
                          weight: FontWeight.w500,
                        ),
                        const SizedBox(height: 14),
                      ],
                      for (final line in card.lines)
                        if (line.text.contains('−1 time · −4 water · −3 food'))
                          _ExpeditionCosts(available: card.available)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                if (line.icon != null) ...[
                                  Icon(
                                    line.icon,
                                    color: ParchmentColors.ink,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: ParchmentLabel(
                                    line.text,
                                    size: 14,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      if (card.tag != null) ...[
                        const SizedBox(height: 12),
                        ParchmentLabel(
                          card.tag!,
                          size: 13,
                          color: card.tone == CardTone.danger
                              ? ParchmentColors.rust
                              : ParchmentColors.leaf,
                        ),
                      ],
                      if (!enabled) ...[
                        const SizedBox(height: 12),
                        const ParchmentLabel(
                          'This action is unavailable.',
                          size: 13,
                          color: ParchmentColors.rust,
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: parchmentButton(
                  enabled ? card.title.toUpperCase() : 'UNAVAILABLE',
                  enabled ? () => Navigator.pop(context, true) : null,
                  key: const ValueKey('confirm-card-action'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CardDeck extends StatelessWidget {
  const CardDeck({super.key, required this.cards, this.columns});
  final List<Widget> cards;
  final int? columns;
  @override
  Widget build(BuildContext context) {
    if (columns == 1 || cards.every((c) => c is ActionCard && c.horizontal)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: cards[i],
            ),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: cards,
    );
  }
}

class CardCarousel extends StatefulWidget {
  const CardCarousel({super.key, required this.cards});
  final List<Widget> cards;
  static double cardWidthFor(BuildContext context) =>
      112 * math.max(1.0, MediaQuery.textScalerOf(context).scale(12) / 12);
  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void page(double delta) {
    if (scroll.hasClients) {
      scroll.animateTo(
        (scroll.offset + delta).clamp(0, scroll.position.maxScrollExtent),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = CardCarousel.cardWidthFor(context);
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(12) / 12,
    );
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.cards.length * (width + 8) - 8 > constraints.maxWidth)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4, bottom: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: ParchmentLabel(
                      'SWIPE FOR MORE',
                      size: 11,
                      color: ParchmentColors.cream,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('choices-previous'),
                    tooltip: 'Previous choices',
                    onPressed: () => page(-width - 8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: ParchmentColors.cream,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('choices-next'),
                    tooltip: 'Next choices',
                    onPressed: () => page(width + 8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: ParchmentColors.cream,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 172 * scale,
            child: SingleChildScrollView(
              key: const ValueKey('event-choice-carousel'),
              controller: scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < widget.cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    SizedBox(width: width, child: widget.cards[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpeditionCosts extends StatelessWidget {
  const _ExpeditionCosts({this.available});
  final Map<String, int>? available;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ParchmentLabel(
        'COST TO CONTINUE',
        size: 11,
        color: ParchmentColors.muted,
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (art, value, label) in [
            ('sun', '1', 'TIME'),
            ('water', '4', 'WATER'),
            ('food', '3', 'FOOD'),
          ])
            Container(
              width: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: CanopyColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (art == 'sun')
                        const Icon(
                          Icons.schedule_rounded,
                          color: ParchmentColors.ink,
                          size: 22,
                        )
                      else
                        CardArt(art, size: 22),
                      const SizedBox(width: 7),
                      ParchmentLabel(value, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ParchmentLabel(label, size: 10),
                  if (available != null) ...[
                    const SizedBox(height: 5),
                    ParchmentLabel(
                      '${available![art == 'sun' ? 'time' : art]} available',
                      size: 10,
                      color: ParchmentColors.muted,
                      weight: FontWeight.w500,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    ],
  );
}
