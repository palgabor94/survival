import 'dart:math';

enum GatheringKind {
  chopping(
    'wood_chopping',
    'Wood chopping',
    'stone_axe',
    'wood_chopping_background_v1',
  ),
  foraging('foraging', 'Foraging', 'stone_knife', 'foraging_background_v1'),
  hunting('hunting', 'Hunting', 'stone_spear', 'hunting_background_v1');

  const GatheringKind(this.id, this.title, this.art, this.scene);
  final String id, title, art, scene;
  static GatheringKind? fromId(String? id) {
    for (final kind in values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

enum GatheringStage { ready, active, complete }

enum TimingQuality { miss, good, perfect }

/// A bounded, serializable attempt. Rewards are committed by GameEngine only.
/// Random plant safety is drawn once, then saved; reopening cannot reroll it.
class GatheringSession {
  GatheringSession(this.kind, {Random? random}) {
    final source = random ?? Random();
    mushroomSafe = source.nextDouble() >= .25;
    unknownSafe = source.nextDouble() >= .65;
  }
  final GatheringKind kind;
  GatheringStage stage = GatheringStage.ready;
  bool paused = false;
  bool abandoned = false;
  bool timedOut = false;
  bool mushroomSafe = true, unknownSafe = false;
  double elapsed = 0;
  double feedbackLeft = 0;
  TimingQuality? lastQuality;
  final List<TimingQuality> _hits = [];
  final Set<String> _picked = {};
  List<TimingQuality> get hits => List.unmodifiable(_hits);
  Set<String> get picked => Set.unmodifiable(_picked);
  bool get complete => stage == GatheringStage.complete;
  bool get active => stage == GatheringStage.active && !paused;
  double get duration => kind == GatheringKind.foraging ? 8 : 12;
  double get remaining => max(0, duration - elapsed);
  double get marker {
    final period = kind == GatheringKind.hunting ? 1.8 : 1.6;
    final phase = (elapsed % period) / period;
    return phase < .5 ? phase * 2 : (1 - phase) * 2;
  }

  TimingQuality get currentQuality {
    final distance = (marker - .5).abs();
    return distance <= .06
        ? TimingQuality.perfect
        : distance <= .18
        ? TimingQuality.good
        : TimingQuality.miss;
  }

  bool start() {
    if (stage != GatheringStage.ready) return false;
    stage = GatheringStage.active;
    return true;
  }

  void update(double seconds) {
    if (!active || !seconds.isFinite || seconds <= 0) return;
    elapsed = min(duration, elapsed + seconds);
    feedbackLeft = max(0, feedbackLeft - seconds);
    if (elapsed >= duration) {
      timedOut = true;
      stage = GatheringStage.complete;
    }
  }

  bool strike() {
    if (!active || kind == GatheringKind.foraging || feedbackLeft > 0) {
      return false;
    }
    lastQuality = currentQuality;
    _hits.add(lastQuality!);
    feedbackLeft = .5;
    if (kind == GatheringKind.hunting || _hits.length == 3) {
      stage = GatheringStage.complete;
    }
    return true;
  }

  static const plants = [
    'berries',
    'fiber',
    'herb',
    'mushroom',
    'unknown_plant',
  ];
  static String? plantBlock(String id, Set<String> tools) => switch (id) {
    'herb' || 'mushroom' =>
      tools.contains('stone_knife') || tools.contains('machete')
          ? null
          : 'Knife required',
    'unknown_plant' => tools.contains('machete') ? null : 'Machete required',
    _ => null,
  };
  bool pick(String id, Set<String> tools) {
    if (!active ||
        kind != GatheringKind.foraging ||
        !plants.contains(id) ||
        plantBlock(id, tools) != null ||
        _picked.length >= 3 ||
        _picked.contains(id)) {
      return false;
    }
    _picked.add(id);
    return true;
  }

  bool finish({bool leave = false}) {
    if (stage != GatheringStage.active) return false;
    if (!leave && kind != GatheringKind.foraging) return false;
    abandoned = leave;
    stage = GatheringStage.complete;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'stage': stage.name,
    'elapsed': elapsed,
    'paused': paused,
    'abandoned': abandoned,
    'timedOut': timedOut,
    'mushroomSafe': mushroomSafe,
    'unknownSafe': unknownSafe,
    'feedbackLeft': feedbackLeft,
    'lastQuality': lastQuality?.name,
    'hits': _hits.map((hit) => hit.name).toList(),
    'picked': _picked.toList(),
  };
  factory GatheringSession.fromJson(Map<String, dynamic> json) {
    final session = GatheringSession(
      GatheringKind.values.byName(json['kind'] as String),
      random: Random(0),
    );
    session.stage = GatheringStage.values.byName(json['stage'] as String);
    session.elapsed = (json['elapsed'] as num).toDouble().clamp(
      0,
      session.duration,
    );
    session.paused = session.stage == GatheringStage.active;
    session.abandoned = json['abandoned'] as bool;
    session.timedOut = json['timedOut'] as bool;
    session.mushroomSafe = json['mushroomSafe'] as bool;
    session.unknownSafe = json['unknownSafe'] as bool;
    session.feedbackLeft = (json['feedbackLeft'] as num).toDouble().clamp(
      0,
      .5,
    );
    session.lastQuality = json['lastQuality'] == null
        ? null
        : TimingQuality.values.byName(json['lastQuality'] as String);
    session._hits.addAll(
      (json['hits'] as List).map(
        (v) => TimingQuality.values.byName(v as String),
      ),
    );
    session._picked.addAll(List<String>.from(json['picked'] as List));
    if (session._hits.length > 3 ||
        session._picked.length > 3 ||
        !session._picked.every(plants.contains)) {
      throw const FormatException('Invalid gathering progress');
    }
    return session;
  }
}
