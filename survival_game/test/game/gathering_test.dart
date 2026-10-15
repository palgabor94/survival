import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/game/world_catalog.dart';
import 'game_engine_test.dart' show FixedRandom;

GameEngine gatheringGame({RunState? state, int seed = 42, Random? random}) =>
    GameEngine(
      EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
      world: WorldCatalog.fromJson(
        File('assets/data/locations.json').readAsStringSync(),
      ),
      recipes: RecipeCatalog.fromJson(
        File('assets/data/recipes.json').readAsStringSync(),
      ),
      random: random ?? Random(seed),
      initialState:
          state ??
          RunState(
            day: 4,
            tools: {'stone_axe', 'stone_spear', 'stone_knife', 'machete'},
            resources: {'wood': 20, 'stone': 8, 'fiber': 20},
          ),
    );

Map<String, dynamic> gatheringSave(GameEngine game) =>
    jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;

void finishPerfectChopping(GameEngine game) {
  for (var i = 0; i < 3; i++) {
    game.tickGathering(i == 0 ? .4 : .8);
    expect(game.strikeGathering(), isTrue);
  }
  expect(game.finishGathering(), isTrue);
}

/// Resolve an actual attempt for the seeded playthrough bots.
void resolveGatheringForSimulation(GameEngine game) {
  final session = game.gathering!;
  if (session.stage == GatheringStage.ready) {
    final reason = game.gatheringBlockReason(session.kind);
    expect(game.beginGathering(), isTrue, reason: reason);
    // Deprivation on START may already create the final death report.
    if (game.gathering == null) return;
  }
  if (session.paused) game.pauseGathering(false);
  if (session.active) {
    if (session.kind == GatheringKind.foraging) {
      for (final plant in [
        session.ecology ? 'ember_berries' : 'berries',
        'fiber',
        'herb',
      ]) {
        game.pickGatheringPlant(plant);
      }
    } else {
      final period = session.kind == GatheringKind.hunting ? 1.8 : 1.6;
      while (session.active) {
        var advance = (period * .25 - session.elapsed) % (period * .5);
        if (advance < .5 && session.feedbackLeft > 0) advance += period * .5;
        game.tickGathering(advance);
        expect(game.strikeGathering(), isTrue);
      }
    }
  }
  expect(game.finishGathering(), isTrue);
}

