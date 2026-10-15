/// Run-local learning state. Profile eligibility lives separately so a new
/// journey never silently starts the guide again.
class TutorialProgress {
  TutorialProgress({this.offered = false});
  bool offered, accepted = false, skipped = false, collapsed = false;
  bool completionRead = false;
  final completed = <String>{};
  final openers = <String>{};
  static const steps = ['gather', 'eat', 'craft', 'pack', 'return', 'night'];
  bool get active => accepted && !skipped && !complete;
  bool get complete => steps.every(completed.contains);
  bool get welcomePending => offered && !accepted && !skipped;
  String get next => steps.firstWhere(
    (id) => !completed.contains(id),
    orElse: () => 'complete',
  );
  void learn(String id) {
    if (active) completed.add(id);
  }

  Map<String, dynamic> toJson() => {
    'offered': offered,
    'accepted': accepted,
    'skipped': skipped,
    'collapsed': collapsed,
    'completionRead': completionRead,
    'completed': completed.toList(),
    'openers': openers.toList(),
  };
  factory TutorialProgress.fromJson(Map<String, dynamic> json) {
    final p = TutorialProgress(offered: json['offered'] as bool? ?? false);
    p.accepted = json['accepted'] as bool? ?? false;
    p.skipped = json['skipped'] as bool? ?? false;
    p.collapsed = json['collapsed'] as bool? ?? false;
    p.completionRead = json['completionRead'] as bool? ?? false;
    p.completed.addAll(List<String>.from(json['completed'] as List? ?? []));
    p.openers.addAll(List<String>.from(json['openers'] as List? ?? []));
    if (p.completed.any((id) => !steps.contains(id))) {
      throw const FormatException('Invalid tutorial checkpoint');
    }
    return p;
  }
}
