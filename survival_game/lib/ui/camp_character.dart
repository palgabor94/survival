import 'package:flutter/material.dart';

const starterCampSprites = [
  'assets/art/explorer_camp_fire_v2.png',
  'assets/art/explorer_camp_wood_v1.png',
  'assets/art/explorer_camp_craft_v1.png',
  'assets/art/explorer_camp_seated_v1.png',
  'assets/art/explorer_camp_inspect_v1.png',
];

String starterCampCharacter(int variant) =>
    starterCampSprites[variant % starterCampSprites.length];

const campSeatedRight = 'assets/art/explorer_camp_seated_right_v1.png';

String campCharacterArt(int tier, int variant) =>
    tier == 2 && variant % starterCampSprites.length == 3
    ? campSeatedRight
    : starterCampCharacter(variant);

/// Positions are registered to the supplied empty camp, not the phone screen.
/// Sprite canvas margins are preserved; the anchor marks its ground contact.
class CampCharacter extends StatelessWidget {
  const CampCharacter({
    super.key,
    required this.artworkRect,
    required this.variant,
    this.tint,
    this.animate = false,
    this.tier = 0,
  });
  final Rect artworkRect;
  final int variant;
  final Color? tint;
  final bool animate;
  final int tier;

  static const positionsByTier = [
    [
      Offset(.42, .69),
      Offset(.27, .615),
      Offset(.47, .72),
      Offset(.782, .593),
      Offset(.32, .69),
    ],
    [
      Offset(.42, .69),
      Offset(.29, .65),
      Offset(.48, .72),
      Offset(.755, .589),
      Offset(.34, .64),
    ],
    [
      Offset(.635, .80),
      Offset(.52, .68),
      Offset(.43, .733),
      Offset(.532, .752),
      Offset(.46, .635),
    ],
    [
      Offset(.57, .79),
      Offset(.66, .635),
      Offset(.43, .69),
      Offset(.13, .607),
      Offset(.39, .635),
    ],
  ];
  // Seated artwork fills more of its canvas with the head and torso. Scaling
  // by the same canvas width would make this pose a larger person.
  static const widths = [.31, .295, .22, .24, .30];
  static const anchors = [
    Offset(.55, .94),
    Offset(.52, .95),
    Offset(.5, .88),
    Offset(.66, .635),
    Offset(.55, .94),
  ];

  @override
  Widget build(BuildContext context) {
    final index = variant % starterCampSprites.length;
    final position = positionsByTier[tier][index];
    final rightSeated = tier == 2 && index == 3;
    final size = artworkRect.width * (rightSeated ? .25 : widths[index]);
    final anchor = rightSeated ? const Offset(.43, .635) : anchors[index];
    final ground = Offset(
      artworkRect.left + artworkRect.width * position.dx,
      artworkRect.top + artworkRect.height * position.dy,
    );
    final pose = Stack(
      key: ValueKey('camp-character-$tier-$index'),
      fit: StackFit.expand,
      children: [
        if (index != 3)
          Positioned(
            left: ground.dx - size * .17,
            top: ground.dy - size * .035,
            width: size * .34,
            height: size * .075,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x302D271B),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        Positioned(
          key: const ValueKey('camp-character-sprite'),
          left: ground.dx - size * anchor.dx,
          top: ground.dy - size * anchor.dy,
          width: size,
          height: size,
          child: Image.asset(
            campCharacterArt(tier, index),
            fit: BoxFit.contain,
            color: tint,
            // Modulate preserves the source alpha; multiply would paint the
            // tint across the sprite's otherwise transparent canvas at night.
            colorBlendMode: tint == null ? null : BlendMode.modulate,
            excludeFromSemantics: true,
          ),
        ),
      ],
    );
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: animate && !MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 650)
            : Duration.zero,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: pose,
      ),
    );
  }
}
