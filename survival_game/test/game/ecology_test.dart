import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'gathering_test.dart' show gatheringGame, gatheringSave;
import 'game_engine_test.dart' show FixedRandom;

RunState supplies({
  List<SurvivalCondition> conditions = const [],
  String weather = 'Sunny',
  int tier = 0,
  Set<String> tools = const {},
  Map<String, int>? resources,
  int health = 80,
  int strain = 0,
}) => RunState(
  day: 4,
  campTier: tier,
  conditions: conditions,
  weather: weather,
  tools: tools,
  strain: strain,
  resources:
      resources ??
      {
        'wood': 20,
        'fiber': 20,
        'herb': 8,
        'charcoal': 4,
        'antidote': 2,
        'bandage': 2,
        'ember_berries': 2,
        'mooncap': 2,
        'ribbon_root': 4,
      },
  stats: {
    SurvivalStat.health: health,
    SurvivalStat.water: 80,
    SurvivalStat.food: 75,
    SurvivalStat.sanity: 80,
  },
);
GameEngine pending(
  String event,
  String choice, {
  RunState? state,
  double roll = 0,
  int cost = 0,
}) {
  final game = gatheringGame(
    state: state ?? supplies(),
    random: FixedRandom(roll),
  );
  final save = gatheringSave(game)
    ..['pendingEvent'] = event
    ..['pendingCost'] = cost;
  expect(game.restore(save), isTrue);
  expect(game.choose(choice), isTrue);
  return game;
}

