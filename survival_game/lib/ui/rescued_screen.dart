import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import 'progression_screens.dart';

/// Retains the rescue route identity used by audio and navigation observers.
class RescuedScreen extends StatelessWidget {
  const RescuedScreen({super.key, required this.game});
  final GameEngine game;
  @override
  Widget build(BuildContext context) => RunResultScreen(game: game);
}
