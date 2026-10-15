import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/fishing_catalog.dart';
import 'package:survival_game/game/fishing_session.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/run_state.dart';
import 'gathering_test.dart' show gatheringGame, gatheringSave;
import 'fishing_session_test.dart' show waitForBite, reelByTracking;

GameEngine fishingGame({
  int seed = 42,
  Set<String> tools = const {
    'basic_rod',
    'reinforced_rod',
    'river_rod',
    'stone_knife',
  },
  Map<String, int>? resources,
  List<SurvivalCondition> conditions = const [],
  int day = 5,
}) => gatheringGame(
  state: RunState(
    day: day,
    campTier: 2,
    tools: tools,
    conditions: conditions,
    resources:
        resources ??
        {
          'wood': 30,
          'stone': 8,
          'fiber': 30,
          'hardwood': 8,
          'metal_scrap': 8,
          'bait': 4,
          'insect_bait': 3,
          'fruit_bait': 4,
          'ember_berries': 3,
          'spiny_sunlurker': 1,
          'mud_whisker': 1,
        },
    stats: {
      SurvivalStat.health: 90,
      SurvivalStat.water: 80,
      SurvivalStat.food: 40,
      SurvivalStat.sanity: 80,
    },
  ),
  random: Random(seed),
);
void landFish(GameEngine game) {
  final s = game.fishing!;
  waitForBite(s);
  expect(s.hook(), isTrue);
  reelByTracking(s);
  expect(s.stage, FishingStage.caught);
  game.saveFishingProgress();
}

