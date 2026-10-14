import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_game/audio/sounds_controller.dart';
import 'package:survival_game/audio/music_controller.dart';
import 'package:survival_game/game/game_sound.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/main.dart';

import 'game/gathering_test.dart' show gatheringGame, gatheringSave;
import 'gathering_widget_test.dart' show press;
import 'music_test.dart' show FakeMusicPlayer;

class FakeSoundPlayer implements SoundPlayer {
  final loads = <String>[];
  final loops = <bool>[];
  final gains = <double>[];
  bool playing = false, disposed = false, failLoad = false;
  int starts = 0;
  Completer<void>? blockedLoad;
  @override
  Future<void> load(String asset, {required bool loop}) async {
    loads.add(asset);
    loops.add(loop);
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

class SoundRig {
  SoundRig({SoundSettingsStore? store, Duration stepInterval = Duration.zero}) {
    controller = SoundsController(
      ambience: base,
      fire: fire,
      steps: steps,
      chopping: wood,
      store: store,
      fadeStep: Duration.zero,
      stepInterval: stepInterval,
    );
  }
  final base = FakeSoundPlayer(), fire = FakeSoundPlayer();
  final steps = FakeSoundPlayer(), wood = FakeSoundPlayer();
  late final SoundsController controller;
}

class MemorySoundSettings implements SoundSettingsStore {
  MemorySoundSettings(this.settings);
  SoundSettings settings;
  @override
  Future<SoundSettings> load() async => settings;
  @override
  Future<void> save(SoundSettings settings) async {
    this.settings = settings;
  }
}

void main() {
  test('ambience follows day/night, rain/storm, river and visible camp', () {
    expect(ambienceForGame(gatheringGame()), [
      AmbientSound.jungle,
      AmbientSound.campfire,
    ]);
    expect(ambienceForGame(gatheringGame(), mapOpen: true), [
      AmbientSound.jungle,
    ]);
    expect(
      ambienceForGame(gatheringGame(state: RunState(phase: RunPhase.night))),
      [AmbientSound.night, AmbientSound.campfire],
    );
    for (final weather in ['Light rain', 'Storm']) {
      expect(
        ambienceForGame(gatheringGame(state: RunState(weather: weather))),
        [AmbientSound.rain, AmbientSound.campfire],
      );
    }
    for (final id in ['riverbank', 'fishing_pond', 'mangrove_shallows']) {
      expect(ambienceForGame(gatheringGame(state: RunState(locationId: id))), [
        AmbientSound.river,
      ]);
    }
    expect(
      ambienceForGame(gatheringGame(state: RunState(phase: RunPhase.gameOver))),
      isEmpty,
    );
    expect(
      ambienceForGame(
        gatheringGame(
          state: RunState(phase: RunPhase.rescued, weather: 'Storm'),
        ),
      ),
      [AmbientSound.jungle],
    );
    final mini = gatheringGame()..openGathering(GatheringKind.chopping);
    expect(ambienceForGame(mini), [AmbientSound.jungle]);
  });
  test(
    'ambient loops stay loaded across transactions and preserve autosave',
    () async {
      final rig = SoundRig();
      final game = gatheringGame();
      var saves = 0;
      game.onChanged = () => saves++;
      rig.controller.attach(game);
      await rig.controller.initialize();
      await rig.controller.settled;
      game.startAction(CampAction.rest);
      await rig.controller.settled;
      expect(saves, 1);
      expect(rig.base.loads, [AmbientSound.jungle.asset]);
      expect(rig.base.starts, 1);
      expect(rig.fire.loads, [AmbientSound.campfire.asset]);
      expect(rig.base.loops, [true]);
      expect(rig.base.gains.last, closeTo(.6 * .28, .0001));
      rig.controller.dispose();
    },
  );
  test(
    'map fades campfire out; background pauses and resume keeps loop position',
    () async {
      final rig = SoundRig();
      rig.controller.attach(gatheringGame());
      await rig.controller.initialize();
      await rig.controller.settled;
      rig.controller.setMapOpen(true);
      await rig.controller.settled;
      expect(rig.fire.playing, isFalse);
      expect(rig.base.loads.length, 1);
      rig.controller.setForeground(false);
      await rig.controller.settled;
      expect(rig.base.playing, isFalse);
      rig.controller.setForeground(true);
      rig.controller.setMapOpen(false);
      await rig.controller.settled;
      expect(rig.base.playing, isTrue);
      expect(rig.base.loads.length, 1);
      expect(rig.fire.loads.length, 1);
      rig.controller.dispose();
    },
  );
  test(
    'successful chops rotate clips; miss, pause and spam never emit impacts',
    () async {
      final rig = SoundRig();
      final game = gatheringGame();
      rig.controller.attach(game);
      await rig.controller.initialize();
      game.openGathering(GatheringKind.chopping);
      game.beginGathering();
      game.tickGathering(.4);
      expect(game.strikeGathering(), isTrue);
      expect(game.strikeGathering(), isFalse);
      await rig.controller.settled;
      expect(rig.wood.loads, ['assets/sounds/wood_1.wav']);
      game.pauseGathering(true);
      expect(game.strikeGathering(), isFalse);
      await rig.controller.settled;
      expect(rig.wood.playing, isFalse);
      expect(rig.base.gains.last, closeTo(.6 * .28 * .45, .0001));
      game.pauseGathering(false);
      game.tickGathering(.8);
      game.strikeGathering();
      await rig.controller.settled;
      expect(rig.wood.loads.last, 'assets/sounds/wood_2.wav');
      game.tickGathering(.5); // marker is outside the hit zone
      game.strikeGathering();
      await rig.controller.settled;
      expect(game.gathering!.lastQuality, TimingQuality.miss);
      expect(rig.wood.loads.length, 2);
      expect(rig.wood.loops, [false, false]);
      rig.controller.dispose();
    },
  );
  test(
    'travel produces a short three-step burst; invalid repeated travel is silent',
    () async {
      final rig = SoundRig();
      final game = gatheringGame();
      rig.controller.attach(game);
      await rig.controller.initialize();
      expect(game.travelTo('riverbank'), isTrue);
      expect(game.travelTo('riverbank'), isFalse);
      await rig.controller.settled;
      expect(rig.steps.loads, [
        'assets/sounds/step_1.wav',
        'assets/sounds/step_2.wav',
        'assets/sounds/step_3.wav',
      ]);
      expect(rig.steps.loops, [false, false, false]);
      expect(rig.base.loads.last, AmbientSound.river.asset);
      expect(rig.fire.playing, isFalse);
      rig.controller.dispose();
    },
  );
  test('save/restore never replays travel or previous impact cues', () async {
    final rig = SoundRig();
    final source = gatheringGame()..travelTo('riverbank');
    final restored = gatheringGame();
    final cues = <GameSound>[];
    restored.addSoundListener(cues.add);
    // The application restores the run before attaching audio controllers.
    expect(restored.restore(gatheringSave(source)), isTrue);
    rig.controller.attach(restored);
    await rig.controller.initialize();
    await rig.controller.settled;
    expect(cues, isEmpty);
    expect(rig.steps.loads, isEmpty);
    expect(rig.wood.loads, isEmpty);
    expect(rig.base.loads.last, AmbientSound.river.asset);
    rig.controller.dispose();
  });
  test(
    'mute during a blocked effect load cancels remaining footsteps',
    () async {
      final rig = SoundRig();
      final block = Completer<void>();
      rig.steps.blockedLoad = block;
      final game = gatheringGame();
      rig.controller.attach(game);
      await rig.controller.initialize();
      game.travelTo('riverbank');
      while (rig.steps.loads.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      rig.controller.setEnabled(false);
      block.complete();
      await rig.controller.settled;
      expect(rig.steps.starts, 0);
      expect(rig.steps.loads.length, 1);
      expect(rig.base.playing, isFalse);
      rig.controller.dispose();
    },
  );
  test(
    'background during a blocked ambient load never starts stale audio',
    () async {
      final rig = SoundRig();
      final block = Completer<void>();
      rig.base.blockedLoad = block;
      rig.controller.attach(gatheringGame());
      await rig.controller.initialize();
      while (rig.base.loads.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      rig.controller.setForeground(false);
      block.complete();
      await rig.controller.settled;
      expect(rig.base.starts, 0);
      expect(rig.fire.playing, isFalse);
      rig.controller.dispose();
    },
  );
  test(
    'settings reopen muted without decoding, clamp gain and ignore NaN',
    () async {
      final store = MemorySoundSettings(
        const SoundSettings(enabled: false, volume: .7),
      );
      final rig = SoundRig(store: store);
      rig.controller.attach(gatheringGame());
      await rig.controller.initialize();
      await rig.controller.settled;
      expect(rig.base.loads, isEmpty);
      rig.controller.setEnabled(true);
      rig.controller.setVolume(2);
      rig.controller.setVolume(double.nan);
      await rig.controller.settled;
      expect(rig.controller.volume, 1);
      expect(store.settings.volume, 1);
      expect(rig.base.gains.every((value) => value >= 0 && value <= 1), isTrue);
      rig.controller.setVolume(0);
      await rig.controller.settled;
      expect(rig.base.playing, isFalse);
      rig.controller.dispose();
    },
  );
  test('sound preferences do not overwrite music or the saved run', () async {
    SharedPreferences.setMockInitialValues({
      'lost_canopy.run': 'saved',
      'lost_canopy.music.enabled': false,
      'lost_canopy.music.volume': .25,
    });
    final store = PreferencesSoundSettings();
    await store.save(const SoundSettings(enabled: false, volume: .8));
    expect((await store.load()).volume, .8);
    expect((await store.load()).enabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lost_canopy.run'), 'saved');
    expect(prefs.getBool('lost_canopy.music.enabled'), isFalse);
    expect(prefs.getDouble('lost_canopy.music.volume'), .25);
  });
  test(
    'decoder errors do not block play and dispose detaches game listeners',
    () async {
      final rig = SoundRig();
      final game = gatheringGame();
      rig.base.failLoad = true;
      rig.controller.attach(game);
      await rig.controller.initialize();
      await rig.controller.settled;
      expect(rig.controller.available, isFalse);
      expect(game.openGathering(GatheringKind.chopping), isTrue);
      game.beginGathering();
      await rig.controller.settled;
      rig.controller.dispose();
      await rig.controller.settled;
      await Future<void>.delayed(Duration.zero);
      game.tickGathering(.4);
      game.strikeGathering();
      expect(rig.wood.loads, isEmpty);
      expect(rig.base.disposed, isTrue);
      expect(rig.steps.disposed, isTrue);
    },
  );
  test('engine emits only transaction cues and allows listener removal', () {
    final game = gatheringGame();
    final cues = <GameSound>[];
    game.addSoundListener(cues.add);
    expect(game.travelTo('not-a-place'), isFalse);
    expect(cues, isEmpty);
    game.travelTo('riverbank');
    expect(cues, [GameSound.travel]);
    game.removeSoundListener(cues.add);
    game.restore(gatheringSave(gatheringGame()));
    game.openGathering(GatheringKind.chopping);
    game.beginGathering();
    game.tickGathering(.4);
    game.strikeGathering();
    expect(cues, [GameSound.travel]);
  });
  test('prepared files are compact decodable clips with source provenance', () {
    final manifest =
        jsonDecode(File('assets/sounds/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect((manifest['sources'] as Map).length, 7);
    final assets = manifest['assets'] as List;
    expect(assets.length, 12);
    var bytes = 0;
    for (final asset in assets) {
      final file = File('assets/sounds/${asset['file']}');
      bytes += file.lengthSync();
      expect(file.lengthSync(), asset['bytes']);
      final duration = double.parse(
        asset['probe']['format']['duration'] as String,
      );
      if (asset['type'] == 'one-shot') {
        expect(duration, lessThan(1));
        expect(String.fromCharCodes(file.readAsBytesSync().take(4)), 'RIFF');
      } else {
        expect(duration, inInclusiveRange(43, 45));
      }
    }
    expect(bytes, lessThan(4 * 1024 * 1024));
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/sounds/'));
  });
  testWidgets(
    'real camp menu controls sound separately and map hides campfire',
    (tester) async {
      final rig = SoundRig();
      final musicPlayer = FakeMusicPlayer();
      final music = MusicController(
        player: musicPlayer,
        fadeStep: Duration.zero,
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        LostCanopyApp(
          engine: gatheringGame(),
          sounds: rig.controller,
          music: music,
        ),
      );
      await tester.pumpAndSettle();
      await rig.controller.settled;
      await press(tester, 'camp-menu', settle: true);
      await press(tester, 'sounds-enabled', settle: true);
      await rig.controller.settled;
      expect(rig.controller.enabled, isFalse);
      expect(rig.base.playing, isFalse);
      expect(musicPlayer.playing, isTrue);
      await press(tester, 'sounds-enabled', settle: true);
      await rig.controller.settled;
      await press(tester, 'music-enabled', settle: true);
      await music.settled;
      expect(musicPlayer.playing, isFalse);
      expect(rig.base.playing, isTrue);
      await press(tester, 'close-dialog', settle: true);
      await press(tester, 'open-map', settle: true);
      await rig.controller.settled;
      expect(rig.fire.playing, isFalse);
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
      await rig.controller.settled;
      expect(rig.fire.playing, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      rig.controller.dispose();
      music.dispose();
    },
  );
}
