import 'fishing_session_test.dart' show waitForBite, reelByTracking;
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/inventory_catalog.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'gathering_test.dart' show gatheringGame, gatheringSave;
import 'game_engine_test.dart' show FixedRandom;

const fullPack = {
  'prepared_small_fish': 2,
  'herb': 3,
  'bandage': 1,
  'bait': 4,
  'wood': 10,
  'fiber': 8,
  'stone': 6,
};
GameEngine inventoryGame({Map<String, int>? resources, int tier = 0}) {
  final base = gatheringGame();
  return GameEngine(
    EventCatalog([
      ...base.catalog.events,
      GameEvent(
        id: 'inventory_haul',
        trigger: 'explore',
        title: 'A cache',
        description: 'A battery and wood.',
        scene: 'explore',
        locations: ['riverbank'],
        choices: [
          EventChoice(
            id: 'take',
            label: 'Take',
            description: 'Open the cache.',
            effect: EventEffect(resources: {'wood': 3, 'battery': 1}),
            result: 'You opened the cache.',
          ),
          EventChoice(
            id: 'leave',
            label: 'Leave',
            description: 'Leave.',
            effect: EventEffect(),
            result: 'Left alone.',
          ),
        ],
      ),
      GameEvent(
        id: 'inventory_flee',
        trigger: 'encounter',
        title: 'Flee',
        description: 'Flee.',
        scene: 'explore',
        locations: ['riverbank'],
        choices: [
          EventChoice(
            id: 'flee',
            label: 'Run',
            description: 'Lose the pack.',
            effect: EventEffect(dropLoot: true, endsExpedition: true),
            result: 'You ran.',
          ),
          EventChoice(
            id: 'stay',
            label: 'Stay',
            description: 'Stay.',
            effect: EventEffect(),
            result: 'Stayed.',
          ),
        ],
      ),
    ]),
    world: base.world,
    recipes: base.recipes,
    random: FixedRandom(0),
    initialState: RunState(
      day: 5,
      campTier: 2,
      packTier: tier,
      tools: {
        'stone_axe',
        'salvage_axe',
        'stone_spear',
        'basic_rod',
        'machete',
        'torch',
        'leaf_rain_cape',
      },
      resources:
          resources ??
          {
            'wood': 50,
            'stone': 50,
            'fiber': 50,
            'hardwood': 10,
            'metal_scrap': 10,
            'prepared_small_fish': 6,
            'herb': 8,
            'bandage': 3,
            'bait': 12,
          },
    ),
  );
}

void forceInventoryEvent(GameEngine g, String id) {
  final save = gatheringSave(g)
    ..['pendingEvent'] = id
    ..['pendingCost'] = 0;
  expect(g.restore(save), isTrue);
}

GameEngine fullHaul() {
  final g = inventoryGame();
  expect(g.travelTo('riverbank', pack: fullPack), isTrue);
  forceInventoryEvent(g, 'inventory_haul');
  expect(g.choose('take'), isTrue);
  return g;
}

