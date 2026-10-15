/// Conditions advance only when game time is spent, never on a UI timer.
enum ConditionKind { poisoned, injured, wet, exhausted }

class SurvivalCondition {
  const SurvivalCondition(this.kind, this.remaining, {this.severity = 1});
  final ConditionKind kind;
  final int remaining, severity;
  String get label => switch (kind) {
    ConditionKind.poisoned => 'Poisoned ${severity == 2 ? 'II' : 'I'}',
    ConditionKind.injured => 'Injured',
    ConditionKind.wet => 'Wet',
    ConditionKind.exhausted => 'Exhausted',
  };
  String get description => switch (kind) {
    ConditionKind.poisoned =>
      'Loses ${severity * 2} health and $severity extra water per time. Healing is blocked. Use an antidote; bitter herbs shorten the illness.',
    ConditionKind.injured =>
      'Physical risks are harder and new physical hits hurt more. Healing is halved. Use a bandage or rest.',
    ConditionKind.wet =>
      'Loses 1 extra food and sanity per time. Rain refreshes this condition. Dry by the fire or wait under shelter.',
    ConditionKind.exhausted =>
      'Loses 1 extra water and food per time. Physical risks and timing challenges are harder. Rest or sleep.',
  };
  SurvivalCondition withRemaining(int ticks) =>
      SurvivalCondition(kind, ticks, severity: severity);
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'remaining': remaining,
    'severity': severity,
  };
  factory SurvivalCondition.fromJson(Map<String, dynamic> j) =>
      SurvivalCondition(
        ConditionKind.values.byName(j['kind'] as String),
        (j['remaining'] as int).clamp(1, 6),
        severity: (j['severity'] as int? ?? 1).clamp(1, 2),
      );
}
