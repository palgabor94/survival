import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/tool_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'gathering_test.dart';
import 'game_engine_test.dart' show FixedRandom;

GameEngine toolGame({
  Set<String>? tools,
  Map<String, int> durability = const {},
  List<SurvivalCondition> conditions = const [],
}) => gatheringGame(
  state: RunState(
    day: 5,
    campTier: 2,
    tools: tools ?? fieldTools.keys.toSet(),
    durability: durability,
    conditions: conditions,
    resources: {
      'wood': 30,
      'stone': 20,
      'fiber': 30,
      'hardwood': 12,
      'metal_scrap': 10,
    },
  ),
  random: FixedRandom(0),
);
GameEngine toolEvent(
  String event, {
  String spear = 'hunting_spear',
  List<SurvivalCondition> conditions = const [],
  double roll = 0,
}) {
  final g = toolGame(conditions: conditions);
  g.equipFieldTool(spear);
  final j = gatheringSave(g)
    ..['pendingEvent'] = event
    ..['pendingCost'] = 0;
  final result = gatheringGame(random: FixedRandom(roll));
  expect(result.restore(j), isTrue);
  return result;
}

void main() {
  test(
    'legacy equipment defaults and upgraded tools satisfy family requirements',
    () {
      final s = RunState(tools: {'salvage_axe', 'hunting_spear'});
      final json = s.toJson()
        ..remove('equippedAxe')
        ..remove('equippedSpear');
      final restored = RunState.fromJson(json);
      expect(restored.activeFieldTool('axe'), 'salvage_axe');
      expect(restored.satisfiesTool('stone_axe'), isTrue);
      expect(restored.satisfiesTool('stone_spear'), isTrue);
      expect(restored.satisfiesTool('machete'), isFalse);
    },
  );
  test(
    'crafting keeps prerequisite, equips full tool and cannot duplicate it',
    () {
      final g = toolGame(tools: {'stone_axe'});
      expect(g.craft('reinforced_axe'), isTrue);
      expect(g.state.tools, containsAll(['stone_axe', 'reinforced_axe']));
      expect(g.state.equippedAxe, 'reinforced_axe');
      expect(g.state.toolCondition('reinforced_axe'), 16);
      expect(g.state.resource('stone'), 18);
      g.continueFromReport();
      expect(g.craft('reinforced_axe'), isFalse);
    },
  );
  test(
    'repair charges repair materials rather than full crafting materials',
    () {
      final g = toolGame(
        tools: {'salvage_spear'},
        durability: {'salvage_spear': 3},
      );
      expect(g.craftCosts('salvage_spear'), {'metal_scrap': 1, 'fiber': 2});
      expect(g.craft('salvage_spear'), isTrue);
      expect(g.state.toolCondition('salvage_spear'), 24);
      expect(g.state.resource('metal_scrap'), 9);
      expect(g.state.resource('hardwood'), 12);
      expect(g.state.timeLeft, 5);
      expect(g.craft('salvage_spear'), isFalse);
    },
  );
  test('broken prerequisite can be upgraded, missing prerequisite cannot', () {
    final g = toolGame(tools: {'stone_axe'}, durability: {'stone_axe': 0});
    expect(g.craftBlockReason('reinforced_axe'), isNull);
    expect(g.craftBlockReason('salvage_axe'), contains('Reinforced Axe'));
  });
  for (final entry in [
    ('stone_axe', 9, 2),
    ('reinforced_axe', 10, 2),
    ('salvage_axe', 11, 3),
  ]) {
    test('${entry.$1} perfect wood reward and wear commit exactly once', () {
      final g = toolGame();
      g.equipFieldTool(entry.$1);
      g.openGathering(GatheringKind.chopping);
      g.beginGathering();
      final maximum = g.state.toolCondition(entry.$1);
      finishPerfectChopping(g);
      expect(g.state.resource('wood'), 30 + entry.$2);
      expect(g.state.resource('hardwood'), 12 + entry.$3);
      expect(g.state.toolCondition(entry.$1), maximum - 1);
      expect(g.finishGathering(), isFalse);
      expect(g.state.toolCondition(entry.$1), maximum - 1);
      final restored = toolGame();
      expect(restored.restore(gatheringSave(g)), isTrue);
      expect(restored.finishGathering(), isFalse);
    });
  }
  test('all missed strikes yield no upgraded wood bonus and extra wear', () {
    final g = toolGame();
    g.equipFieldTool('salvage_axe');
    g.openGathering(GatheringKind.chopping);
    g.beginGathering();
    for (var i = 0; i < 3; i++) {
      if (i > 0) g.tickGathering(.8);
      expect(g.strikeGathering(), isTrue);
    }
    expect(g.finishGathering(), isTrue);
    expect(g.state.resource('wood'), 30);
    expect(g.state.toolCondition('salvage_axe'), 20);
  });
  test(
    'start freezes equipment and control, restore resumes same tool; no active swap',
    () {
      final g = toolGame();
      g.equipFieldTool('reinforced_axe');
      g.openGathering(GatheringKind.chopping);
      g.beginGathering();
      g.tickGathering(.2);
      expect(g.equipFieldTool('salvage_axe'), isFalse);
      final saved = gatheringSave(g);
      final clone = toolGame();
      expect(clone.restore(saved), isTrue);
      expect(clone.gathering!.toolId, 'reinforced_axe');
      expect(clone.gathering!.goodScale, 1.1);
      expect(clone.gathering!.paused, isTrue);
      clone.pauseGathering(false);
      clone.tickGathering(.2);
      clone.strikeGathering();
      clone.finishGathering(leave: true);
      expect(clone.state.toolCondition('reinforced_axe'), 15);
      expect(clone.state.toolCondition('salvage_axe'), 24);
    },
  );
  test('one remaining condition completes attempt and then falls back', () {
    final g = toolGame(durability: {'salvage_axe': 1});
    g.equipFieldTool('salvage_axe');
    g.openGathering(GatheringKind.chopping);
    g.beginGathering();
    finishPerfectChopping(g);
    expect(g.state.toolCondition('salvage_axe'), 0);
    expect(g.state.activeFieldTool('axe'), 'reinforced_axe');
  });
  test('GOOD window grows but PERFECT does not', () {
    final base = GatheringSession(GatheringKind.hunting)
      ..start()
      ..elapsed = .45 + .18;
    final upgraded = GatheringSession(GatheringKind.hunting, goodScale: 1.2)
      ..start()
      ..elapsed = .45 + .18;
    expect(base.currentQuality, TimingQuality.miss);
    expect(upgraded.currentQuality, TimingQuality.good);
    base.elapsed = .45 + .07;
    upgraded.elapsed = base.elapsed;
    expect(base.currentQuality, TimingQuality.good);
    expect(upgraded.currentQuality, TimingQuality.good);
  });
  test(
    'jaguar spear chances combine equipment and status without changing rewards',
    () {
      for (final entry in [
        ('stone_spear', .7),
        ('hunting_spear', .78),
        ('salvage_spear', .85),
      ]) {
        final g = toolEvent('jaguar_trail', spear: entry.$1);
        final choice = g.pendingEvent!.choices.firstWhere(
          (c) => c.id == 'spear',
        );
        expect(g.chanceFor(choice), closeTo(entry.$2, .0001));
        expect(g.choose('spear'), isTrue);
        expect(
          g.state.toolCondition(entry.$1),
          fieldTools[entry.$1]!.durability - 1,
        );
      }
      final injured = toolEvent(
        'jaguar_trail',
        conditions: [SurvivalCondition(ConditionKind.injured, 3)],
      );
      expect(
        injured.chanceFor(
          injured.pendingEvent!.choices.firstWhere((c) => c.id == 'spear'),
        ),
        closeTo(.68, .0001),
      );
    },
  );
  test('new boar action accepts upgraded-only spear and never adds meat', () {
    final g = toolEvent('boar_charge');
    expect(g.choose('brace_spear'), isTrue);
    expect(g.state.resource('raw_meat'), 0);
    expect(g.state.toolCondition('hunting_spear'), 15);
    final failed = toolEvent('boar_charge', roll: .99);
    expect(failed.choose('brace_spear'), isTrue);
    expect(failed.report!.changes['Health'], lessThan(0));
    expect(failed.state.toolCondition('hunting_spear'), 15);
  });
  test('event axes use the actual upgraded tool and add wood once', () {
    final g = toolGame(tools: {'salvage_axe'});
    final j = gatheringSave(g)..['pendingEvent'] = 'hardwood_grove';
    expect(g.restore(j), isTrue);
    final c = g.pendingEvent!.choices.firstWhere(
      (c) => c.requiresTools.contains('stone_axe'),
    );
    expect(g.canChoose(c), isTrue);
    expect(g.choose(c.id), isTrue);
    expect(g.state.toolCondition('salvage_axe'), 23);
    expect(g.report!.changes['wood'], (c.effect.resources['wood'] ?? 0) + 2);
  });
}