void main() {
  test('stack boundaries distinguish quantities, types and unknown items', () {
    expect(packSlots({'wood': 10}), 1);
    expect(packSlots({'wood': 11}), 2);
    expect(packSlots({'stone': 6}), 2);
    expect(packSlots({'wood': 0}), 0);
    expect(packSlots({'small_fish': 3, 'prepared_small_fish': 1}), 2);
    expect(packSlots({'battery': 2}), 2);
    expect(packSlots(fullPack), 8);
  });
  test(
    'packing draft saves without spending stock or daylight and cancels cleanly',
    () {
      final g = inventoryGame();
      expect(g.beginPacking('riverbank'), isTrue);
      final total = g.state.resources;
      expect(g.updatePacking({'wood': 30}, {'stone_axe'}), isTrue);
      expect(g.leaveCamp(), isTrue);
      expect(g.state.availableResource('wood'), 30);
      expect(g.state.storedResources['wood'], 20);
      expect(g.state.resource('wood'), 50);
      final other = inventoryGame();
      other.beginPacking('riverbank');
      other.updatePacking({'herb': 3}, {'stone_axe'});
      final copy = inventoryGame();
      expect(copy.restore(gatheringSave(other)), isTrue);
      expect(copy.packingDraft!.items, {'herb': 3});
      copy.cancelPacking();
      expect(copy.state.resources, total);
      expect(copy.state.timeLeft, 6);
    },
  );
  test(
    'over-capacity drafts and negative or unavailable amounts cannot depart',
    () {
      final g = inventoryGame();
      g.beginPacking('riverbank');
      expect(g.updatePacking({'stone': 50}, {'stone_axe'}), isTrue);
      expect(g.leaveCamp(), isFalse);
      expect(g.state.locationId, 'camp');
      expect(g.state.timeLeft, 6);
      expect(g.updatePacking({'wood': -1}, {'stone_axe'}), isFalse);
      expect(g.updatePacking({'wood': 51}, {'stone_axe'}), isFalse);
    },
  );
  test('departure locks selected gear and keeps spare tools at camp', () {
    final g = inventoryGame();
    expect(
      g.travelTo('riverbank', pack: {}, gear: {'stone_axe', 'machete'}),
      isTrue,
    );
    expect(g.state.toolUsable('stone_axe'), isTrue);
    expect(g.state.toolUsable('salvage_axe'), isFalse);
    expect(g.state.satisfiesTool('stone_knife'), isTrue);
    expect(g.state.tools, contains('salvage_axe'));
    expect(g.equipFieldTool('salvage_axe'), isFalse);
  });
  test('only one tool per family and a packed bait are accepted', () {
    final g = inventoryGame();
    expect(
      g.travelTo('riverbank', pack: {}, gear: {'stone_axe', 'salvage_axe'}),
      isFalse,
    );
    expect(g.travelTo('fishing_pond', pack: {}, gear: {'basic_rod'}), isFalse);
    expect(
      g.travelTo('fishing_pond', pack: {'bait': 1}, gear: {'basic_rod'}),
      isTrue,
    );
    expect(g.state.availableResource('herb'), 0);
    expect(g.state.storedResources['herb'], 8);
  });
  test(
    'overflow reserves new items while keeping camp and carried stock distinct',
    () {
      final g = fullHaul();
      expect(g.hasPendingHaul, isTrue);
      expect(g.state.usedPackSlots, 8);
      expect(g.state.pendingResources, {'wood': 3, 'battery': 1});
      expect(g.state.availableResource('wood'), 10);
      expect(g.state.resource('wood'), 53);
      expect(g.state.storedResources['wood'], 40);
      expect(g.continueFromReport(), isFalse);
      expect(g.goDeeper(), isFalse);
      expect(g.craft('trail_backpack'), isFalse);
    },
  );
  test(
    'selection persists; confirming discards exact amounts once and frees stack space',
    () {
      final g = fullHaul();
      final kept = {...fullPack, 'stone': 5, 'battery': 1};
      g.updateHaulSelection(kept);
      final copy = inventoryGame();
      expect(copy.restore(gatheringSave(g)), isTrue);
      expect(copy.haulSelection, kept);
      expect(copy.resolveHaul(kept), isTrue);
      expect(copy.hasPendingHaul, isFalse);
      expect(copy.state.usedPackSlots, 8);
      expect(copy.state.resource('wood'), 50);
      expect(copy.state.resource('stone'), 49);
      expect(copy.state.resource('battery'), 1);
      expect(copy.report!.changes['wood'], isNull);
      expect(copy.report!.changes['stone'], -1);
      expect(copy.resolveHaul(kept), isFalse);
      expect(copy.continueFromReport(), isTrue);
      expect(copy.returnHome(), isTrue);
      expect(copy.state.packResources, isEmpty);
      expect(copy.state.storedResources['battery'], 1);
    },
  );
  test(
    'an impossible or forged kept amount is rejected without changing inventory',
    () {
      final g = fullHaul();
      final saved = jsonEncode(g.state.toJson());
      expect(g.resolveHaul(g.haulCandidate), isFalse);
      expect(g.resolveHaul({'battery': 2}), isFalse);
      expect(jsonEncode(g.state.toJson()), saved);
    },
  );
  test(
    'dropping a normal pack loses carried supplies, never camp stock or gear',
    () {
      final g = inventoryGame();
      g.travelTo(
        'riverbank',
        pack: {'herb': 3, 'prepared_small_fish': 2},
        gear: {'stone_axe'},
      );
      forceInventoryEvent(g, 'inventory_flee');
      expect(g.choose('flee'), isTrue);
      expect(g.state.resource('herb'), 5);
      expect(g.state.resource('prepared_small_fish'), 4);
      expect(g.state.tools, contains('stone_axe'));
      expect(g.state.resource('wood'), 50);
      expect(g.state.locationId, 'camp');
      expect(g.state.packResources, isEmpty);
    },
  );
  test(
    'legacy field saves keep their old stock and old loss policy for one trip',
    () {
      final g = inventoryGame();
      g.travelTo('riverbank', pack: {'wood': 2});
      final saved = gatheringSave(g)
        ..['version'] = 1
        ..['pendingEvent'] = 'inventory_flee';
      final s = saved['state'] as Map;
      for (final id in [
        'packResources',
        'pendingResources',
        'expeditionGear',
        'legacyPack',
        'packTier',
      ]) {
        s.remove(id);
      }
      (saved['expedition'] as Map)['loot'] = {'wood': 2};
      expect(g.restore(saved), isTrue);
      expect(g.state.legacyPack, isTrue);
      expect(g.choose('flee'), isTrue);
      expect(g.state.resource('wood'), 48);
      expect(g.state.resource('herb'), 8);
      expect(g.state.legacyPack, isFalse);
    },
  );
  test(
    'new active field saves preserve distinct storage and pack across restore',
    () {
      final g = inventoryGame();
      g.travelTo('riverbank', pack: {'herb': 3});
      final copy = inventoryGame();
      expect(copy.restore(gatheringSave(g)), isTrue);
      expect(copy.state.packResources, {'herb': 3});
      expect(copy.state.storedResources['herb'], 5);
      expect(copy.state.legacyPack, isFalse);
    },
  );
  test(
    'camp gathering bypasses pack capacity and goes straight into storage',
    () {
      final g = inventoryGame();
      g.openGathering(GatheringKind.chopping);
      g.beginGathering();
      for (var i = 0; i < 3; i++) {
        g.tickGathering(i == 0 ? .4 : .8);
        g.strikeGathering();
      }
      g.finishGathering();
      expect(g.hasPendingHaul, isFalse);
      expect(g.state.packResources, isEmpty);
      expect(g.state.storedResources['wood'], 59);
    },
  );
  test(
    'full fishing catch remains pending through restore, then unloads once',
    () {
      final g = inventoryGame(resources: {'wood': 100, 'bait': 4});
      expect(
        g.travelTo(
          'fishing_pond',
          pack: {'wood': 70, 'bait': 2},
          gear: {'basic_rod'},
        ),
        isTrue,
      );
      g.castLine();
      waitForBite(g.fishing!);
      g.fishing!.hook();
      reelByTracking(g.fishing!);
      expect(g.finishFishing(), isTrue);
      expect(g.hasPendingHaul, isTrue);
      expect(g.state.inField, isTrue);
      final species = g.report!.catchRecord!.speciesId;
      final copy = inventoryGame(resources: {'wood': 100, 'bait': 4});
      expect(copy.restore(gatheringSave(g)), isTrue);
      expect(copy.resolveHaul({'wood': 60, 'bait': 1, species: 1}), isTrue);
      expect(copy.state.locationId, 'camp');
      expect(copy.state.packResources, isEmpty);
      expect(copy.state.resource(species), 1);
      expect(copy.state.resource('wood'), 90);
      expect(copy.state.resource('bait'), 3);
      expect(copy.resolveHaul({'wood': 60}), isFalse);
    },
  );
  test(
    'empty last pack and chosen gear are preserved as next-trip template',
    () {
      final g = inventoryGame();
      g.travelTo('riverbank', pack: {}, gear: {'stone_axe'});
      forceInventoryEvent(g, 'inventory_flee');
      g.choose('flee');
      g.continueFromReport();
      expect(g.beginPacking('riverbank'), isTrue);
      expect(g.packingDraft!.items, isEmpty);
      expect(g.packingDraft!.gear, {'stone_axe'});
    },
  );
  test(
    'permanent backpack recipes expand capacity without occupying slots',
    () {
      final g = inventoryGame();
      expect(g.craft('trail_backpack'), isTrue);
      expect(g.state.packCapacity, 12);
      g.continueFromReport();
      expect(g.craft('expedition_pack'), isTrue);
      expect(g.state.packCapacity, 16);
      expect(g.state.usedPackSlots, 0);
    },
  );
}
