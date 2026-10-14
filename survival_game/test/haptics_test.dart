import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_game/feedback/haptics_controller.dart';
import 'package:survival_game/audio/music_controller.dart';
import 'package:survival_game/feedback/haptics_scope.dart';
import 'package:survival_game/game/gathering_session.dart';
import 'package:survival_game/game/run_state.dart';
import 'package:survival_game/main.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/fishing_screen.dart';

import 'game/gathering_test.dart' show gatheringGame, gatheringSave;
import 'gathering_widget_test.dart' show press;
import 'music_test.dart' show FakeMusicPlayer;
import 'sounds_test.dart' show SoundRig;

class FakeHapticDevice implements HapticDevice {
  final pulses = <HapticCue>[];
  bool fail = false;
  @override
  Future<void> pulse(HapticCue cue) async {
    if (fail) throw StateError('Haptics unsupported');
    pulses.add(cue);
  }
}

void main() {
  test(
    'native feedback maps to platform selection/light/medium/heavy calls',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final methods = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (
        method,
      ) async {
        methods.add(method);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final device = SystemHapticDevice();
      for (final cue in HapticCue.values) {
        await device.pulse(cue);
      }
      expect(
        methods.map((m) => m.method).toList(),
        List.filled(4, 'HapticFeedback.vibrate'),
      );
      expect(methods.map((m) => m.arguments).toList(), [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
    },
  );
  test(
    'chops distinguish perfect/good/miss and reject repeated or paused strikes',
    () async {
      final device = FakeHapticDevice();
      final controller = HapticsController(device: device);
      final game = gatheringGame();
      controller.attach(game);
      await controller.initialize();
      game.openGathering(GatheringKind.chopping);
      game.beginGathering();
      game.tickGathering(.4);
      game.strikeGathering();
      game.strikeGathering();
      game.saveGatheringProgress();
      game.pauseGathering(true);
      game.strikeGathering();
      game.pauseGathering(false);
      await controller.settled;
      expect(device.pulses, [HapticCue.success]);
      game.tickGathering(.7);
      game.strikeGathering();
      game.tickGathering(.5);
      game.strikeGathering();
      await controller.settled;
      expect(device.pulses, [
        HapticCue.success,
        HapticCue.light,
        HapticCue.selection,
      ]);
      controller.dispose();
    },
  );
  test(
    'plant collection emits once, and finished outcome emits once',
    () async {
      final device = FakeHapticDevice();
      final controller = HapticsController(device: device);
      final game = gatheringGame();
      controller.attach(game);
      await controller.initialize();
      game.openGathering(GatheringKind.foraging);
      game.beginGathering();
      game.pickGatheringPlant('berries');
      game.pickGatheringPlant('berries');
      game.finishGathering(leave: true);
      game.finishGathering(leave: true);
      await controller.settled;
      expect(device.pulses, [HapticCue.light, HapticCue.success]);
      controller.dispose();
    },
  );
  test(
    'actual damage warns and attach/restore never vibrates old outcomes',
    () async {
      final source = gatheringGame(
        state: RunState(
          stats: {
            SurvivalStat.health: 80,
            SurvivalStat.water: 0,
            SurvivalStat.food: 0,
            SurvivalStat.sanity: 80,
          },
        ),
      );
      final device = FakeHapticDevice();
      final controller = HapticsController(device: device);
      controller.attach(source);
      await controller.initialize();
      source.startAction(CampAction.rest);
      await controller.settled;
      expect(device.pulses, [HapticCue.warning]);
      final restored = gatheringGame();
      restored.restore(gatheringSave(source));
      controller.attach(restored);
      restored.continueFromReport();
      await controller.settled;
      expect(device.pulses, [HapticCue.warning]);
      controller.dispose();
    },
  );
  test(
    'ruins turns have selection feedback and no invalid-index feedback',
    () async {
      final game = gatheringGame(
        state: RunState(campTier: 2, tools: {'machete'}),
      );
      game.travelTo('ancient_ruins');
      game.choose('align');
      final device = FakeHapticDevice();
      final controller = HapticsController(device: device)..attach(game);
      await controller.initialize();
      expect(game.turnRuinsTile(0), isTrue);
      expect(game.turnRuinsTile(9), isFalse);
      await controller.settled;
      expect(device.pulses, [HapticCue.selection]);
      if (game.ruinsPuzzle!.solved) game.turnRuinsTile(0);
      game.finishRuinsPuzzle();
      await controller.settled;
      expect(device.pulses.last, HapticCue.warning);
      controller.dispose();
    },
  );
  test('mute/background suppress feedback without replay on resume', () async {
    final device = FakeHapticDevice();
    final controller = HapticsController(device: device);
    final game = gatheringGame();
    controller.attach(game);
    await controller.initialize();
    controller.setEnabled(false);
    game.startAction(CampAction.rest);
    controller.setEnabled(true);
    game.continueFromReport();
    controller.setForeground(false);
    controller.tap();
    controller.pulse(HapticCue.warning);
    game.startAction(CampAction.rest);
    controller.setForeground(true);
    game.continueFromReport();
    await controller.settled;
    expect(device.pulses, isEmpty);
    controller.dispose();
  });
  test(
    'persisted setting is independent of audio and run, survives reopening',
    () async {
      SharedPreferences.setMockInitialValues({
        'lost_canopy.run': 'run',
        'lost_canopy.music.enabled': true,
      });
      final store = PreferencesHapticSettings();
      final controller = HapticsController(
        device: FakeHapticDevice(),
        store: store,
      );
      await controller.initialize();
      controller.setEnabled(false);
      await controller.settled;
      final reopened = HapticsController(
        device: FakeHapticDevice(),
        store: store,
      );
      await reopened.initialize();
      expect(reopened.enabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lost_canopy.run'), 'run');
      expect(prefs.getBool('lost_canopy.music.enabled'), isTrue);
      controller.dispose();
      reopened.dispose();
    },
  );
  test(
    'queued pulses respect mute; unsupported device cannot break transactions',
    () async {
      final device = FakeHapticDevice();
      final controller = HapticsController(device: device);
      await controller.initialize();
      controller.pulse(HapticCue.success);
      controller.setEnabled(false);
      await controller.settled;
      expect(device.pulses, isEmpty);
      controller.setEnabled(true);
      device.fail = true;
      controller.attach(gatheringGame());
      controller.pulse(HapticCue.warning);
      await controller.settled;
      controller.dispose();
    },
  );
  test('rapid background/resume invalidates queued feedback', () async {
    final device = FakeHapticDevice();
    final controller = HapticsController(device: device);
    await controller.initialize();
    controller.pulse(HapticCue.success);
    controller.setForeground(false);
    controller.setForeground(true);
    await controller.settled;
    expect(device.pulses, isEmpty);
    controller.dispose();
  });
  test(
    'feedback leaves autosave intact and detach prevents further pulses',
    () async {
      final device = FakeHapticDevice();
      final controller = HapticsController(device: device);
      final game = gatheringGame();
      var saves = 0;
      game.onChanged = () => saves++;
      controller.attach(game);
      await controller.initialize();
      game.startAction(CampAction.rest);
      await controller.settled;
      expect(saves, 1);
      expect(device.pulses, [HapticCue.success]);
      controller.dispose();
      game.continueFromReport();
      game.startAction(CampAction.rest);
      expect(device.pulses, [HapticCue.success]);
    },
  );
  testWidgets(
    'card result supersedes generic tap; disabled cards stay silent',
    (tester) async {
      final device = FakeHapticDevice();
      final controller = HapticsController(device: device);
      final game = gatheringGame();
      controller.attach(game);
      await controller.initialize();
      await tester.pumpWidget(
        HapticsScope(
          controller: controller,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ActionCard(
                    title: 'Rest',
                    key: const ValueKey('rest'),
                    onTap: () => game.startAction(CampAction.rest),
                  ),
                  const ActionCard(title: 'Locked', key: ValueKey('locked')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('rest')));
      await tester.pump(const Duration(milliseconds: 100));
      await controller.settled;
      expect(device.pulses, [HapticCue.success]);
      await tester.tap(find.byKey(const ValueKey('locked')));
      await tester.pump(const Duration(milliseconds: 100));
      await controller.settled;
      expect(device.pulses, [HapticCue.success]);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
  testWidgets('actual camp menu saves haptics toggle and cancels delayed tap', (
    tester,
  ) async {
    final device = FakeHapticDevice();
    final controller = HapticsController(device: device);
    await tester.pumpWidget(
      LostCanopyApp(engine: gatheringGame(), haptics: controller),
    );
    await tester.pumpAndSettle();
    await press(tester, 'camp-menu', settle: true);
    await press(tester, 'haptics-enabled', settle: true);
    expect(controller.enabled, isFalse);
    final count = device.pulses.length;
    await press(tester, 'close-dialog', settle: true);
    await controller.settled;
    expect(device.pulses.length, count);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  testWidgets('fishing bite warns once and accepted hook has light feedback', (
    tester,
  ) async {
    final game = gatheringGame(
      state: RunState(day: 2, tools: {'basic_rod'}, resources: {'bait': 2}),
    );
    game.travelTo('fishing_pond');
    final device = FakeHapticDevice();
    final controller = HapticsController(device: device)..attach(game);
    await controller.initialize();
    await tester.pumpWidget(
      HapticsScope(
        controller: controller,
        child: MaterialApp(home: FishingScreen(game: game)),
      ),
    );
    await press(tester, 'cast-line');
    for (var i = 0; i < 40 && game.fishing!.stage.name != 'bite'; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await controller.settled;
    expect(device.pulses.where((c) => c == HapticCue.success), hasLength(1));
    await press(tester, 'hook-fish');
    await controller.settled;
    expect(device.pulses.last, HapticCue.light);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  testWidgets('all feedback controls fit a small phone with doubled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final haptics = HapticsController(device: FakeHapticDevice());
    final music = MusicController(
      player: FakeMusicPlayer(),
      fadeStep: Duration.zero,
    );
    final sounds = SoundRig();
    await tester.pumpWidget(
      LostCanopyApp(
        engine: gatheringGame(),
        haptics: haptics,
        music: music,
        sounds: sounds.controller,
      ),
    );
    await tester.pumpAndSettle();
    await press(tester, 'camp-menu', settle: true);
    for (final key in ['music-enabled', 'sounds-enabled', 'haptics-enabled']) {
      await press(tester, key, settle: true);
    }
    expect(haptics.enabled, isFalse);
    expect(music.enabled, isFalse);
    expect(sounds.controller.enabled, isFalse);
    expect(tester.takeException(), isNull);
    await press(tester, 'close-dialog', settle: true);
    await tester.pumpWidget(const SizedBox.shrink());
    haptics.dispose();
    music.dispose();
    sounds.controller.dispose();
  });
}
