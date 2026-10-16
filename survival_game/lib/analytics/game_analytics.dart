import '../game/game_engine.dart';
import '../game/run_state.dart';
import 'analytics_controller.dart';

/// Observes semantic state transitions once, not individual animation ticks.
class GameAnalytics {
  GameAnalytics(this.analytics, this.game) {
    _run = game.metrics.id;
    game.addListener(_changed);
    game.addTelemetryListener(_event);
    _changed();
    analytics.track('run_loaded', {
      'journey_started': game.journeyStarted ? 1 : 0,
    });
  }
  final AnalyticsController analytics;
  final GameEngine game;
  String? _run, _eventId, _conditions, _lesson;
  int? _tier, _day;
  void _context() {
    analytics.context = {
      'run_id': game.metrics.id,
      'day': game.state.day,
      'location': game.state.locationId,
      'phase': game.state.phase.name,
      'camp_tier': game.state.campTier,
      for (final stat in SurvivalStat.values) stat.name: game.state.value(stat),
    };
  }

  void _event(String name, Map<String, Object> values) {
    _context();
    analytics.track(name, values);
  }

  void _changed() {
    _context();
    if (_run != game.metrics.id) {
      _run = game.metrics.id;
      _eventId = null;
      _tier = null;
      _day = null;
      _conditions = null;
      _lesson = null;
      analytics.track('run_started', {});
    }
    if (_day != game.state.day) {
      _day = game.state.day;
      analytics.track('day_reached', {});
    }
    if (_tier != game.state.campTier) {
      _tier = game.state.campTier;
      analytics.track('camp_tier_reached', {});
    }
    final currentEvent = game.pendingEvent?.id;
    if (_eventId != currentEvent) {
      _eventId = currentEvent;
      if (currentEvent != null) {
        analytics.track('event_presented', {'event': currentEvent});
      }
    }
    final conditions = game.state.conditions.map((c) => c.kind.name).toList()
      ..sort();
    final conditionKey = conditions.join(',');
    if (_conditions != conditionKey) {
      _conditions = conditionKey;
      analytics.track('conditions_changed', {
        'conditions': conditionKey.isEmpty ? 'none' : conditionKey,
      });
    }
    final lesson = '${game.tutorial.toJson()}';
    if (_lesson != lesson) {
      _lesson = lesson;
      analytics.track('tutorial_progress', {
        'complete': game.tutorial.complete ? 1 : 0,
        'next_lesson': game.tutorial.next,
        'lessons_done': game.tutorial.completed.length,
        'skipped': game.tutorial.skipped ? 1 : 0,
      });
    }
  }

  void dispose() {
    game.removeListener(_changed);
    game.removeTelemetryListener(_event);
  }
}
