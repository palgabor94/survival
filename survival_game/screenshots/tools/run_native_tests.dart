// Run the unchanged test declarations in Flutter's native engine when the
// normal flutter test launcher cannot bind its local WebSocket in the sandbox.
// The runner consumes the test_api version supplied by flutter_test.
// ignore_for_file: implementation_imports, depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/invoker.dart';
import 'package:test_api/src/backend/operating_system.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/suite.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_api/src/backend/test.dart' as backend;

import '../../test/widget_test.dart' as widgets;
import '../../test/camp_widget_test.dart' as camp;
import '../../test/card_widget_test.dart' as cards;
import '../../test/card_illustration_test.dart' as illustrations;
import '../../test/expedition_widget_test.dart' as expedition_ui;
import '../../test/trip_widget_test.dart' as trip_ui;
import '../../test/game/card_test.dart' as card_logic;
import '../../test/game/camp_test.dart' as camp_logic;
import '../../test/game/expedition_test.dart' as expedition_logic;
import '../../test/game/fishing_session_test.dart' as fishing;
import '../../test/game/game_engine_test.dart' as engine;
import '../../test/game/trip_test.dart' as trip;
import '../../test/game/content_expansion_test.dart' as expansion;
import '../../test/game/rescue_test.dart' as rescue;
import '../../test/rescue_widget_test.dart' as rescue_ui;
import '../../test/camp_backdrop_test.dart' as camp_art;
import '../../test/game/gathering_test.dart' as gathering;
import '../../test/gathering_widget_test.dart' as gathering_ui;
import '../../test/music_test.dart' as music;
import '../../test/sounds_test.dart' as sounds;
import '../../test/haptics_test.dart' as haptics;
import '../../test/navigation_test.dart' as navigation;
import '../../test/scene_background_test.dart' as scene_background;

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 24;
  final declarer = Declarer(collectTraces: true, noRetry: true);
  declarer.declare(() {
    final files = <String, void Function()>{
      'game_engine': engine.main,
      'camp_logic': camp_logic.main,
      'card_logic': card_logic.main,
      'expedition_logic': expedition_logic.main,
      'fishing': fishing.main,
      'gathering': gathering.main,
      'gathering_widgets': gathering_ui.main,
      'music': music.main,
      'sounds': sounds.main,
      'haptics': haptics.main,
      'navigation': navigation.main,
      'scene_background': scene_background.main,
      'trip_logic': trip.main,
      'content_expansion': expansion.main,
      'rescue': rescue.main,
      'rescue_widgets': rescue_ui.main,
      'camp_backdrop': camp_art.main,
      'illustrations': illustrations.main,
      'widgets': widgets.main,
      'camp_widgets': camp.main,
      'card_widgets': cards.main,
      'expedition_widgets': expedition_ui.main,
      'trip_widgets': trip_ui.main,
    };
    for (final entry in files.entries) {
      declarer.group(entry.key, entry.value);
    }
  });
  final root = declarer.build();
  final suite = Suite(
    root,
    SuitePlatform(Runtime.vm, os: OperatingSystem.macOS),
  );
  var passed = 0;
  var failed = 0;
  var skipped = 0;
  final failures = <String>[];
  final filter = Platform.environment['LOST_CANOPY_TEST_FILTER'];

  Future<bool> run(
    backend.Test test,
    List<Group> groups, {
    bool hook = false,
  }) async {
    if (!hook && filter != null && !test.name.contains(filter)) return true;
    if (test.metadata.skip) {
      if (!hook) {
        skipped++;
        stdout.writeln('SKIP ${test.name}');
      }
      return true;
    }
    stdout.writeln('RUN ${test.name}');
    final live = test.load(suite, groups: groups);
    final errors = live.onError.listen((error) {
      stdout.writeln('ERROR ${test.name}\n${error.error}\n${error.stackTrace}');
    });
    final messages = live.onMessage.listen((message) {
      stdout.writeln(message.text);
    });
    await Invoker.guard(() => live.run())!.timeout(const Duration(seconds: 90));
    await live.close();
    final okay = live.state.result == Result.success;
    if (!okay) {
      failed++;
      failures.add(test.name);
    } else if (!hook) {
      passed++;
    }
    stdout.writeln('${okay ? 'PASS' : 'FAIL'} ${test.name}');
    await errors.cancel();
    await messages.cancel();
    return okay;
  }

  Future<void> walk(Group group, List<Group> parents) async {
    final groups = [...parents, group];
    final ready =
        group.setUpAll == null ||
        await run(group.setUpAll!, groups, hook: true);
    if (ready) {
      for (final entry in group.entries) {
        if (entry is Group) {
          await walk(entry, groups);
        } else {
          await run(entry as backend.Test, groups);
        }
      }
    }
    if (group.tearDownAll != null) {
      await run(group.tearDownAll!, groups, hook: true);
    }
  }

  try {
    await walk(suite.group, []);
    final report = {
      'passed': passed,
      'failed': failed,
      'skipped': skipped,
      'failures': failures,
      'runner': 'native Flutter engine, test_api LiveTest',
    };
    File(
      '.dart_tool/native-test-results.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    stdout.writeln(
      'NATIVE TEST RESULTS: $passed passed, $failed failed, $skipped skipped',
    );
    keepAlive.cancel();
    exit(failed == 0 ? 0 : 1);
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    keepAlive.cancel();
    exit(2);
  }
}
