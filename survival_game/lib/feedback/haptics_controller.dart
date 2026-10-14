import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_engine.dart';
import '../game/gathering_session.dart';
import '../game/run_state.dart';
import '../game/fishing_session.dart';
import '../game/ruins_puzzle.dart';

enum HapticCue { selection, light, success, warning }

abstract class HapticDevice {
  Future<void> pulse(HapticCue cue);
}

class SystemHapticDevice implements HapticDevice {
  @override
  Future<void> pulse(HapticCue cue) => switch (cue) {
    HapticCue.selection => HapticFeedback.selectionClick(),
    HapticCue.light => HapticFeedback.lightImpact(),
    HapticCue.success => HapticFeedback.mediumImpact(),
    HapticCue.warning => HapticFeedback.heavyImpact(),
  };
}

abstract class HapticSettingsStore {
  Future<bool> load();
  Future<void> save(bool enabled);
}

class PreferencesHapticSettings implements HapticSettingsStore {
  @override
  Future<bool> load() async =>
      (await SharedPreferences.getInstance()).getBool(
        'lost_canopy.haptics.enabled',
      ) ??
      true;
  @override
  Future<void> save(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(
        'lost_canopy.haptics.enabled',
        enabled,
      );
}

/// Transaction observation keeps feedback out of saves and simulations.
/// A game result supersedes the delayed card tap, avoiding duplicate pulses.
class HapticsController extends ChangeNotifier {
  HapticsController({
    required HapticDevice device,
    HapticSettingsStore? store,
    this.tapDelay = const Duration(milliseconds: 40),
  }) : _device = device,
       _store = store;
  factory HapticsController.device() => HapticsController(
    device: SystemHapticDevice(),
    store: PreferencesHapticSettings(),
  );
  final HapticDevice _device;
  final HapticSettingsStore? _store;
  final Duration tapDelay;
  GameEngine? _game;
  bool enabled = true, _ready = false, _foreground = true, _closed = false;
  int _settingsRevision = 0;
  int _deliveryRevision = 0;
  Timer? _tap;
  Future<void> _pending = Future.value(), _save = Future.value();
  ActionReport? _report;
  GatheringSession? _gathering;
  int _hits = 0, _plants = 0, _moves = 0;
  RuinsPuzzle? _puzzle;
  FishingSession? _fishing;
  bool get _canPulse => enabled && _ready && _foreground && !_closed;

  Future<void> initialize() async {
    final revision = _settingsRevision;
    try {
      final saved = await _store?.load();
      if (!_closed && revision == _settingsRevision && saved != null) {
        enabled = saved;
      }
    } catch (error) {
      debugPrint('Haptic settings: $error');
    }
    if (_closed) return;
    _ready = true;
    notifyListeners();
  }

  void attach(GameEngine game) {
    _game?.removeListener(_changed);
    _tap?.cancel();
    _deliveryRevision++;
    _game = game;
    _snapshot();
    game.addListener(_changed);
  }

  void _snapshot() {
    _report = _game?.report;
    _gathering = _game?.gathering;
    _hits = _gathering?.hits.length ?? 0;
    _plants = _gathering?.picked.length ?? 0;
    _puzzle = _game?.ruinsPuzzle;
    _fishing = _game?.fishing;
    _moves = _game?.ruinsPuzzle?.moves ?? 0;
  }

  void _changed() {
    final game = _game!;
    HapticCue? cue;
    final report = game.report;
    if (report != null && !identical(report, _report)) {
      final failedActivity =
          (_puzzle != null && game.ruinsPuzzle == null && !_puzzle!.solved) ||
          (_fishing != null &&
              game.fishing == null &&
              _fishing!.quality == CatchQuality.missed) ||
          (_gathering != null &&
              game.gathering == null &&
              _gathering!.kind != GatheringKind.foraging &&
              _gathering!.hits.every((hit) => hit == TimingQuality.miss));
      cue =
          !game.state.isAlive ||
              (report.changes['Health'] ?? 0) < 0 ||
              failedActivity
          ? HapticCue.warning
          : HapticCue.success;
    } else if (identical(game.gathering, _gathering) && _gathering != null) {
      if (_gathering!.hits.length > _hits) {
        cue = switch (_gathering!.lastQuality) {
          TimingQuality.perfect => HapticCue.success,
          TimingQuality.good => HapticCue.light,
          _ => HapticCue.selection,
        };
      } else if (_gathering!.picked.length > _plants) {
        cue = HapticCue.light;
      }
    } else if (identical(game.ruinsPuzzle, _puzzle) &&
        (game.ruinsPuzzle?.moves ?? 0) > _moves) {
      cue = HapticCue.selection;
    }
    // Always advance while muted/backgrounded; resume must not replay cues.
    _snapshot();
    if (cue != null) pulse(cue);
  }

  void tap() {
    if (!_canPulse) return;
    _tap?.cancel();
    _tap = Timer(tapDelay, () => pulse(HapticCue.selection));
  }

  void pulse(HapticCue cue) {
    _tap?.cancel();
    _tap = null;
    if (!_canPulse) return;
    final revision = _deliveryRevision;
    // Check again when dispatched, so queued feedback respects mute/background.
    _pending = _pending.then((_) async {
      if (!_canPulse || revision != _deliveryRevision) return;
      try {
        await _device.pulse(cue);
      } catch (error) {
        debugPrint('Haptic feedback: $error');
      }
    });
  }

  void setForeground(bool value) {
    _foreground = value;
    if (!value) {
      _deliveryRevision++;
      _tap?.cancel();
      _tap = null;
    }
  }

  void setEnabled(bool value) {
    enabled = value;
    _settingsRevision++;
    if (!value) {
      _deliveryRevision++;
      _tap?.cancel();
      _tap = null;
    }
    notifyListeners();
    _save = _save.then((_) async {
      try {
        await _store?.save(value);
      } catch (error) {
        debugPrint('Haptic settings save: $error');
      }
    });
  }

  Future<void> get settled async {
    await _pending;
    await _save;
  }

  @override
  void dispose() {
    _closed = true;
    _deliveryRevision++;
    _tap?.cancel();
    _game?.removeListener(_changed);
    super.dispose();
  }
}
