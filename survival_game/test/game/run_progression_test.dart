import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_game/game/run_progression.dart';
import 'package:survival_game/game/run_storage.dart';
import 'package:survival_game/game/run_state.dart';
import 'inventory_test.dart' show inventoryGame, fullPack;
import 'gathering_test.dart' show gatheringSave;
import 'rescue_test.dart' show rescueGame, rescueState, reopen;
import 'fishing_session_test.dart' show waitForBite, reelByTracking;

RunMetrics sampleMetrics() => RunMetrics()
  ..nights = 7
  ..campTier = 2
  ..crafted = 9
  ..fishCaught = 5
  ..locations.addAll(['riverbank', 'plane_wreck', 'bamboo_grove'])
  ..fishSpecies.addAll(['small_fish', 'mud_whisker'])
  ..recipes.addAll(List.generate(6, (i) => 'recipe$i'))
  ..encounterTypes.addAll(['jaguar_trail', 'snake_thicket'])
  ..components.add('battery');
RunSummary summary(RunMetrics m, {String outcome = 'lost', int before = 420}) =>
    RunSummary(
      metrics: m,
      outcome: outcome,
      day: 8,
      location: 'riverbank',
      stats: RunState().stats,
      xpBefore: before,
    );

void main() {
  test(
    'accepted XP example totals 246 and immutable summary freezes counters',
    () {
      final m = sampleMetrics();
      final s = summary(m);
      expect(s.earned, 246);
      expect(s.xpAfter, 666);
      m.nights = 99;
      expect(s.metrics.nights, 7);
      s.metrics.locations.clear();
      expect(s.metrics.locations.length, 3);
      (s.toJson()['metrics'] as Map)['nights'] = 100;
      expect(s.metrics.nights, 7);
      expect(() => s.stats[SurvivalStat.health] = 0, throwsUnsupportedError);
    },
  );
  test('every category caps independently at maximum 760', () {
    final m = RunMetrics()
      ..nights = 90
      ..campTier = 3
      ..stormSteps = 3;
    for (var i = 0; i < 30; i++) {
      m.locations.add('$i');
      m.fishSpecies.add('$i');
      m.recipes.add('$i');
      m.encounterTypes.add('$i');
      m.components.add('$i');
    }
    expect(summary(m, outcome: 'rescued').earned, 760);
    expect(summary(m, outcome: 'abandoned').earned, 660);
  });
  test('rank thresholds cover boundary, skipped ranks and maximum', () {
    expect(rankFor(199), 1);
    expect(rankFor(200), 2);
    expect(rankFor(666), 3);
    expect(rankFor(1140), 4);
    expect(rankFor(5400), 10);
    expect(rankFor(99999), 10);
  });
  test(
    'archive cap preserves lifetime totals and repeated closure gives no XP',
    () {
      final p = PlayerProfile();
      final first = summary(RunMetrics()..nights = 1, before: 0);
      p.record(first);
      expect(p.record(first), false);
      for (var i = 0; i < 25; i++) {
        p.record(summary(RunMetrics()..nights = 1, before: p.xp));
      }
      expect(p.archive.length, 20);
      expect(p.journeys, 26);
      expect(p.xp, 208);
      expect(p.bestNights, 1);
      final copy = PlayerProfile.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(copy.journeys, 26);
      expect(copy.xp, 208);
      expect(copy.record(copy.archive.first), false);
    },
  );
  test(
    'draft destination is not visited until real departure and restore does not repeat',
    () {
      final g = inventoryGame();
      g.beginPacking('riverbank');
      expect(g.metrics.locations, isEmpty);
      g.leaveCamp();
      expect(g.metrics.locations, {'riverbank'});
      final copy = inventoryGame();
      expect(copy.restore(gatheringSave(g)), true);
      expect(copy.metrics.locations, {'riverbank'});
      expect(copy.metrics.id, g.metrics.id);
    },
  );
  test(
    'craft transactions count once, repairs do not count and unique recipes deduplicate',
    () {
      final g = inventoryGame();
      expect(g.craft('bandage'), true);
      g.continueFromReport();
      expect(g.craft('bandage'), true);
      expect(g.metrics.crafted, 2);
      expect(g.metrics.recipes, {'bandage'});
      final other = inventoryGame();
      expect(other.craft('stone_axe'), false);
      expect(other.metrics.crafted, 0);
    },
  );
  test(
    'poison fatal source is captured before condition expires and no full night is invented',
    () {
      final g = rescueGame(
        state: rescueState(health: 2).copyWith(
          conditions: [
            const SurvivalCondition(ConditionKind.poisoned, 1, severity: 2),
          ],
        ),
      );
      expect(g.startAction(CampAction.rest), true);
      expect(g.metrics.fatalCause, 'poisoned:2');
      expect(g.metrics.nights, 0);
      expect(g.completedRun!.outcome, 'lost');
      final xp = g.profile.xp;
      g.continueFromReport();
      expect(g.profile.xp, xp);
      final copy = reopen(g);
      expect(copy.profile.xp, xp);
      expect(copy.profile.journeys, 1);
    },
  );
  test(
    'deprivation is distinct from poison and a lethal night is not survived',
    () {
      final g = rescueGame(state: rescueState(health: 1, water: 0, food: 0));
      g.startAction(CampAction.rest);
      expect(g.metrics.fatalCause, 'deprivation');
      expect(g.completedRun!.metrics.nights, 0);
    },
  );
  test(
    'pending components do not count until final retained haul reaches camp',
    () {
      final g = inventoryGame();
      expect(g.travelTo('plane_wreck', pack: fullPack), true);
      expect(g.choose('recover'), true);
      expect(g.metrics.components, isEmpty);
      expect(
        g.resolveHaul({...g.haulCandidate, 'stone': 5, 'metal_scrap': 0}),
        true,
      );
      expect(g.metrics.components, isEmpty);
      g.continueFromReport();
      g.returnHome();
      expect(g.metrics.components, {'battery'});
      final count = g.metrics.components.length;
      g.continueFromReport();
      expect(g.metrics.components.length, count);
    },
  );
  test(
    'released successful fish counts as catch and species but not retained food',
    () {
      final g = inventoryGame();
      expect(
        g.travelTo('fishing_pond', pack: {'bait': 1}, gear: {'basic_rod'}),
        true,
      );
      g.castLine();
      waitForBite(g.fishing!);
      g.fishing!.hook();
      reelByTracking(g.fishing!);
      expect(g.finishFishing(release: true), true);
      expect(g.metrics.fishCaught, 1);
      expect(g.metrics.fishKept, 0);
      expect(g.metrics.fishSpecies.length, 1);
      expect(g.finishFishing(), false);
      expect(g.metrics.fishCaught, 1);
    },
  );
  test('kept fish counts independently of fish left in camp storage', () {
    final g = inventoryGame(resources: {'small_fish': 6, 'bait': 4});
    g.travelTo('fishing_pond', pack: {'bait': 1}, gear: {'basic_rod'});
    g.castLine();
    waitForBite(g.fishing!);
    g.fishing!.hook();
    reelByTracking(g.fishing!);
    g.finishFishing();
    expect(g.metrics.fishCaught, 1);
    expect(g.metrics.fishKept, 1);
  });
  test(
    'legacy ended saves display zero retroactive XP and active legacy tracking is partial',
    () {
      final g = rescueGame(
        state: rescueState().copyWith(phase: RunPhase.rescued),
      );
      final old = gatheringSave(g)
        ..remove('metrics')
        ..remove('profile')
        ..remove('completedRun')
        ..['version'] = 2;
      final copy = inventoryGame();
      expect(copy.restore(old), true);
      expect(copy.completedRun!.earned, 0);
      expect(copy.completedRun!.metrics.legacyEnded, true);
      final active = gatheringSave(inventoryGame())
        ..remove('metrics')
        ..remove('profile')
        ..['version'] = 1;
      expect(copy.restore(active), true);
      expect(copy.metrics.partialSince, 5);
      expect(copy.metrics.nights, 0);
    },
  );
  test(
    'options unlock at ranks and apply only to new runs preserving profile',
    () {
      for (final option in startingOptions) {
        final g = inventoryGame();
        g.profile.xp = rankThreshold(option.rank);
        final old = g.state.resources;
        expect(g.selectStartingOption(option.id), true);
        expect(g.state.resources, old);
        final id = g.metrics.id;
        g.restart();
        expect(g.metrics.id, isNot(id));
        expect(g.state.resource('wood'), 2 + (option.items['wood'] ?? 0));
        expect(g.state.resource('stone'), option.items['stone'] ?? 0);
        expect(g.state.value(SurvivalStat.food), 75 + option.food);
        expect(g.state.packCapacity, 8);
        expect(g.metrics.option, option.id);
        expect(g.profile.journeys, 1);
      }
      expect(inventoryGame().selectStartingOption('medic'), false);
    },
  );
  test(
    'serialized writes preserve snapshots and save failure blocks reset until retry',
    () async {
      final g = inventoryGame();
      final writes = <Map<String, dynamic>>[];
      var fail = true;
      g.persistSnapshot = (snapshot) async {
        if (fail) throw StateError('Disk full');
        writes.add(snapshot);
      };
      g.abandonJourney();
      await g.saveSettled;
      expect(g.saveFailed, true);
      final id = g.metrics.id;
      g.restart();
      expect(g.metrics.id, id);
      fail = false;
      await g.retrySave();
      expect(g.canStartNewRun, true);
      g.restart();
      await g.saveSettled;
      expect(g.profile.journeys, 1);
      expect(writes.last['profile'], g.profile.toJson());
    },
  );
  test(
    'queued saves cannot overwrite newer profile with an older snapshot',
    () async {
      final g = inventoryGame();
      final first = Completer<void>();
      final ids = <String>[];
      g.persistSnapshot = (snapshot) async {
        if (ids.isEmpty) await first.future;
        ids.add((snapshot['metrics'] as Map)['id'] as String);
      };
      g.beginPacking('riverbank');
      g.updatePacking({}, {});
      expect(g.saving, true);
      first.complete();
      await g.saveSettled;
      expect(ids.length, 2);
      expect(g.canStartNewRun, true);
    },
  );
  test(
    'preferences keep a complete prior snapshot for malformed primary fallback',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = PreferencesRunStorage();
      final a = inventoryGame().toJson();
      await storage.save(a);
      final b = inventoryGame().toJson();
      await storage.save(b);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lost_canopy.run', 'broken');
      expect((await storage.load())!['metrics'], a['metrics']);
    },
  );
  test(
    'invalid restore preserves current profile and loaded backup remains the trusted prior snapshot',
    () async {
      final g = inventoryGame();
      g.profile.xp = 666;
      final checkpoint = jsonDecode(jsonEncode(g.toJson()));
      final bad = gatheringSave(g)
        ..['ruinsPuzzle'] = {
          'session': {
            'tiles': [9, 0],
          },
        };
      expect(g.restore(bad), false);
      expect(g.toJson(), checkpoint);
      SharedPreferences.setMockInitialValues({});
      final storage = PreferencesRunStorage();
      final a = inventoryGame().toJson();
      await storage.save(a);
      await storage.save(inventoryGame().toJson());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'lost_canopy.run',
        jsonEncode({
          'version': 3,
          'state': {},
          'profile': {'bad': true},
        }),
      );
      await storage.load();
      final recovered = await storage.loadBackup();
      expect(recovered!['metrics'], a['metrics']);
      await storage.save(recovered);
      expect((await storage.loadBackup())!['metrics'], a['metrics']);
    },
  );
}
