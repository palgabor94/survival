import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/game_engine.dart';
import 'package:survival_game/game/event_catalog.dart';
import 'package:survival_game/game/crafting.dart';
import 'package:survival_game/game/world_catalog.dart';
import 'package:survival_game/game/run_state.dart';

GameEngine tutorialGame({bool offer = true}) => GameEngine(
  EventCatalog.fromJson(File('assets/data/events.json').readAsStringSync()),
  world: WorldCatalog.fromJson(
    File('assets/data/locations.json').readAsStringSync(),
  ),
  recipes: RecipeCatalog.fromJson(
    File('assets/data/recipes.json').readAsStringSync(),
  ),
  random: Random(42),
  offerFirstRunGuide: offer,
);
GameEngine reloadGuide(GameEngine g) {
  final next = tutorialGame();
  expect(next.restore(g.toJson()), isTrue);
  return next;
}

GameEngine guidedGather() {
  final g = tutorialGame();
  g.decideFirstRunGuide(true);
  expect(g.startAction(CampAction.forage), isTrue);
  expect(g.pendingEvent!.id, 'berry_patch');
  expect(g.tutorial.completed, isEmpty);
  expect(g.choose('gather'), isTrue);
  g.continueFromReport();
  return g;
}

void main() {
  test(
    'first-day tutorial only offers once across skip reload and restart',
    () {
      var g = tutorialGame();
      expect(g.tutorial.welcomePending, isTrue);
      final stats = g.state.stats, supplies = g.state.resources;
      g.decideFirstRunGuide(false);
      expect(g.state.stats, stats);
      expect(g.state.resources, supplies);
      g = reloadGuide(g);
      expect(g.tutorial.welcomePending, isFalse);
      expect(g.tutorial.active, isFalse);
      g.restart();
      expect(g.tutorial.welcomePending, isFalse);
      expect(g.profile.firstRunGuideHandled, isTrue);
    },
  );
  test('first-day tutorial old active saves do not get a welcome', () {
    final save = tutorialGame().toJson()..remove('tutorial');
    (save['profile'] as Map).remove('firstRunGuideHandled');
    final g = tutorialGame();
    expect(g.restore(save), isTrue);
    expect(g.tutorial.welcomePending, isFalse);
    expect(g.profile.firstRunGuideHandled, isTrue);
    g.restart();
    expect(g.tutorial.welcomePending, isFalse);
  });
  test('first-day tutorial survives reload before welcome choice', () {
    final g = reloadGuide(tutorialGame());
    expect(g.tutorial.welcomePending, isTrue);
    g.decideFirstRunGuide(true);
    expect(reloadGuide(g).tutorial.active, isTrue);
  });
  test(
    'first-day tutorial complete real normal-cost day with mid-step reloads',
    () {
      var g = guidedGather();
      expect(g.tutorial.next, 'eat');
      expect(g.state.resource('ember_berries'), 2);
      g = reloadGuide(g);
      expect(g.consume('ember_berries'), isTrue);
      g.continueFromReport();
      expect(g.tutorial.next, 'craft');
      expect(g.craft('torch'), isTrue);
      g.continueFromReport();
      expect(g.tutorial.next, 'pack');
      expect(g.state.timeLeft, 4);
      expect(g.beginPacking('riverbank'), isTrue);
      expect(g.tutorial.next, 'pack'); // Opening/cancelling is not departure.
      g.cancelPacking();
      expect(g.beginPacking('riverbank'), isTrue);
      expect(
        g.updatePacking({'ember_berries': 1, 'herb': 1}, {'torch'}),
        isTrue,
      );
      expect(g.leaveCamp(), isTrue);
      expect(g.pendingEvent!.id, 'river_supplies');
      g = reloadGuide(g);
      expect(g.tutorial.next, 'return');
      expect(g.choose('rod_materials'), isTrue);
      expect(g.choose('rod_materials'), isFalse); // No duplicate tutorial loot.
      g.continueFromReport();
      expect(g.returnHome(), isTrue);
      g.continueFromReport();
      expect(g.state.inField, isFalse);
      expect(g.state.packResources, isEmpty);
      expect(g.tutorial.next, 'night');
      for (var i = 0; i < 2; i++) {
        expect(g.startAction(CampAction.rest), isTrue);
        g.continueFromReport();
      }
      expect(g.pendingEvent!.id, 'fire_dying');
      expect(g.choose('torch'), isTrue);
      g.continueFromReport();
      expect(g.sleep(), isTrue);
      expect(g.state.day, 2);
      expect(g.tutorial.complete, isTrue);
      expect(g.metrics.nights, 1);
      expect(g.profile.xp, 0); // Tutorial has no separate XP award.
      g = reloadGuide(g);
      expect(g.tutorial.complete, isTrue);
      expect(g.tutorial.completionRead, isFalse);
      g.acknowledgeGuideCompletion();
      expect(reloadGuide(g).profile.completedFirstDay, isTrue);
      g.restart();
      expect(g.tutorial.welcomePending, isFalse);
      expect(g.tutorial.active, isFalse);
    },
  );
  test(
    'first-day tutorial later skip resume preserve actual checkpoint progress',
    () {
      var g = guidedGather();
      g.collapseGuide(true);
      g = reloadGuide(g);
      expect(g.tutorial.collapsed, isTrue);
      g.skipGuide();
      g = reloadGuide(g);
      expect(g.tutorial.active, isFalse);
      expect(g.tutorial.completed, {'gather'});
      g.resumeGuide();
      expect(g.tutorial.next, 'eat');
      expect(g.tutorial.active, isTrue);
      expect(g.tutorial.collapsed, isFalse);
      expect(g.craft('stone_axe'), isFalse);
      expect(g.tutorial.completed.contains('craft'), isFalse);
    },
  );
  test('first-day tutorial fixed opener cannot repeat after reload', () {
    var g = guidedGather();
    g = reloadGuide(g);
    expect(g.tutorial.openers, {'berry_patch'});
    expect(g.startAction(CampAction.forage), isTrue);
    expect(g.pendingEvent!.id, isNot('berry_patch'));
    expect(g.tutorial.openers.length, 1);
  });
}