void main() {
  test('poison ticks once per spent time; report and restore never tick', () {
    final game = gatheringGame(
      state: supplies(
        conditions: [const SurvivalCondition(ConditionKind.poisoned, 4)],
      ),
    );
    game.startAction(CampAction.rest);
    expect(game.state.value(SurvivalStat.health), 78);
    expect(game.state.value(SurvivalStat.water), 75);
    expect(game.state.condition(ConditionKind.poisoned)!.remaining, 3);
    final saved = gatheringSave(game);
    final copy = gatheringGame();
    expect(copy.restore(saved), isTrue);
    expect(copy.state.toJson(), game.state.toJson());
    copy.continueFromReport();
    expect(copy.state.toJson(), game.state.toJson());
  });
  test('new poison is applied after travel cost, never retrospectively', () {
    final game = pending('ecology_pool', 'drink', cost: 2);
    expect(game.state.value(SurvivalStat.health), 80);
    expect(game.state.condition(ConditionKind.poisoned)!.remaining, 4);
    expect(game.report!.conditionChanges.single, contains('acquired'));
  });
  test('poison refresh retains strongest severity and maximum duration', () {
    final game = pending(
      'ecology_pool',
      'drink',
      state: supplies(
        conditions: [
          const SurvivalCondition(ConditionKind.poisoned, 2, severity: 2),
        ],
      ),
    );
    expect(game.state.conditions, hasLength(1));
    expect(game.state.condition(ConditionKind.poisoned)!.severity, 2);
    expect(game.state.condition(ConditionKind.poisoned)!.remaining, 4);
  });
  test(
    'antidote clears poison without refund or daylight; repeated use refused',
    () {
      final game = gatheringGame(
        state: supplies(
          conditions: [const SurvivalCondition(ConditionKind.poisoned, 4)],
        ),
      );
      expect(game.consume('antidote'), isTrue);
      expect(game.state.value(SurvivalStat.health), 80);
      expect(game.state.timeLeft, 6);
      expect(game.state.resource('antidote'), 1);
      game.continueFromReport();
      expect(game.consume('antidote'), isFalse);
    },
  );
  test(
    'bandage removes injury before healing, but poison still blocks healing',
    () {
      for (final poison in [false, true]) {
        final game = gatheringGame(
          state: supplies(
            conditions: [
              const SurvivalCondition(ConditionKind.injured, 6),
              if (poison) const SurvivalCondition(ConditionKind.poisoned, 4),
            ],
          ),
        );
        expect(game.consume('bandage'), isTrue);
        expect(game.state.hasCondition(ConditionKind.injured), isFalse);
        expect(game.state.value(SurvivalStat.health), poison ? 80 : 84);
      }
    },
  );
  test('bitter herbs shorten poison but cannot remove its last tick', () {
    final game = gatheringGame(
      state: supplies(
        conditions: [const SurvivalCondition(ConditionKind.poisoned, 2)],
      ),
    );
    expect(game.chewHerbs(), isTrue);
    expect(game.state.condition(ConditionKind.poisoned)!.remaining, 1);
    game.continueFromReport();
    final before = game.state.toJson();
    expect(game.chewHerbs(), isFalse);
    expect(game.state.toJson(), before);
  });
  test(
    'physical risk penalties cap and guaranteed choices stay guaranteed',
    () {
      final game = gatheringGame(
        state: supplies(
          conditions: [
            const SurvivalCondition(ConditionKind.poisoned, 4, severity: 2),
            const SurvivalCondition(ConditionKind.injured, 6),
            const SurvivalCondition(ConditionKind.exhausted, 4),
          ],
        ),
      );
      EventChoice choice(double chance, String domain) => EventChoice(
        id: 'x',
        label: 'x',
        description: 'x',
        effect: EventEffect(),
        result: 'x',
        successChance: chance,
        riskDomain: domain,
      );
      expect(game.chanceFor(choice(.7, 'physical')), closeTo(.45, .0001));
      expect(game.chanceFor(choice(.7, 'mental')), .7);
      expect(game.chanceFor(choice(1, 'physical')), 1);
    },
  );
  test(
    'existing injury amplifies physical damage; new injury does not amplify itself',
    () {
      final normal = pending('ecology_thorns', 'force', roll: .999);
      final injured = pending(
        'ecology_thorns',
        'force',
        roll: .999,
        state: supplies(
          conditions: [const SurvivalCondition(ConditionKind.injured, 6)],
        ),
      );
      expect(normal.state.value(SurvivalStat.health), 72);
      expect(injured.state.value(SurvivalStat.health), 70);
    },
  );
  test('rain exposure needs three ticks; sheltered rest does not get wet', () {
    final game = pending(
      'ecology_dew',
      'leave',
      cost: 3,
      state: supplies(weather: 'Light rain'),
    );
    expect(game.state.condition(ConditionKind.wet)!.remaining, 3);
    final cape = pending(
      'ecology_dew',
      'leave',
      cost: 3,
      state: supplies(weather: 'Light rain', tools: {'leaf_rain_cape'}),
    );
    expect(cape.state.hasCondition(ConditionKind.wet), isFalse);
    final rested = gatheringGame(state: supplies(weather: 'Storm'));
    for (var i = 0; i < 3; i++) {
      rested.startAction(CampAction.rest);
      rested.continueFromReport();
    }
    expect(rested.state.hasCondition(ConditionKind.wet), isFalse);
  });
  test(
    'dry by fire removes wet before the paid tick, while poison still ticks',
    () {
      final game = gatheringGame(
        state: supplies(
          conditions: [
            const SurvivalCondition(ConditionKind.wet, 3),
            const SurvivalCondition(ConditionKind.poisoned, 4),
          ],
        ),
      );
      expect(game.dryByFire(), isTrue);
      expect(game.state.hasCondition(ConditionKind.wet), isFalse);
      expect(game.state.value(SurvivalStat.health), 78);
      expect(game.state.value(SurvivalStat.sanity), 80);
      expect(game.state.resource('wood'), 19);
    },
  );
  test('repeatable supplies are resources, never owned tools', () {
    final game = gatheringGame(state: supplies());
    expect(game.craft('charcoal'), isTrue);
    expect(game.state.resource('charcoal'), 6);
    expect(game.state.tools, isNot(contains('charcoal')));
    game.continueFromReport();
    expect(game.craft('charcoal'), isTrue);
    expect(game.state.resource('charcoal'), 8);
  });
  test('antidote extra water and daytime costs are paid once', () {
    final game = gatheringGame(state: supplies());
    expect(game.craft('antidote'), isTrue);
    expect(game.state.value(SurvivalStat.water), 70);
    expect(game.state.resource('antidote'), 3);
    final before = game.state.toJson();
    expect(game.craft('antidote'), isFalse);
    expect(game.state.toJson(), before);
  });
  test(
    'roots prepare in batches of at most three; toxic species stay toxic',
    () {
      final game = gatheringGame(state: supplies());
      expect(game.prepareRoots(), isTrue);
      expect(game.state.resource('ribbon_root'), 1);
      expect(game.state.resource('cooked_root'), 3);
      game.continueFromReport();
      expect(game.consume('mooncap'), isTrue);
      expect(game.state.condition(ConditionKind.poisoned)!.severity, 2);
      expect(game.state.knownSpecies, contains('mooncap'));
    },
  );
  test('studying consumes one sample and one time without eating it', () {
    final game = gatheringGame(state: supplies());
    expect(game.studySpecies('mooncap'), isTrue);
    expect(game.state.resource('mooncap'), 1);
    expect(game.state.value(SurvivalStat.food), 72);
    expect(game.state.hasCondition(ConditionKind.poisoned), isFalse);
    expect(game.state.knownSpecies, contains('mooncap'));
  });
  test(
    'new foraging stores species; old saved sessions retain legacy safety',
    () {
      final game = gatheringGame(state: supplies(tools: {'stone_knife'}));
      game.openGathering(GatheringKind.foraging);
      game.beginGathering();
      expect(game.pickGatheringPlant('mooncap'), isTrue);
      game.finishGathering();
      expect(game.state.resource('mooncap'), 3);
      expect(game.state.hasCondition(ConditionKind.poisoned), isFalse);
      final legacy = GatheringSession(GatheringKind.foraging).toJson()
        ..remove('ecology')
        ..remove('windowScale');
      expect(GatheringSession.fromJson(legacy).ecology, isFalse);
    },
  );
  test('minigame timing modifier is frozen and serialized', () {
    final game = gatheringGame(
      state: supplies(
        tools: {'stone_axe'},
        conditions: [
          const SurvivalCondition(ConditionKind.injured, 1),
          const SurvivalCondition(ConditionKind.exhausted, 1),
        ],
      ),
    );
    game.openGathering(GatheringKind.chopping);
    game.beginGathering();
    expect(game.state.conditions, isEmpty);
    expect(game.gathering!.windowScale, closeTo(.765, .0001));
    final copy = gatheringGame();
    expect(copy.restore(gatheringSave(game)), isTrue);
    expect(copy.gathering!.windowScale, game.gathering!.windowScale);
  });
  test(
    'sleep has two status ticks, no duplicate daytime cost, and no poison healing',
    () {
      final game = gatheringGame(
        state: supplies(
          conditions: [
            const SurvivalCondition(ConditionKind.poisoned, 1),
            const SurvivalCondition(ConditionKind.exhausted, 4),
          ],
        ).copyWith(phase: RunPhase.night, timeLeft: 0),
      );
      final save = gatheringSave(game)..['nightResolved'] = true;
      expect(game.restore(save), isTrue);
      expect(game.sleep(), isTrue);
      expect(game.state.value(SurvivalStat.health), 78);
      expect(game.state.value(SurvivalStat.water), 67);
      expect(game.state.value(SurvivalStat.food), 65);
      expect(game.state.conditions, isEmpty);
      final dawn = jsonEncode(game.state.toJson());
      game.continueFromReport();
      expect(jsonEncode(game.state.toJson()), dawn);
    },
  );
  test(
    'legacy run saves without ecology fields restore with no conditions',
    () {
      final game = gatheringGame();
      final save = gatheringSave(game);
      for (final key in [
        'conditions',
        'knownSpecies',
        'exposure',
        'strain',
        'worldFlags',
      ]) {
        (save['state'] as Map).remove(key);
      }
      expect(game.restore(save), isTrue);
      expect(game.state.conditions, isEmpty);
      expect(game.state.knownSpecies, {'ember_berries'});
    },
  );
}
