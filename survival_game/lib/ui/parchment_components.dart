import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'card_illustration.dart';
import 'card_art.dart';
import 'ecology_art.dart';
import 'fishing_art.dart';

abstract final class ParchmentColors {
  static const ink = Color(0xFF203B31),
      leaf = Color(0xFF294E36),
      muted = Color(0xFF68705A),
      rust = Color(0xFF8F4E37),
      cream = Color(0xFFFFF0CC);
}

class PaperSurface extends StatelessWidget {
  const PaperSurface({super.key, required this.child, this.selected = false});
  final Widget child;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF1E2BD),
      image: const DecorationImage(
        image: AssetImage('assets/art/ui_parchment_texture.png'),
        fit: BoxFit.cover,
        opacity: .75,
      ),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: selected ? ParchmentColors.leaf : const Color(0xFFB7A981),
        width: 2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class ParchmentLabel extends StatelessWidget {
  const ParchmentLabel(
    this.text, {
    super.key,
    this.size = 14,
    this.color = ParchmentColors.ink,
    this.align = TextAlign.left,
    this.weight = FontWeight.w800,
  });
  final String text;
  final double size;
  final Color color;
  final TextAlign align;
  final FontWeight weight;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
    ),
  );
}

class ParchmentClose extends StatelessWidget {
  const ParchmentClose({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Close',
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: ParchmentColors.ink,
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: ParchmentColors.leaf),
    ),
    icon: const Icon(Icons.close_rounded),
  );
}

Widget parchmentButton(
  String label,
  VoidCallback? action, {
  bool secondary = false,
  Key? key,
}) => FilledButton(
  key: key,
  onPressed: action,
  style: FilledButton.styleFrom(
    backgroundColor: secondary ? const Color(0xFFE6D6AE) : ParchmentColors.leaf,
    foregroundColor: secondary ? ParchmentColors.ink : ParchmentColors.cream,
    disabledBackgroundColor: const Color(0xFFD3C7A7),
    disabledForegroundColor: ParchmentColors.muted,
    minimumSize: const Size(44, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
  ),
  child: Text(
    label,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
  ),
);

/// Every parchment card reserves the same title, art, info and status slots.
/// At larger system text sizes all cards grow together; never by content.
class ParchmentCard extends StatelessWidget {
  const ParchmentCard({
    super.key,
    required this.title,
    required this.art,
    required this.status,
    required this.onTap,
    this.info = '',
    this.selected = false,
    this.image,
    this.artWidget,
  });
  final String? image;
  final Widget? artWidget;
  final String title, art, info, status;
  final VoidCallback? onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(12) / 12,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $status. View details',
      child: PaperSurface(
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                SizedBox(
                  height: 32 * scale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: ParchmentLabel(
                        title.toUpperCase(),
                        size: 10,
                        align: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1.5,
                  child:
                      artWidget ??
                      (hasFishingArt(art) && image == null
                          ? FishingArt(art)
                          : hasEcologyArt(art) && image == null
                          ? EcologyArt(art)
                          : Image.asset(
                              image ??
                                  cardIllustrationFor(art) ??
                                  'assets/art/card_trail_scene_v1.png',
                              fit: BoxFit.cover,
                            )),
                ),
                SizedBox(
                  height: 22 * scale,
                  child: Center(
                    child: ParchmentLabel(
                      info,
                      size: 9,
                      color: ParchmentColors.muted,
                    ),
                  ),
                ),
                Container(
                  height: 26 * scale,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  color: ['LOCKED', 'MISSING', 'EMPTY'].contains(status)
                      ? ParchmentColors.rust
                      : ParchmentColors.leaf,
                  child: ParchmentLabel(
                    status,
                    size: 9,
                    color: ParchmentColors.cream,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ParchmentCardGrid extends StatelessWidget {
  const ParchmentCardGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(12) / 12,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final child in children)
          SizedBox(width: 112 * scale, height: 172 * scale, child: child),
      ],
    );
  }
}

/// A menu entry uses one shared group frame, as in the approved menu plan.
class ParchmentMenuRow extends StatelessWidget {
  const ParchmentMenuRow({
    super.key,
    required this.title,
    required this.art,
    required this.onTap,
    this.trailing = '›',
  });
  final String title, art, trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            CardArt(art, size: 26),
            const SizedBox(width: 8),
            Expanded(child: ParchmentLabel(title, size: 13)),
            const SizedBox(width: 8),
            ParchmentLabel(trailing, size: 13, color: ParchmentColors.muted),
          ],
        ),
      ),
    ),
  );
}

class ParchmentSetting extends StatelessWidget {
  const ParchmentSetting({
    super.key,
    required this.title,
    required this.enabled,
    required this.onEnabled,
    this.value,
    this.onVolume,
    this.switchKey,
    this.sliderKey,
  });
  final String title;
  final bool enabled;
  final ValueChanged<bool>? onEnabled;
  final double? value;
  final ValueChanged<double>? onVolume;
  final Key? switchKey, sliderKey;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(child: ParchmentLabel(title, size: 13)),
          if (value != null)
            ParchmentLabel(
              '${(value! * 100).round()}%',
              size: 12,
              color: ParchmentColors.muted,
            ),
          const SizedBox(width: 8),
          Switch(
            key: switchKey,
            value: enabled,
            onChanged: onEnabled,
            activeThumbColor: ParchmentColors.cream,
            activeTrackColor: ParchmentColors.leaf,
            inactiveThumbColor: const Color(0xFFE6D6AE),
            inactiveTrackColor: const Color(0xFFC3B58F),
          ),
        ],
      ),
      if (value != null)
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: ParchmentColors.leaf,
              inactiveTrackColor: Color(0xFFC3B58F),
              thumbColor: ParchmentColors.leaf,
            ),
            child: Slider(
              key: sliderKey,
              label: '${(value! * 100).round()}%',
              value: value!,
              onChanged: enabled ? onVolume : null,
            ),
          ),
        ),
    ],
  );
}
