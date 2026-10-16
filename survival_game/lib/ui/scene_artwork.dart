import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'canopy_theme.dart';

/// Fits portrait art to the available width and blends exposed image edges
/// into the scene's backing color. UI children remain outside this mask.
class SceneArtwork extends StatelessWidget {
  const SceneArtwork({
    super.key,
    required this.asset,
    this.alignment = Alignment.center,
    this.tint,
    this.foregroundBuilder,
    this.edgeFade = 48,
    this.alwaysFadeEdges = false,
  });
  final String asset;
  final Alignment alignment;
  final Color? tint;
  final double edgeFade;
  final bool alwaysFadeEdges;

  /// Receives the full, uniformly scaled artwork rectangle, including any
  /// portion outside the viewport. Anchors therefore survive letterboxing.
  final Widget Function(BuildContext context, Rect artworkRect)?
  foregroundBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fit = sceneBackgroundFit(constraints.biggest);
      return Image.asset(
        asset,
        fit: fit,
        alignment: alignment,
        color: tint,
        colorBlendMode: tint == null ? null : BlendMode.multiply,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: CanopyColors.background),
        frameBuilder: (context, child, frame, synchronous) {
          if (child is! RawImage || child.image == null) return child;
          final source = Size(
            child.image!.width.toDouble(),
            child.image!.height.toDouble(),
          );
          final fitted = applyBoxFit(fit, source, constraints.biggest);
          Widget artwork = child;
          if (foregroundBuilder != null) {
            final scale = fitted.destination.width / fitted.source.width;
            final rect = alignment.inscribe(
              Size(source.width * scale, source.height * scale),
              Offset.zero & constraints.biggest,
            );
            artwork = Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: child),
                foregroundBuilder!(context, rect),
              ],
            );
          }
          if (!alwaysFadeEdges &&
              fitted.destination.height >= constraints.maxHeight - .5) {
            return artwork;
          }
          return ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) {
              final imageRect = alignment.inscribe(fitted.destination, bounds);
              final fade =
                  math.min(edgeFade, imageRect.height * .18) / imageRect.height;
              if (alwaysFadeEdges) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [
                    Colors.transparent,
                    Color(0x28FFFFFF),
                    Color(0x80FFFFFF),
                    Color(0xD7FFFFFF),
                    Colors.white,
                    Colors.white,
                    Color(0xD7FFFFFF),
                    Color(0x80FFFFFF),
                    Color(0x28FFFFFF),
                    Colors.transparent,
                  ],
                  stops: [
                    0,
                    fade * .25,
                    fade * .5,
                    fade * .75,
                    fade,
                    1 - fade,
                    1 - fade * .75,
                    1 - fade * .5,
                    1 - fade * .25,
                    1,
                  ],
                ).createShader(imageRect);
              }
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  alwaysFadeEdges || imageRect.top > bounds.top + .5
                      ? Colors.transparent
                      : Colors.white,
                  Colors.white,
                  Colors.white,
                  alwaysFadeEdges || imageRect.bottom < bounds.bottom - .5
                      ? Colors.transparent
                      : Colors.white,
                ],
                stops: [0, fade, 1 - fade, 1],
              ).createShader(imageRect);
            },
            child: artwork,
          );
        },
      );
    },
  );
}
