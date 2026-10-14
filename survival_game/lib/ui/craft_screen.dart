import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import 'parchment_craft_screen.dart';

/// Selection returns a recipe ID; camp owns the actual transaction.
class CraftScreen extends StatefulWidget {
  const CraftScreen({super.key, required this.game, this.showCamp = false});
  final GameEngine game;
  final bool showCamp;
  @override
  State<CraftScreen> createState() => _CraftScreenState();
}

class _CraftScreenState extends State<CraftScreen> {
  late bool camp = widget.showCamp;
  @override
  Widget build(BuildContext context) => ParchmentCraftScreen(
    game: widget.game,
    showCamp: camp,
    onCraft: () => setState(() => camp = false),
    onCamp: () => setState(() => camp = true),
  );
}
