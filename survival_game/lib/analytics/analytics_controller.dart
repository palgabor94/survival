import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AnalyticsSink {
  Future<void> configure(bool enabled, String? playerId);
  Future<void> send(String name, Map<String, Object> parameters);
  Future<void> reset();
}

/// A bounded local journal doubles as an outbox. Events carry stable IDs so
/// exports can remove retries; SDK acceptance is not server acknowledgement.
class AnalyticsController extends ChangeNotifier {
  AnalyticsController({
    required this.sink,
    required this.preferences,
    DateTime Function()? clock,
    String Function()? newId,
  }) : clock = clock ?? DateTime.now,
       newId = newId ?? randomId;
  static const storageKey = 'lost_canopy.analytics.v1';
  static const capacity = 2000;
  final AnalyticsSink sink;
  final SharedPreferences preferences;
  final DateTime Function() clock;
  final String Function() newId;
  bool? consent;
  String? playerId;
  String sessionId = '';
  String screen = 'startup';
  String backendStatus = 'not_configured';
  bool foreground = true;
  bool _started = false, _disposed = false;
  DateTime? _screenSince, _lastInteraction;
  Timer? _timer;
  Future<void> _queue = Future.value();
  bool _flushing = false, _dirty = false;
  final List<Map<String, dynamic>> _events = [];
  Map<String, Object> context = {};
  int _sequence = 0;
  int dropped = 0;
  bool get enabled => consent == true;
  int get queued => _events.where((e) => e['sent'] != true).length;
  List<Map<String, dynamic>> get journal => _events
      .map((e) => Map<String, dynamic>.from(jsonDecode(jsonEncode(e)) as Map))
      .toList();
  static String randomId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> initialize({bool heartbeat = true}) async {
    Map<String, dynamic>? previous;
    try {
      final raw = preferences.getString(storageKey);
      if (raw != null) {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        consent = saved['consent'] as bool?;
        playerId = saved['player_id'] as String?;
        previous = saved['checkpoint'] as Map<String, dynamic>?;
        dropped = (saved['dropped'] as num?)?.toInt() ?? 0;
        if (enabled) {
          _events.addAll(
            (saved['events'] as List? ?? []).cast<Map<String, dynamic>>().take(
              capacity,
            ),
          );
        }
      }
    } catch (_) {
      // Telemetry corruption cannot block the game or grant consent.
      consent = null;
      playerId = null;
      _events.clear();
    }
    if (enabled) playerId ??= newId();
    sessionId = newId();
    _started = true;
    _screenSince = clock();
    _lastInteraction = clock();
    await _configure();
    if (enabled) {
      track('session_start', {'recovered': previous == null ? 0 : 1});
      if (previous != null) {
        track('session_interrupted', {
          'previous_session': '${previous['session_id'] ?? ''}',
          'last_screen': '${previous['screen'] ?? 'unknown'}',
          'last_state': '${previous['state'] ?? 'unknown'}',
          'last_seen': '${previous['at'] ?? ''}',
        });
      }
    }
    if (heartbeat && !_disposed) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => pulse());
    }
    await flush();
  }

  Future<void> _configure() async {
    try {
      await sink
          .configure(enabled, playerId)
          .timeout(const Duration(seconds: 3));
      backendStatus = 'ready';
    } catch (_) {
      backendStatus = 'not_configured';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setConsent(bool value) async {
    if (consent == value) return;
    consent = value;
    if (value) {
      playerId ??= newId();
      _screenSince = clock();
      _lastInteraction = clock();
    } else {
      _events.clear();
      playerId = null;
      context.clear();
    }
    await _configure();
    if (!value) {
      try {
        await sink.reset();
      } catch (_) {}
    } else {
      track('consent_granted', {});
      track('session_start', {'recovered': 0});
    }
    await flush();
    if (!_disposed) notifyListeners();
  }

  /// Removes the device journal and rotates identity. Already exported cloud
  /// data requires a separate administrator deletion by the old player ID.
  Future<void> eraseLocalData() async {
    await setConsent(false);
    _events.clear();
    playerId = null;
    dropped = 0;
    await flush();
  }

  void track(String event, Map<String, Object> values) {
    if (!enabled || !_started || _disposed) return;
    if (!RegExp(r'^[a-z][a-z0-9_]{0,35}$').hasMatch(event)) return;
    final params = <String, Object>{
      ...Map.fromEntries(context.entries.take(9)),
      ...Map.fromEntries(values.entries.take(10)),
      'schema_version': 1,
      'client_time_ms': clock().toUtc().millisecondsSinceEpoch,
      'session_id': sessionId,
      'screen': screen,
      'event_id': newId(),
      'event_index': ++_sequence,
    };
    // Firebase accepts at most 25 parameters, scalar numbers/strings only.
    final clean = <String, Object>{};
    for (final entry in params.entries) {
      if (clean.length >= 25) break;
      if (!RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(entry.key)) continue;
      final v = entry.value;
      if (v is num && v.isFinite) clean[entry.key] = v;
      if (v is String) clean[entry.key] = v.substring(0, min(v.length, 100));
    }
    _events.add({
      'name': 'lc_$event',
      'at': clock().toUtc().toIso8601String(),
      'player_id': playerId,
      'parameters': clean,
      'sent': false,
    });
    if (_events.length > capacity) {
      _events.removeAt(0);
      dropped++;
    }
    // Ordered checkpoint writes, including a failed backend. Never await from
    // gameplay transactions and never call the game's random generator.
    unawaited(flush());
  }

  void showScreen(String name) {
    if (screen == name) return;
    _dwell();
    final previous = screen;
    screen = name;
    _screenSince = clock();
    track('screen_view', {'previous_screen': previous});
  }

  void _dwell() {
    final since = _screenSince;
    if (foreground && since != null) {
      final ms = max(0, clock().difference(since).inMilliseconds);
      if (ms > 0) track('screen_time', {'duration_ms': ms});
    }
    _screenSince = clock();
  }

  void interact(String target, {int? x, int? y, String gesture = 'tap'}) {
    _lastInteraction = clock();
    track('interaction', {
      'target': target,
      'gesture': gesture,
      'x_percent': ?x,
      'y_percent': ?y,
    });
  }

  void pulse() {
    if (!foreground) return;
    _dwell();
    track('heartbeat', {
      'idle_seconds': _lastInteraction == null
          ? 0
          : max(0, clock().difference(_lastInteraction!).inSeconds),
    });
  }

  void setForeground(bool value) {
    if (foreground == value) return;
    if (!value) _dwell();
    foreground = value;
    if (value) _lastInteraction = clock();
    _screenSince = clock();
    track(value ? 'app_foreground' : 'app_background', {});
    unawaited(flush());
  }

  Future<void> flush() {
    _dirty = true;
    if (_flushing) return _queue;
    _flushing = true;
    _queue = _queue.then((_) async {
      try {
        do {
          _dirty = false;
          await _persist();
          if (enabled && backendStatus == 'ready') {
            for (final e in _events.where((e) => e['sent'] != true).toList()) {
              if (!enabled) break;
              try {
                await sink.send(
                  e['name'] as String,
                  Map<String, Object>.from(e['parameters'] as Map),
                );
                e['sent'] = true;
              } catch (_) {
                break;
              }
            }
          }
          await _persist();
        } while (_dirty);
      } catch (_) {
        /* Telemetry failure cannot escape to gameplay. */
      } finally {
        _flushing = false;
      }
    });
    return _queue;
  }

  Future<void> _persist() async {
    await preferences.setString(
      storageKey,
      jsonEncode({
        'consent': consent,
        'player_id': playerId,
        'dropped': dropped,
        'events': enabled ? _events : [],
        'checkpoint': enabled
            ? {
                'session_id': sessionId,
                'screen': screen,
                'state': foreground ? 'foreground' : 'background',
                'at': clock().toUtc().toIso8601String(),
              }
            : null,
      }),
    );
  }

  String exportJsonLines() => _events.map(jsonEncode).join('\n');
  @override
  void dispose() {
    _dwell();
    _timer?.cancel();
    unawaited(flush());
    _disposed = true;
    super.dispose();
  }
}