void main() {
  test(
    'all five species can be caught, but basic rods cannot select advanced fish',
    () {
      final seen = <String>{};
      for (var seed = 0; seed < 500; seed++) {
        final f = FishCatch.draw(
          Random(seed),
          bait: 'fruit_bait',
          rod: 'river_rod',
          day: 5,
        );
        seen.add(f.speciesId);
        expect(
          f.lengthCm,
          inInclusiveRange(f.species.minLength, f.species.maxLength),
        );
        expect(
          f.weightGrams,
          inInclusiveRange(
            (f.species.minWeight * 1000).round(),
            (f.species.maxWeight * 1000).round(),
          ),
        );
        final basic = FishCatch.draw(
          Random(seed),
          bait: 'fruit_bait',
          rod: 'basic_rod',
          day: 5,
        );
        expect(basic.species.minRod, 0);
      }
      expect(seen, fishSpecies.keys.toSet());
    },
  );
  test(
    'strong venomous and rare species are not available before day three',
    () {
      for (var seed = 0; seed < 100; seed++) {
        final f = FishCatch.draw(
          Random(seed),
          bait: 'fruit_bait',
          rod: 'river_rod',
          day: 2,
        );
        expect(
          f.speciesId,
          isNot(isIn(['spiny_sunlurker', 'goldspot_riverfish'])),
        );
      }
    },
  );
  test('fruit bait favours goldspots without guaranteeing them', () {
    int count(String bait) => List.generate(
      1500,
      (seed) =>
          FishCatch.draw(Random(seed), bait: bait, rod: 'river_rod', day: 5),
    ).where((f) => f.speciesId == 'goldspot_riverfish').length;
    final fruit = count('fruit_bait'), worm = count('bait');
    expect(fruit, greaterThan(worm * 5));
    expect(fruit, lessThan(1500));
  });
  test(
    'selecting bait costs nothing; cast consumes only the selected bait and one durability',
    () {
      final game = fishingGame();
      expect(
        game.travelTo('fishing_pond', gear: {'river_rod', 'stone_knife'}),
        isTrue,
      );
      final before = game.state.toJson();
      expect(game.selectFishingBait('fruit_bait'), isTrue);
      expect(game.state.toJson(), before);
      expect(game.equipFishingRod('river_rod'), isTrue);
      expect(game.castLine(), isTrue);
      expect(game.state.resource('fruit_bait'), 3);
      expect(game.state.resource('bait'), 4);
      expect(game.state.toolCondition('river_rod'), 29);
      expect(game.castLine(), isFalse);
      expect(game.selectFishingBait('bait'), isFalse);
      expect(game.equipFishingRod('basic_rod'), isFalse);
    },
  );
  test('no worm is needed when another owned bait is available', () {
    final game = fishingGame(resources: {'insect_bait': 2});
    expect(game.travelBlockReason('fishing_pond'), isNull);
    game.travelTo('fishing_pond');
    expect(game.fishing!.baitId, 'insect_bait');
    expect(game.castLine(), isTrue);
  });
  test('cast metadata and paid costs survive a mid-reel restore exactly', () {
    final game = fishingGame();
    game.travelTo('fishing_pond');
    game.equipFishingRod('river_rod');
    game.selectFishingBait('fruit_bait');
    game.castLine();
    final s = game.fishing!;
    waitForBite(s);
    s.hook();
    s.update(.2);
    final copy = fishingGame(seed: 99);
    expect(copy.restore(gatheringSave(game)), isTrue);
    expect(copy.fishing!.paused, isTrue);
    expect(copy.fishing!.toJson(), s.toJson());
    expect(copy.state.toJson(), game.state.toJson());
    final snapshot = copy.fishing!.toJson();
    copy.fishing!.update(100);
    expect(copy.fishing!.toJson(), snapshot);
    copy.pauseFishing(false);
    reelByTracking(copy.fishing!);
    expect(copy.fishing!.stage, FishingStage.caught);
  });
  test(
    'closing a landed catch preserves the same unclaimed fish without duplication',
    () {
      final game = fishingGame();
      game.travelTo('fishing_pond');
      game.castLine();
      landFish(game);
      final record = game.fishing!.catchRecord!;
      final initial = game.state.resource(record.speciesId);
      final copy = fishingGame();
      expect(copy.restore(gatheringSave(game)), isTrue);
      expect(copy.fishing!.stage, FishingStage.caught);
      expect(copy.fishing!.catchRecord!.toJson(), record.toJson());
      expect(copy.state.resource(record.speciesId), initial);
      expect(copy.finishFishing(), isTrue);
      expect(copy.state.resource(record.speciesId), initial + 1);
      expect(copy.finishFishing(), isFalse);
      expect(copy.report!.catchRecord!.toJson(), record.toJson());
    },
  );
  test(
    'releasing a catch discovers its species without granting food or refunding bait',
    () {
      final game = fishingGame();
      game.travelTo('fishing_pond');
      game.castLine();
      landFish(game);
      final id = game.fishing!.catchRecord!.speciesId;
      final before = game.state.resource(id);
      expect(game.finishFishing(release: true), isTrue);
      expect(game.state.resource(id), before);
      expect(game.state.resource('bait'), 3);
      expect(game.state.knownFish, contains(id));
      expect(game.report!.title, 'Catch released');
    },
  );
  test(
    'new report catch identity survives acknowledgement and save restore',
    () {
      final game = fishingGame();
      game.travelTo('fishing_pond');
      game.castLine();
      landFish(game);
      game.finishFishing();
      final copy = fishingGame();
      expect(copy.restore(gatheringSave(game)), isTrue);
      expect(copy.report!.toJson(), game.report!.toJson());
      final state = copy.state.toJson();
      copy.continueFromReport();
      expect(copy.state.toJson(), state);
    },
  );
  test(
    'unsafe fish causes its fixed poison only after eating, with no immediate poison damage',
    () {
      for (final id in ['mud_whisker', 'spiny_sunlurker']) {
        final game = fishingGame();
        expect(game.state.conditions, isEmpty);
        expect(game.consume(id), isTrue);
        expect(
          game.state.condition(ConditionKind.poisoned)!.severity,
          fishSpecies[id]!.poison,
        );
        expect(game.state.condition(ConditionKind.poisoned)!.remaining, 4);
        expect(game.state.value(SurvivalStat.health), 90);
        expect(game.state.value(SurvivalStat.food), 48);
      }
    },
  );
  test(
    'safe preparation needs a knife for spines and rejects unavailable costs atomically',
    () {
      final game = fishingGame(tools: {'basic_rod'});
      final before = game.state.toJson();
      expect(game.prepareFishBlockReason('spiny_sunlurker'), 'Knife required');
      expect(game.prepareFish('spiny_sunlurker'), isFalse);
      expect(game.state.toJson(), before);
    },
  );
  test(
    'preparation stores one safe portion and charges one time and one wood once',
    () {
      final game = fishingGame();
      expect(game.prepareFish('spiny_sunlurker'), isTrue);
      expect(game.state.resource('spiny_sunlurker'), 0);
      expect(game.state.resource('prepared_spiny_sunlurker'), 1);
      expect(game.state.resource('wood'), 29);
      expect(game.state.timeLeft, 5);
      expect(game.state.value(SurvivalStat.food), 37);
      expect(game.state.conditions, isEmpty);
      expect(game.prepareFish('spiny_sunlurker'), isFalse);
      game.continueFromReport();
      expect(game.consume('prepared_spiny_sunlurker'), isTrue);
      expect(game.state.value(SurvivalStat.food), 71);
      expect(game.state.conditions, isEmpty);
    },
  );
  test(
    'stronger rods widen the zone and exhaustion remains a frozen penalty',
    () {
      final healthy = FishingSession()..rodId = 'river_rod';
      final weak = FishingSession(zoneScale: .9)..rodId = 'river_rod';
      final basic = FishingSession();
      expect(
        healthy.effectiveZoneHalfWidth,
        greaterThan(basic.effectiveZoneHalfWidth),
      );
      expect(
        weak.effectiveZoneHalfWidth,
        closeTo(healthy.effectiveZoneHalfWidth * .9, .00001),
      );
    },
  );
  test(
    'a broken rod is blocked and can be repaired at its real recipe cost',
    () {
      final game = fishingGame(tools: {'basic_rod'});
      final save = gatheringSave(game);
      (save['state'] as Map)['durability'] = {'basic_rod': 0};
      game.restore(save);
      expect(game.travelBlockReason('fishing_pond'), contains('Repair'));
      expect(game.craft('basic_rod'), isTrue);
      expect(game.state.toolCondition('basic_rod'), 12);
    },
  );
  test('insect and fruit bait are repeatable supplies, not owned tools', () {
    final game = fishingGame();
    expect(game.craft('fruit_bait'), isTrue);
    expect(game.state.resource('fruit_bait'), 7);
    expect(game.state.resource('ember_berries'), 2);
    expect(game.state.tools, isNot(contains('fruit_bait')));
    game.continueFromReport();
    expect(game.craft('fruit_bait'), isTrue);
    expect(game.state.resource('fruit_bait'), 10);
  });
  test('legacy session saves keep the prior interrupted-cast policy', () {
    final game = fishingGame();
    game.travelTo('fishing_pond');
    game.castLine();
    final save = jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;
    (save['fishing'] as Map).remove('session');
    final copy = fishingGame();
    expect(copy.restore(save), isTrue);
    expect(copy.fishing, isNull);
    expect(copy.state.resource('bait'), 3);
    expect(copy.report!.body, contains('slipped away'));
  });
}