void main() {
  test(
    'ready/back costs nothing; starting once spends daylight and supplies',
    () {
      final game = gatheringGame();
      final before = game.state.toJson();
      expect(game.openGathering(GatheringKind.chopping), isTrue);
      expect(game.cancelGathering(), isTrue);
      expect(game.state.toJson(), before);
      game.openGathering(GatheringKind.chopping);
      expect(game.beginGathering(), isTrue);
      expect(game.beginGathering(), isFalse);
      expect(game.state.timeLeft, 5);
      expect(game.state.value(SurvivalStat.water), 76);
      expect(game.state.value(SurvivalStat.food), 72);
      expect(game.startAction(CampAction.rest), isFalse);
      expect(game.openGathering(GatheringKind.hunting), isFalse);
    },
  );
  test(
    'three perfect swings award once, preserve surplus hardwood and wear axe',
    () {
      final game = gatheringGame();
      game.openGathering(GatheringKind.chopping);
      game.beginGathering();
      finishPerfectChopping(game);
      expect(game.state.resource('wood'), 29);
      expect(game.state.resource('hardwood'), 2);
      expect(game.state.toolCondition('stone_axe'), 9);
      expect(game.report!.changes['Water'], -4);
      expect(game.finishGathering(), isFalse);
      expect(game.state.resource('wood'), 29);
    },
  );
  test('two perfect swings keep the smaller hardwood bonus', () {
    final game = gatheringGame();
    game.openGathering(GatheringKind.chopping);
    game.beginGathering();
    game.tickGathering(.4);
    game.strikeGathering();
    game.tickGathering(.8);
    game.strikeGathering();
    game.tickGathering(.7);
    game.strikeGathering();
    expect(game.gathering!.hits, [
      TimingQuality.perfect,
      TimingQuality.perfect,
      TimingQuality.good,
    ]);
    game.finishGathering();
    expect(game.state.resource('hardwood'), 1);
    expect(game.state.resource('wood'), 28);
    expect(game.state.toolCondition('stone_axe'), 9);
  });

  GameEngine pendingChoice(String event, {double roll = 0, RunState? state}) {
    final game = gatheringGame(state: state, random: FixedRandom(roll));
    final save = gatheringSave(game);
    save['pendingEvent'] = event;
    expect(game.restore(save), isTrue);
    return game;
  }

  test('every ordinary axe/spear choice wears once on success and failure', () {
    final catalog = gatheringGame().catalog;
    for (final event in catalog.events) {
      for (final choice in event.choices.where(
        (c) =>
            c.minigame == null &&
            c.requiresTools.any(RunState.toolDurability.containsKey),
      )) {
        for (final roll in [0.0, .999]) {
          final game = pendingChoice(event.id, roll: roll);
          final tools = choice.requiresTools.where(
            RunState.toolDurability.containsKey,
          );
          expect(
            game.choose(choice.id),
            isTrue,
            reason: '${event.id}/${choice.id}',
          );
          for (final tool in tools) {
            expect(game.state.toolCondition(tool), 9);
            expect(game.report!.body, contains('durability: 10 → 9'));
          }
          final resolved = game.state.toJson();
          expect(game.choose(choice.id), isFalse);
          expect(game.state.toJson(), resolved);
          final copy = gatheringGame();
          expect(copy.restore(gatheringSave(game)), isTrue);
          expect(copy.state.toJson(), resolved);
          expect(copy.report!.toJson(), game.report!.toJson());
          expect(copy.choose(choice.id), isFalse);
        }
      }
    }
  });

  test(
    'last ordinary use breaks axe; blocked choices preserve state; repair recovers it',
    () {
      final game = pendingChoice(
        'fallen_branches',
        state: RunState(
          tools: {'stone_axe'},
          durability: {'stone_axe': 1},
          resources: {'wood': 8, 'stone': 4, 'fiber': 6},
        ),
      );
      expect(game.choose('chop'), isTrue);
      expect(game.state.toolCondition('stone_axe'), 0);
      expect(game.report!.body, contains('Repair it in the workshop.'));
      game.continueFromReport();
      final save = gatheringSave(game)..['pendingEvent'] = 'fallen_branches';
      game.restore(save);
      final before = game.state.toJson();
      expect(game.choose('chop'), isFalse);
      expect(game.choose('chop_minigame'), isFalse);
      expect(game.state.toJson(), before);
      expect(game.choose('wood'), isTrue);
      game.continueFromReport();
      expect(game.craft('stone_axe'), isTrue);
      expect(game.state.toolCondition('stone_axe'), 10);
      expect(game.report!.title, startsWith('Repaired:'));
    },
  );

  test(
    'ordinary use preserves untracked tools and missing tools cannot wear',
    () {
      final game = pendingChoice('berry_patch');
      expect(game.choose('roots'), isTrue);
      expect(game.state.durability, isEmpty);
      expect(game.state.tools, contains('stone_knife'));
      final noAxe = pendingChoice('fallen_branches', state: RunState());
      final before = noAxe.state.toJson();
      expect(noAxe.choose('chop'), isFalse);
      expect(noAxe.state.toJson(), before);
    },
  );

  test(
    'hand fishing awards at most one fish and failed attempts award none',
    () {
      for (final roll in [0.0, .999]) {
        final game = pendingChoice('hidden_pool', roll: roll);
        expect(game.choose('hand'), isTrue);
        expect(game.state.resource('small_fish'), roll == 0 ? 1 : 0);
        final copy = gatheringGame();
        copy.restore(gatheringSave(game));
        expect(copy.choose('hand'), isFalse);
        expect(
          copy.state.resource('small_fish'),
          game.state.resource('small_fish'),
        );
      }
    },
  );
  test('spam taps cannot skip swing cooldown or generate extra strikes', () {
    final s = GatheringSession(GatheringKind.chopping, random: Random(1))
      ..start();
    s.update(.4);
    expect(s.strike(), isTrue);
    for (var i = 0; i < 20; i++) {
      expect(s.strike(), isFalse);
    }
    expect(s.hits.length, 1);
    s.update(.8);
    expect(s.strike(), isTrue);
  });
  test(
    'early exit preserves only completed swings and consumes the attempt',
    () {
      final game = gatheringGame();
      game.openGathering(GatheringKind.chopping);
      game.beginGathering();
      game.tickGathering(.4);
      game.strikeGathering();
      expect(game.finishGathering(leave: true), isTrue);
      expect(game.state.resource('wood'), 23);
      expect(game.state.timeLeft, 5);
      expect(game.report!.body, contains('early'));
    },
  );
  test(
    'pause freezes marker and timeout; resume continues the same attempt',
    () {
      final game = gatheringGame();
      game.openGathering(GatheringKind.hunting);
      game.beginGathering();
      game.tickGathering(.2);
      final marker = game.gathering!.marker;
      game.pauseGathering(true);
      game.tickGathering(100);
      expect(game.gathering!.elapsed, .2);
      expect(game.gathering!.marker, marker);
      expect(game.strikeGathering(), isFalse);
      game.pauseGathering(false);
      game.tickGathering(.25);
      expect(game.strikeGathering(), isTrue);
      expect(game.gathering!.lastQuality, TimingQuality.perfect);
      game.finishGathering();
      expect(game.state.resource('raw_meat'), 3);
    },
  );
  test(
    'hunting miss and timeout produce no meat, still spend time and durability',
    () {
      for (final timeout in [false, true]) {
        final game = gatheringGame();
        game.openGathering(GatheringKind.hunting);
        game.beginGathering();
        if (timeout) {
          game.tickGathering(12);
        } else {
          game.strikeGathering();
        }
        expect(game.finishGathering(), isTrue);
        expect(game.state.resource('raw_meat'), 0);
        expect(game.state.timeLeft, 5);
        expect(game.state.toolCondition('stone_spear'), lessThan(10));
      }
    },
  );
  test(
    'foraging is playable by hand; tool gates and maximum selection are enforced',
    () {
      final game = gatheringGame(state: RunState());
      game.openGathering(GatheringKind.foraging);
      expect(game.beginGathering(), isTrue);
      expect(game.pickGatheringPlant('ember_berries'), isTrue);
      expect(game.pickGatheringPlant('ember_berries'), isFalse);
      expect(game.pickGatheringPlant('fiber'), isTrue);
      expect(game.pickGatheringPlant('herb'), isFalse);
      expect(game.pickGatheringPlant('mushroom'), isFalse);
      expect(game.pickGatheringPlant('unknown_plant'), isFalse);
      expect(game.pickGatheringPlant('invented'), isFalse);
      expect(game.finishGathering(), isTrue);
      expect(game.state.resource('fiber'), 2);
      expect(game.state.value(SurvivalStat.food), 72);
      expect(game.state.resource('ember_berries'), 1);
    },
  );
  test('foraging timeout and exit keep picks; a fourth plant is refused', () {
    for (final timeout in [false, true]) {
      final game = gatheringGame();
      game.openGathering(GatheringKind.foraging);
      game.beginGathering();
      for (final id in ['ember_berries', 'fiber', 'herb']) {
        expect(game.pickGatheringPlant(id), isTrue);
      }
      expect(game.pickGatheringPlant('mushroom'), isFalse);
      if (timeout) game.tickGathering(8);
      game.finishGathering(leave: !timeout);
      expect(game.state.resource('fiber'), 22);
      expect(game.state.resource('herb'), 1);
      expect(game.state.timeLeft, 5);
    }
  });
  test(
    'selected plants and hidden safety survive save; active sessions restore paused',
    () {
      final game = gatheringGame();
      game.openGathering(GatheringKind.foraging);
      game.beginGathering();
      game.pickGatheringPlant('mooncap');
      game.tickGathering(2.5);
      final copy = gatheringGame(seed: 99);
      expect(copy.restore(gatheringSave(game)), isTrue);
      expect(copy.gathering!.paused, isTrue);
      expect(copy.gathering!.elapsed, 2.5);
      expect(copy.gathering!.picked, {'mooncap'});
      expect(copy.gathering!.mushroomSafe, game.gathering!.mushroomSafe);
      expect(copy.beginGathering(), isFalse);
      copy.finishGathering();
      game.finishGathering();
      expect(copy.report!.toJson(), game.report!.toJson());
      final reportCopy = gatheringGame();
      reportCopy.restore(gatheringSave(copy));
      expect(reportCopy.gathering, isNull);
      expect(reportCopy.state.toJson(), copy.state.toJson());
      expect(reportCopy.finishGathering(), isFalse);
    },
  );
  void restoreLegacyForage(GameEngine game) {
    final save = gatheringSave(game);
    (save['gathering']['session'] as Map).remove('ecology');
    expect(game.restore(save), isTrue);
  }

  test(
    'legacy safe herbs from two picks stack regardless of selection order',
    () {
      for (final picks in [
        ['herb', 'unknown_plant'],
        ['unknown_plant', 'herb'],
      ]) {
        final game = gatheringGame();
        game.openGathering(GatheringKind.foraging);
        restoreLegacyForage(game);
        game.gathering!.unknownSafe = true;
        game.beginGathering();
        for (final id in picks) {
          game.pickGatheringPlant(id);
        }
        game.finishGathering();
        expect(game.state.resource('herb'), 3);
      }
    },
  );
  test('dangerous plants show damage only in the final actual outcome', () {
    final game = gatheringGame();
    game.openGathering(GatheringKind.foraging);
    restoreLegacyForage(game);
    game.gathering!.unknownSafe = false;
    game.beginGathering();
    game.pickGatheringPlant('unknown_plant');
    expect(game.state.value(SurvivalStat.health), 100);
    expect(game.report, isNull);
    game.finishGathering();
    expect(game.report!.changes['Health'], -8);
  });
  test('last daylight completes activity before queuing the night event', () {
    final game = gatheringGame(
      state: RunState(timeLeft: 1, tools: {'stone_spear'}),
    );
    game.openGathering(GatheringKind.hunting);
    game.beginGathering();
    game.tickGathering(.45);
    game.strikeGathering();
    game.finishGathering();
    expect(game.state.timeLeft, 0);
    expect(game.pendingEvent, isNull);
    game.continueFromReport();
    expect(game.state.phase, RunPhase.night);
    expect(game.pendingEvent!.trigger, 'night');
  });
  test(
    'deprivation can end an attempt on START without loot or repeat costs',
    () {
      final game = gatheringGame(
        state: RunState(
          tools: {'stone_spear'},
          stats: {
            SurvivalStat.health: 5,
            SurvivalStat.water: 0,
            SurvivalStat.food: 0,
            SurvivalStat.sanity: 30,
          },
        ),
      );
      game.openGathering(GatheringKind.hunting);
      expect(game.beginGathering(), isTrue);
      expect(game.state.phase, RunPhase.gameOver);
      expect(game.gathering, isNull);
      expect(game.state.resource('raw_meat'), 0);
      expect(game.beginGathering(), isFalse);
    },
  );
  test('worn and broken tools can be repaired at real recipe costs', () {
    final game = gatheringGame(
      state: RunState(
        tools: {'stone_axe'},
        durability: {'stone_axe': 0},
        resources: {'wood': 8, 'stone': 4, 'fiber': 6},
      ),
    );
    game.openGathering(GatheringKind.chopping);
    expect(game.beginGathering(), isFalse);
    game.cancelGathering();
    expect(game.craftBlockReason('stone_axe'), isNull);
    expect(game.craft('stone_axe'), isTrue);
    expect(game.state.toolCondition('stone_axe'), 10);
    expect(game.state.resource('wood'), 6);
    expect(game.state.resource('fiber'), 4);
    expect(game.state.timeLeft, 5);
    game.continueFromReport();
    expect(game.craft('stone_axe'), isFalse);
  });
  test(
    'version-one saves without durability preserve usable existing tools',
    () {
      final game = gatheringGame();
      final json = gatheringSave(game);
      (json['state'] as Map).remove('durability');
      final copy = gatheringGame();
      expect(copy.restore(json), isTrue);
      expect(copy.state.toolCondition('stone_axe'), 10);
    },
  );
  test(
    'event minigame reserves then charges travel once and tracks carried loot',
    () {
      final game = gatheringGame();
      final save = gatheringSave(game);
      (save['state'] as Map)['locationId'] = 'riverbank';
      save['pendingEvent'] = 'hardwood_grove';
      save['pendingAction'] = 'explore';
      save['pendingCost'] = 2;
      save['expedition'] = {
        'locationId': 'riverbank',
        'depth': 0,
        'loot': <String, int>{},
      };
      expect(game.restore(save), isTrue);
      expect(game.choose('chop_minigame'), isTrue);
      expect(game.state.timeLeft, 6);
      expect(game.state.toolCondition('stone_axe'), 10);
      final readyCopy = gatheringGame();
      readyCopy.restore(gatheringSave(game));
      expect(readyCopy.cancelGathering(), isTrue);
      expect(readyCopy.pendingEvent!.id, 'hardwood_grove');
      expect(readyCopy.pendingCost, 2);
      expect(readyCopy.state.toolCondition('stone_axe'), 10);
      game.beginGathering();
      expect(game.state.timeLeft, 4);
      expect(game.state.toolCondition('stone_axe'), 10);
      finishPerfectChopping(game);
      expect(game.expedition!.loot['wood'], 9);
      expect(game.expedition!.loot['hardwood'], 2);
      expect(game.state.toolCondition('stone_axe'), 9);
      game.continueFromReport();
      expect(game.awaitingExpeditionDecision, isTrue);
      game.returnHome();
      expect(game.state.resource('wood'), 29);
    },
  );
}
