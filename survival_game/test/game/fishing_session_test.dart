import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/game/fishing_session.dart';

/// Rolls 0 for every draw: the bite arrives after the minimum 1.4 seconds.
class ZeroRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

const frame = 1 / 60;

/// Advances until the fish bites; returns the elapsed seconds.
double waitForBite(FishingSession session) {
  var elapsed = 0.0;
  while (session.stage == FishingStage.waiting && elapsed < 10) {
    session.update(frame);
    elapsed += frame;
  }
  return elapsed;
}

/// A player who holds whenever the marker trails the moving zone.
void reelByTracking(FishingSession session) {
  for (var i = 0; i < 1200 && session.stage == FishingStage.reeling; i++) {
    session.holding = session.cursor < session.target;
    session.update(frame);
  }
}

void main() {
  test('time does not pass before the cast and only one cast is allowed', () {
    final session = FishingSession(random: ZeroRandom());
    session.update(5);
    expect(session.stage, FishingStage.ready);
    expect(session.hook(), isFalse);
    expect(session.cast(), isTrue);
    expect(session.cast(), isFalse);
    expect(session.stage, FishingStage.waiting);
  });

  test('hooking before the bite does nothing; the bite follows the delay', () {
    final session = FishingSession(random: ZeroRandom())..cast();
    session.update(1);
    expect(session.hook(), isFalse);
    expect(session.stage, FishingStage.waiting);
    session.update(.5);
    expect(session.stage, FishingStage.bite);
  });

  test('bite delay always stays within 1.4 to 2.8 seconds', () {
    for (var seed = 0; seed < 50; seed++) {
      final session = FishingSession(random: Random(seed))..cast();
      final elapsed = waitForBite(session);
      expect(session.stage, FishingStage.bite);
      expect(elapsed, inInclusiveRange(1.4, 2.8 + frame));
    }
  });

  test('missing the bite window lets the fish escape', () {
    final session = FishingSession(random: ZeroRandom())..cast();
    waitForBite(session);
    session.update(FishingSession.biteWindow + .05);
    expect(session.stage, FishingStage.escaped);
    expect(session.quality, CatchQuality.missed);
    expect(session.complete, isTrue);
    expect(session.hook(), isFalse);
  });

  test('a fast hook and steady tracking land a perfect catch', () {
    for (var seed = 0; seed < 20; seed++) {
      final session = FishingSession(random: Random(seed))..cast();
      waitForBite(session);
      session.update(.2);
      expect(session.hook(), isTrue);
      reelByTracking(session);
      expect(session.stage, FishingStage.caught, reason: 'seed $seed');
      expect(session.quality, CatchQuality.perfect, reason: 'seed $seed');
      expect(session.holding, isFalse);
    }
  });

  test('a slow hook still catches, but only a good fish', () {
    final session = FishingSession(random: Random(3))..cast();
    waitForBite(session);
    session.update(.9);
    expect(session.hook(), isTrue);
    reelByTracking(session);
    expect(session.stage, FishingStage.caught);
    expect(session.quality, CatchQuality.good);
  });

  test('never reeling lets the fish escape', () {
    for (var seed = 0; seed < 10; seed++) {
      final session = FishingSession(random: Random(seed))..cast();
      waitForBite(session);
      session.hook();
      for (var i = 0; i < 1200 && !session.complete; i++) {
        session.update(frame);
      }
      expect(session.stage, FishingStage.escaped, reason: 'seed $seed');
      expect(session.quality, CatchQuality.missed);
    }
  });

  test('invalid or paused updates do not advance the simulation', () {
    final session = FishingSession(random: ZeroRandom())..cast();
    for (final dt in [0.0, -1.0, double.nan, double.infinity]) {
      session.update(dt);
    }
    session.update(1.3);
    expect(session.stage, FishingStage.waiting);
  });

  test('one long update matches many short frames', () {
    FishingSession reel(void Function(FishingSession) advance) {
      final session = FishingSession(random: ZeroRandom())..cast();
      session.update(1.5);
      session.hook();
      session.holding = true;
      advance(session);
      return session;
    }

    final chunked = reel((s) => s.update(1));
    final framed = reel((s) {
      for (var i = 0; i < 120; i++) {
        s.update(1 / 120);
      }
    });
    expect(chunked.cursor, closeTo(framed.cursor, 1e-9));
    expect(chunked.progress, closeTo(framed.progress, 1e-9));
    expect(chunked.stage, framed.stage);
  });

  test('abandoning ends the session once as a miss', () {
    final session = FishingSession(random: ZeroRandom())..cast();
    session.holding = true;
    session.abandon();
    expect(session.stage, FishingStage.escaped);
    expect(session.holding, isFalse);
    session.update(5);
    expect(session.stage, FishingStage.escaped);
  });
}
