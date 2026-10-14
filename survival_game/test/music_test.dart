import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_game/audio/music_controller.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/main.dart';

import 'game/gathering_test.dart' show gatheringGame;
import 'gathering_widget_test.dart' show press;
import 'widget_test.dart' show testGame;

class FakeMusicPlayer implements MusicPlayer {
  final loads = <MusicTrack>[];
  final gains = <double>[];
  bool playing = false, disposed = false, failLoad = false;
  int starts = 0;
  Completer<void>? blockedLoad;
  @override
  Future<void> load(MusicTrack track) async {
    loads.add(track);
    if (failLoad) throw StateError('decoder unavailable');
    await blockedLoad?.future;
  }

  @override
  Future<void> volume(double value) async {
    gains.add(value);
  }

  @override
  void start() {
    playing = true;
    starts++;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    playing = false;
  }
}

class MemoryMusicSettings implements MusicSettingsStore {
  MemoryMusicSettings(this.settings);
  MusicSettings settings;
  @override
  Future<MusicSettings> load() async => settings;
  @override
  Future<void> save(MusicSettings value) async {
    settings = value;
  }
}

void main() {
  test('camp and map choose different music; night stays calm', () {
    final game = testGame();
    expect(musicForGame(game), MusicTrack.camp);
    expect(musicForGame(game, mapOpen: true), MusicTrack.mainTheme);
    expect(
      musicForGame(testGame(state: RunState(phase: RunPhase.night))),
      MusicTrack.camp,
    );
  });
  test('encounter and rescue storm use action; game over is silent', () {
    final game = testGame();
    final saved = jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;
    saved['pendingEvent'] = game.catalog.events
        .firstWhere((e) => e.trigger == 'encounter')
        .id;
    expect(game.restore(saved), isTrue);
    expect(musicForGame(game), MusicTrack.action);
    final storm = testGame(
      state: RunState.fromJson({
        ...RunState().toJson(),
        'rescueStage': 'storm',
      }),
    );
    expect(musicForGame(storm), MusicTrack.action);
    expect(
      musicForGame(testGame(state: RunState(phase: RunPhase.gameOver))),
      isNull,
    );
  });
  test('gathering is main music; hunting START switches to action', () {
    final game = gatheringGame();
    game.openGathering(GatheringKind.hunting);
    expect(musicForGame(game), MusicTrack.mainTheme);
    game.beginGathering();
    expect(musicForGame(game), MusicTrack.action);
    game.finishGathering(leave: true);
    expect(musicForGame(game), MusicTrack.camp);
  });
  test(
    'transactions preserve autosave and do not reload or restart same track',
    () async {
      final game = gatheringGame();
      var saves = 0;
      game.onChanged = () => saves++;
      final player = FakeMusicPlayer();
      final music = MusicController(player: player, fadeStep: Duration.zero);
      music.attach(game);
      await music.initialize();
      await music.settled;
      expect(player.loads, [MusicTrack.camp]);
      game.startAction(CampAction.rest);
      await music.settled;
      expect(saves, 1);
      expect(player.loads, [MusicTrack.camp]);
      expect(player.starts, 1);
      music.dispose();
    },
  );
  test(
    'scene changes fade through zero before new track; gains stay bounded',
    () async {
      final player = FakeMusicPlayer();
      final music = MusicController(player: player, fadeStep: Duration.zero);
      music.attach(testGame());
      await music.initialize();
      await music.settled;
      music.setMapOpen(true);
      await music.settled;
      expect(player.loads, [MusicTrack.camp, MusicTrack.mainTheme]);
      expect(player.gains, contains(0));
      expect(player.gains.every((v) => v >= 0 && v <= .35), isTrue);
      expect(player.gains.last, closeTo(.35, .0001));
      music.dispose();
    },
  );
  test(
    'mute and volume survive reopening and mute avoids loading audio',
    () async {
      final store = MemoryMusicSettings(
        const MusicSettings(enabled: false, volume: .6),
      );
      final player = FakeMusicPlayer();
      final music = MusicController(
        player: player,
        store: store,
        fadeStep: Duration.zero,
      );
      await music.initialize();
      await music.settled;
      expect(player.loads, isEmpty);
      music.setEnabled(true);
      await music.settled;
      expect(player.playing, isTrue);
      music.setVolume(.2);
      music.setEnabled(false);
      await music.settled;
      expect(player.playing, isFalse);
      final second = MusicController(
        player: FakeMusicPlayer(),
        store: store,
        fadeStep: Duration.zero,
      );
      await second.initialize();
      await second.settled;
      expect(second.enabled, isFalse);
      expect(second.volume, .2);
      music.dispose();
      second.dispose();
    },
  );
  test(
    'background pauses; resume continues same file; rapid routes coalesce',
    () async {
      final player = FakeMusicPlayer();
      final music = MusicController(player: player, fadeStep: Duration.zero);
      music.attach(testGame());
      await music.initialize();
      await music.settled;
      music.setForeground(false);
      await music.settled;
      expect(player.playing, isFalse);
      music.setMapOpen(true);
      music.setMapOpen(false);
      music.setForeground(true);
      await music.settled;
      expect(player.loads, [MusicTrack.camp]);
      expect(player.playing, isTrue);
      music.dispose();
    },
  );
  test('mute during slow load never starts stale music', () async {
    final player = FakeMusicPlayer()..blockedLoad = Completer<void>();
    final music = MusicController(player: player, fadeStep: Duration.zero);
    await music.initialize();
    for (var i = 0; i < 10 && player.loads.isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(player.loads, isNotEmpty);
    music.setEnabled(false);
    player.blockedLoad!.complete();
    await music.settled;
    expect(player.starts, 0);
    expect(player.playing, isFalse);
    music.dispose();
  });
  test(
    'audio failure does not stop gameplay and disposal removes listener',
    () async {
      final player = FakeMusicPlayer()..failLoad = true;
      final music = MusicController(player: player, fadeStep: Duration.zero);
      final game = testGame();
      music.attach(game);
      await music.initialize();
      await music.settled;
      expect(music.available, isFalse);
      expect(game.startAction(CampAction.rest), isTrue);
      music.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(player.disposed, isTrue);
      expect(game.continueFromReport(), isTrue);
    },
  );
  test('preference keys are independent of the run save', () async {
    SharedPreferences.setMockInitialValues({
      'lost_canopy.run': 'original-save',
    });
    final prefs = PreferencesMusicSettings();
    await prefs.save(const MusicSettings(enabled: false, volume: .7));
    final result = await prefs.load();
    expect(result.enabled, isFalse);
    expect(result.volume, .7);
    expect(
      (await SharedPreferences.getInstance()).getString('lost_canopy.run'),
      'original-save',
    );
  });
  test('all three bundled MP3s match supplied source files', () {
    final yaml = File('pubspec.yaml').readAsStringSync();
    expect(yaml, contains('assets/music/'));
    for (final track in MusicTrack.values) {
      expect(
        File(track.asset).readAsBytesSync(),
        File('../music/${track.file}.mp3').readAsBytesSync(),
      );
    }
  });
  testWidgets(
    'camp music controls persist mute and map switches main then camp',
    (tester) async {
      final player = FakeMusicPlayer();
      final music = MusicController(player: player, fadeStep: Duration.zero);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(LostCanopyApp(engine: testGame(), music: music));
      await tester.pumpAndSettle();
      await music.settled;
      expect(music.selectedTrack, MusicTrack.camp);
      await press(tester, 'camp-menu', settle: true);
      await press(tester, 'music-enabled', settle: true);
      await music.settled;
      expect(music.enabled, isFalse);
      expect(player.playing, isFalse);
      await press(tester, 'music-enabled', settle: true);
      await music.settled;
      await press(tester, 'close-dialog', settle: true);
      await press(tester, 'open-map', settle: true);
      await music.settled;
      expect(music.selectedTrack, MusicTrack.mainTheme);
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
      await music.settled;
      expect(music.selectedTrack, MusicTrack.camp);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      music.dispose();
    },
  );
}
