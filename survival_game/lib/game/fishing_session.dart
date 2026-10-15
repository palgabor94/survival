import 'dart:math';

enum FishingStage { ready, waiting, bite, reeling, caught, escaped }

enum CatchQuality { missed, good, perfect }

/// Simulation is independent of frame rate and Flutter. Time only advances
/// through update; callers pause updates while backgrounded or showing a dialog.
class FishingSession {
  FishingSession({Random? random, this.zoneScale = 1}) {
    final rng = random ?? Random();
    _biteDelay = 1.4 + rng.nextDouble() * 1.4;
    _wavePhase = rng.nextDouble() * pi * 2;
  }
  final double zoneScale;
  double get effectiveZoneHalfWidth => zoneHalfWidth * zoneScale;
  FishingStage stage = FishingStage.ready;
  CatchQuality quality = CatchQuality.missed;
  late final double _biteDelay, _wavePhase;
  double _phaseTime = 0;
  double _inZoneTime = 0;
  double _reeledTime = 0;
  double _hookReaction = 1;
  double cursor = .48;
  double target = .5;
  double progress = .3;
  bool holding = false;
  static const double zoneHalfWidth = .18;
  static const double biteWindow = 2;
  static const double reelDuration = 8;
  bool get complete =>
      stage == FishingStage.caught || stage == FishingStage.escaped;
  bool get inZone => (cursor - target).abs() <= effectiveZoneHalfWidth;
  double get remaining => stage == FishingStage.bite
      ? max(0, biteWindow - _phaseTime)
      : max(0, reelDuration - _phaseTime);

  bool cast() {
    if (stage != FishingStage.ready) return false;
    stage = FishingStage.waiting;
    _phaseTime = 0;
    return true;
  }

  bool hook() {
    if (stage != FishingStage.bite) return false;
    _hookReaction = _phaseTime;
    _phaseTime = 0;
    stage = FishingStage.reeling;
    // Start together instead of jumping the fish away on the first reel frame.
    cursor = target = .5 + .25 * sin(_wavePhase);
    return true;
  }

  void update(double seconds) {
    if (!seconds.isFinite ||
        seconds <= 0 ||
        complete ||
        stage == FishingStage.ready) {
      return;
    }
    // Fixed substeps make the reel outcome consistent across display refresh rates.
    var remaining = seconds;
    while (remaining > 0 && !complete) {
      final dt = min(remaining, 1 / 120);
      remaining -= dt;
      _phaseTime += dt;
      if (stage == FishingStage.waiting && _phaseTime >= _biteDelay) {
        stage = FishingStage.bite;
        _phaseTime = 0;
      } else if (stage == FishingStage.bite && _phaseTime >= biteWindow) {
        abandon();
      } else if (stage == FishingStage.reeling) {
        target = .5 + .25 * sin(_phaseTime * 1.2 + _wavePhase);
        cursor = (cursor + (holding ? .40 : -.28) * dt).clamp(0, 1);
        if (holding) _reeledTime += dt;
        if (inZone) _inZoneTime += dt;
        // Drifting with the fish alone is not a catch: the player must reel.
        progress = (progress + (inZone ? .30 : -.16) * dt).clamp(
          0,
          _reeledTime >= .2 ? 1 : .95,
        );
        if (progress >= 1) {
          quality = _hookReaction <= .45 && _inZoneTime / _phaseTime >= .8
              ? CatchQuality.perfect
              : CatchQuality.good;
          stage = FishingStage.caught;
          holding = false;
        } else if (_phaseTime >= reelDuration || progress <= 0) {
          abandon();
        }
      }
    }
  }

  void abandon() {
    if (complete) return;
    stage = FishingStage.escaped;
    quality = CatchQuality.missed;
    holding = false;
  }
}
