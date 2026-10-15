import 'package:flutter/material.dart';
import '../game/tool_catalog.dart';

class ToolArt extends StatelessWidget {
  const ToolArt(this.id, {super.key, this.icon = false});
  final String id;
  final bool icon;
  @override
  Widget build(BuildContext context) {
    final ids = [
      'stone_axe',
      'reinforced_axe',
      'salvage_axe',
      'stone_spear',
      'hunting_spear',
      'salvage_spear',
    ];
    final cell = ids.indexOf(id);
    if (!fieldTools.containsKey(id)) return const SizedBox.shrink();
    const width = 1536.0, height = 1024.0;
    // The spear tips extend slightly above the nominal second row. Keep
    // that clear gutter with the spears, rather than the axe icons.
    final sourceY = icon ? (cell < 3 ? 0.0 : 480.0) : (cell ~/ 3) * height / 3;
    final cellHeight = icon ? (cell < 3 ? 480.0 : 544.0) : height / 3;
    return FittedBox(
      fit: icon ? BoxFit.contain : BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 512,
        height: cellHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.translate(
              offset: Offset(-(cell % 3) * 512, -sourceY),
              child: Image.asset(
                icon
                    ? 'assets/art/tool_icons_atlas_v1.png'
                    : 'assets/art/tools_atlas_v1.png',
                width: width,
                height: height,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
