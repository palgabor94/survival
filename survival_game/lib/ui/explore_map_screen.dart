import '../analytics/analytics_ui.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../game/world_catalog.dart';
import 'action_card.dart';
import 'parchment_components.dart';
import 'card_art.dart';
import 'canopy_components.dart';

/// Calibrated against explore_map_world_v2.png, independently of travel rules.
const mapLandmarkAnchors = <String, Offset>{
  'bamboo_grove': Offset(.21, .235),
  'fishing_pond': Offset(.78, .26),
  'riverbank': Offset(.49, .408),
  'camp': Offset(.23, .55),
  'plane_wreck': Offset(.78, .55),
  'ancient_ruins': Offset(.76, .765),
  'mangrove_shallows': Offset(.23, .875),
};

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key, required this.game});
  final GameEngine game;
  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  String? selectedId;
  GameEngine get game => widget.game;
  @override
  Widget build(BuildContext context) {
    final place = selectedId == null ? null : game.world.find(selectedId!);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      _map(c.maxWidth, _mapHeight(c, place)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                        child: place == null
                            ? PaperSurface(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.touch_app_outlined,
                                        size: 22,
                                        color: ParchmentColors.leaf,
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: ParchmentLabel(
                                          'Tap a place on the map.',
                                          size: 13,
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _details(place),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final large = MediaQuery.textScalerOf(context).scale(12) > 18;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          PaperSurface(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.explore_outlined,
                    size: 22,
                    color: ParchmentColors.leaf,
                  ),
                  const SizedBox(width: 7),
                  ParchmentLabel('EXPLORE', size: large ? 13 : 18),
                ],
              ),
            ),
          ),
          PaperSurface(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ParchmentLabel('DAY ${game.state.day}', size: 11),
                  ParchmentLabel(
                    '${game.state.timeLeft}/6 time',
                    size: 10,
                    color: ParchmentColors.muted,
                  ),
                ],
              ),
            ),
          ),
          PaperSurface(
            child: IconButton(
              key: const ValueKey('map-close'),
              tooltip: 'Close map',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: ParchmentColors.ink),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
        ],
      ),
    );
  }

  double _mapHeight(BoxConstraints viewport, WorldLocation? place) {
    final natural = viewport.maxWidth * 1.5;
    if (viewport.maxHeight < 700 ||
        MediaQuery.textScalerOf(context).scale(12) > 18) {
      return natural;
    }
    var footer = 84.0;
    if (place != null) {
      footer = place.timeCost > 0 ? 191 : 160;
      final block = game.travelBlockReason(place.id);
      if (block != null) {
        final measure = TextPainter(
          text: TextSpan(
            text: block,
            style: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: viewport.maxWidth - 52);
        footer += measure.height + 7;
        measure.dispose();
      }
      if (place.id == 'fishing_pond' &&
          !game.state.tools.contains('basic_rod')) {
        footer += 54;
      }
    }
    return math.min(natural, math.max(320, viewport.maxHeight - 82 - footer));
  }

  Widget _map(double availableWidth, double height) {
    final width = height / 1.5;
    final selected = selectedId == null ? null : mapLandmarkAnchors[selectedId];
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/art/explore_map_world_v2.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF102A28),
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xFF102A28),
                        ],
                        stops: [0, .025, .975, 1],
                      ),
                    ),
                  ),
                ),
              ),
              if (selected != null)
                Positioned(
                  left: selected.dx * width - 38,
                  top: selected.dy * height - 45,
                  width: 76,
                  height: 38,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFB6D78A),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              for (final place in game.world.locations)
                _pin(place, width, height),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pin(WorldLocation place, double width, double height) {
    final anchor = mapLandmarkAnchors[place.id] ?? Offset(place.x, place.y);
    final selected = selectedId == place.id;
    final locked = !place.isUnlocked(game.state);
    final label = place.id == 'mangrove_shallows' ? 'Mangrove' : place.name;
    return Positioned(
      left: (anchor.dx * width - 59).clamp(2, math.max(2, width - 120)),
      top: anchor.dy * height - 58,
      width: 118,
      height: 100,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${place.name}${locked ? ', locked' : ''}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('map-node-${place.id}'),
            onTap: () {
              AnalyticsScope.of(context)?.track('map_destination_selected', {
                'destination': place.id,
                'locked': locked ? 1 : 0,
              });
              setState(() => selectedId = place.id);
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? ParchmentColors.leaf
                      : const Color(0xF0EFE0BA),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFB6D78A)
                        : const Color(0xFFB7A981),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x60000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (locked) ...[
                      Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: selected
                            ? ParchmentColors.cream
                            : ParchmentColors.muted,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (place.id == 'camp') ...[
                      Icon(
                        Icons.home_rounded,
                        size: 12,
                        color: selected
                            ? ParchmentColors.cream
                            : ParchmentColors.leaf,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: ParchmentLabel(
                        label,
                        size: 10,
                        color: selected
                            ? ParchmentColors.cream
                            : ParchmentColors.ink,
                        align: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(WorldLocation place) {
    final block = place.id == 'camp' ? null : game.travelBlockReason(place.id);
    final needsRod =
        place.id == 'fishing_pond' && !game.state.tools.contains('basic_rod');
    return PaperSurface(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CardArt(_art(place.id), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: ParchmentLabel(place.name.toUpperCase(), size: 17),
                ),
                IconButton(
                  key: const ValueKey('map-place-details'),
                  tooltip: 'Read about this place',
                  onPressed: () => showDialog<void>(
                    context: context,
                    routeSettings: const RouteSettings(name: 'canopy_dialog'),
                    builder: (_) => CanopyDialog(
                      title: place.name,
                      art: _art(place.id),
                      child: ParchmentLabel(
                        place.description,
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: ParchmentColors.leaf,
                    size: 21,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (block != null) ...[
              const SizedBox(height: 7),
              ParchmentLabel(
                block,
                size: 12,
                color: ParchmentColors.rust,
                weight: FontWeight.w500,
              ),
            ],
            if (place.timeCost > 0) ...[
              const SizedBox(height: 9),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _cost('time', '${place.timeCost} time'),
                  _cost('water', '−${place.timeCost * 4} Water'),
                  _cost('food', '−${place.timeCost * 3} Food'),
                ],
              ),
            ],
            const SizedBox(height: 10),
            ActionCard(
              key: const ValueKey('travel-destination'),
              asButton: true,
              horizontal: true,
              title: place.id == 'camp'
                  ? 'Back to camp'
                  : block != null
                  ? 'Location locked'
                  : place.id == 'fishing_pond'
                  ? 'Go fishing'
                  : 'Prepare pack · ${place.name}',
              art: _art(place.id),
              onTap: block != null
                  ? null
                  : place.id == 'camp'
                  ? () => Navigator.pop(context)
                  : () => Navigator.pop(context, place.id),
            ),
            if (needsRod) ...[
              const SizedBox(height: 6),
              parchmentButton(
                'CRAFT A BASIC ROD',
                () => Navigator.pop(context, 'workshop'),
                secondary: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cost(String art, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (art == 'time')
        const Icon(Icons.schedule_rounded, size: 18, color: ParchmentColors.ink)
      else
        CardArt(art, size: 18),
      const SizedBox(width: 4),
      ParchmentLabel(label, size: 11),
    ],
  );
}

String _art(String id) => switch (id) {
  'fishing_pond' => 'basic_rod',
  'riverbank' => 'water',
  'bamboo_grove' => 'fiber',
  'ancient_ruins' => 'beacon_core',
  'plane_wreck' => 'radio_module',
  'camp' => 'shelter',
  _ => 'bait',
};
