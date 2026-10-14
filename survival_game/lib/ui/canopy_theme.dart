import 'package:flutter/material.dart';

/// Portrait scenes keep both horizontal edges visible on tall phones.
BoxFit sceneBackgroundFit(Size viewport) =>
    viewport.width <= viewport.height ? BoxFit.fitWidth : BoxFit.cover;

abstract final class CanopyColors {
  static const background = Color(0xFF102A28);
  static const panel = Color(0xFFF1E2BD);
  static const panelLight = Color(0xFFE6D6AE);
  static const cream = Color(0xFF203B31);
  static const muted = Color(0xFF68705A);
  static const gold = Color(0xFF294E36);
  static const border = Color(0xFFB7A981);
  static const health = Color(0xFFFF7862);
  static const water = Color(0xFF62D8ED);
  static const food = Color(0xFF9B5437);
  static const sanity = Color(0xFFD2A2F2);
  static const leaf = Color(0xFF294E36);
  static const workshop = Color(0xFFE2D2AA);
}

/// Scene navigation keeps the artwork in place instead of sliding pages.
class CanopyPageTransitionsBuilder extends PageTransitionsBuilder {
  const CanopyPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 140);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
      child: child,
    );
  }
}

final canopyTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: CanopyColors.background,
  colorScheme: const ColorScheme.light(
    primary: CanopyColors.gold,
    onPrimary: Color(0xFFFFF0CC),
    secondary: CanopyColors.leaf,
    surface: CanopyColors.panel,
    onSurface: CanopyColors.cream,
    error: CanopyColors.health,
  ),
  fontFamily: 'Arial',
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: const CanopyPageTransitionsBuilder(),
    },
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, height: 1.4),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
  ).apply(bodyColor: CanopyColors.cream, displayColor: CanopyColors.cream),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      textStyle: const TextStyle(
        fontFamily: 'Arial',
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: CanopyColors.cream,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: CanopyColors.cream,
      textStyle: const TextStyle(
        fontFamily: 'Arial',
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: CanopyColors.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(color: CanopyColors.border, width: 2),
    ),
  ),
);
