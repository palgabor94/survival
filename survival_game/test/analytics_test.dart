import 'package:survival_game/main.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_game/analytics/analytics_controller.dart';
import 'package:survival_game/analytics/analytics_ui.dart';
import 'package:survival_game/analytics/game_analytics.dart';
import 'package:survival_game/game/run_state.dart';
import 'widget_test.dart' show testGame;

class FakeAnalyticsSink implements AnalyticsSink {
  bool available = true, enabled = false;
  int resets = 0;
  final events = <String>[];
  @override
  Future<void> configure(bool value, String? playerId) async {
    if (!available) throw StateError('offline');
    enabled = value;
  }

  @override
  Future<void> send(String name, Map<String, Object> parameters) async {
    if (!available) throw StateError('offline');
    if (enabled) events.add(name);
  }

  @override
  Future<void> reset() async {
    resets++;
  }
}

void main() {
  late SharedPreferences prefs;
  late FakeAnalyticsSink sink;
  late AnalyticsController analytics;
  var time = DateTime.utc(2026, 10, 16);
  var ids = 0;
  Future<void> start({bool optIn = true}) async {
    analytics = AnalyticsController(
      sink: sink,
      preferences: prefs,
      clock: () => time,
      newId: () => 'id_${ids++}',
    );
    await analytics.initialize(heartbeat: false);
    if (optIn) await analytics.setConsent(true);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    sink = FakeAnalyticsSink();
    time = DateTime.utc(2026, 10, 16);
    ids = 0;
  });
  tearDown(() {
    analytics.dispose();
  });

  test(
    'nothing collected before consent and opt out clears journal and ID',
    () async {
      await start(optIn: false);
      analytics.track('test', {});
      expect(analytics.journal, isEmpty);
      await analytics.setConsent(true);
      analytics.track('choice', {});
      await analytics.flush();
      expect(sink.events, contains('lc_choice'));
      final firstId = analytics.playerId;
      await analytics.setConsent(false);
      analytics.track('must_not_collect', {});
      await analytics.flush();
      expect(analytics.journal, isEmpty);
      expect(analytics.playerId, isNull);
      final stored = jsonDecode(
        prefs.getString(AnalyticsController.storageKey)!,
      );
      expect(stored['events'], isEmpty);
      expect(stored['checkpoint'], isNull);
      await analytics.setConsent(true);
      expect(analytics.playerId, isNot(firstId));
    },
  );

  test(
    'screen dwell excludes background time and heartbeats reveal idle',
    () async {
      await start();
      analytics.showScreen('camp');
      time = time.add(const Duration(seconds: 10));
      analytics.setForeground(false);
      time = time.add(const Duration(hours: 2));
      analytics.pulse();
      analytics.setForeground(true);
      time = time.add(const Duration(seconds: 5));
      analytics.showScreen('map');
      analytics.pulse();
      final times = analytics.journal.where(
        (e) => e['name'] == 'lc_screen_time',
      );
      expect(times.map((e) => e['parameters']['duration_ms']), [10000, 5000]);
      expect(
        analytics.journal.where((e) => e['name'] == 'lc_heartbeat').length,
        1,
      );
      expect(analytics.journal.last['parameters']['idle_seconds'], 5);
    },
  );

  test(
    'outbox survives backend failure, retries with stable IDs on relaunch',
    () async {
      sink.available = false;
      await start();
      analytics.track('choice', {'choice': 'safe'});
      await analytics.flush();
      final oldId = analytics.playerId;
      final choiceId = analytics.journal.last['parameters']['event_id'];
      analytics.dispose();
      await analytics.flush();
      sink.available = true;
      await start();
      expect(analytics.playerId, oldId);
      expect(sink.events.where((e) => e == 'lc_choice').length, 1);
      expect(
        analytics.journal.firstWhere(
          (e) => e['name'] == 'lc_choice',
        )['parameters']['event_id'],
        choiceId,
      );
      expect(analytics.queued, 0);
      expect(sink.events, contains('lc_session_interrupted'));
      final recovered = analytics.journal.firstWhere(
        (e) => e['name'] == 'lc_session_interrupted',
      );
      expect(recovered['parameters']['last_state'], 'foreground');
    },
  );

  test(
    'game confirms only valid transactions and listeners cannot break gameplay',
    () async {
      await start();
      final game = testGame();
      final observer = GameAnalytics(analytics, game);
      game.addTelemetryListener((_, _) => throw StateError('bad observer'));
      expect(game.craft('does_not_exist'), false);
      expect(game.startAction(CampAction.rest), true);
      expect(game.startAction(CampAction.rest), false);
      await analytics.flush();
      expect(sink.events.where((e) => e == 'lc_action_started').length, 1);
      expect(sink.events.where((e) => e == 'lc_action_result').length, 1);
      expect(sink.events, isNot(contains('lc_craft_started')));
      final result = analytics.journal.firstWhere(
        (e) => e['name'] == 'lc_action_result',
      );
      expect(result['parameters']['run_id'], game.metrics.id);
      expect((result['parameters'] as Map).length, lessThanOrEqualTo(25));
      observer.dispose();
    },
  );

  test(
    'death counted once and restoring an ended run does not replay it',
    () async {
      await start();
      final game = testGame(
        state: RunState(
          stats: {
            SurvivalStat.health: 1,
            SurvivalStat.water: 0,
            SurvivalStat.food: 0,
            SurvivalStat.sanity: 1,
          },
        ),
      );
      final observer = GameAnalytics(analytics, game);
      game.startAction(CampAction.rest);
      game.ensureRunSummary();
      game.ensureRunSummary();
      expect(game.state.isAlive, false);
      await analytics.flush();
      expect(sink.events.where((e) => e == 'lc_run_ended').length, 1);
      observer.dispose();
      final restored = testGame();
      expect(restored.restore(game.toJson()), true);
      final second = GameAnalytics(analytics, restored);
      restored.ensureRunSummary();
      await analytics.flush();
      expect(sink.events.where((e) => e == 'lc_run_ended').length, 1);
      second.dispose();
    },
  );

  test('telemetry leaves deterministic game state unchanged', () async {
    await start();
    final first = testGame(), second = testGame();
    final observer = GameAnalytics(analytics, first);
    first.startAction(CampAction.forage);
    second.startAction(CampAction.forage);
    expect(first.pendingEvent!.id, second.pendingEvent!.id);
    final choice = first.visibleChoices.where(first.canChoose).first;
    first.choose(choice.id);
    second.choose(choice.id);
    expect(first.state.toJson(), second.state.toJson());
    observer.dispose();
  });

  test(
    'excess parameters preserve mandatory IDs and clamp Firebase scalars',
    () async {
      await start();
      analytics.context = {for (var i = 0; i < 40; i++) 'context_$i': i};
      analytics.track('oversized', {
        for (var i = 0; i < 40; i++) 'value_$i': 'x' * 150,
      });
      final p = analytics.journal.last['parameters'] as Map;
      expect(p.length, lessThanOrEqualTo(25));
      expect(p['event_id'], isNotNull);
      expect(p['client_time_ms'], time.millisecondsSinceEpoch);
      expect((p['value_0'] as String).length, 100);
      await analytics.flush();
    },
  );

  test(
    'corrupt telemetry storage fails closed without blocking gameplay',
    () async {
      await prefs.setString(AnalyticsController.storageKey, '{broken');
      await start(optIn: false);
      expect(analytics.consent, isNull);
      expect(analytics.journal, isEmpty);
      expect(sink.events, isEmpty);
    },
  );

  testWidgets('first menu offers consent once and settings remain usable', (
    tester,
  ) async {
    await tester.runAsync(() => start(optIn: false));
    await tester.pumpWidget(
      LostCanopyApp(
        engine: testGame(),
        analytics: analytics,
        showMainMenu: true,
        enableAudio: false,
        enableHaptics: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Help improve Lost Canopy'.toUpperCase()), findsOneWidget);
    await tester.tap(find.text('NO THANKS'));
    await tester.pumpAndSettle();
    expect(analytics.consent, false);
    expect(analytics.journal, isEmpty);
    await tester.ensureVisible(
      find.byKey(const ValueKey('main-menu-settings')),
    );
    await tester.tap(find.byKey(const ValueKey('main-menu-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('analytics-enabled')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'passive targets distinguish taps and swipes without swallowing actions',
    (tester) async {
      await tester.runAsync(() => start());
      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyticsGestures(
            controller: analytics,
            child: Scaffold(
              body: AnalyticsTarget(
                'test_button',
                child: TextButton(
                  onPressed: () => pressed++,
                  child: const Text('Press'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Press'));
      await tester.pump();
      expect(pressed, 1);
      var e = analytics.journal.last;
      expect(e['parameters']['target'], 'test_button');
      expect(e['parameters']['gesture'], 'tap');
      await tester.drag(find.byType(Scaffold), const Offset(100, 0));
      await tester.pump();
      e = analytics.journal.last;
      expect(e['parameters']['gesture'], 'swipe');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
