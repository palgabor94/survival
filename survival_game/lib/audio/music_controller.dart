import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_engine.dart';
import '../game/gathering_session.dart';
import '../game/rescue_progress.dart';
import '../game/run_state.dart';

enum MusicTrack {
  mainTheme('main'),
  camp('camp'),
  action('action');

  const MusicTrack(this.file);
  final String file;
  String get asset => 'assets/music/$file.mp3';
}

MusicTrack? musicForGame(GameEngine game, {bool mapOpen = false}) {
  if (game.state.phase == RunPhase.gameOver) return null;
  if (game.state.rescued) return MusicTrack.camp;
  if (game.state.rescueStage == RescueStage.storm ||
      game.pendingEvent?.trigger == 'encounter' ||
      (game.gathering?.kind == GatheringKind.hunting &&
          game.gathering?.stage != GatheringStage.ready)) {
    return MusicTrack.action;
  }
  if (mapOpen ||
      game.expedition != null ||
      game.fishing != null ||
      game.ruinsPuzzle != null ||
      game.gathering != null ||
      game.pendingEvent?.trigger == 'explore') {
    return MusicTrack.mainTheme;
  }
  return MusicTrack.camp;
}

abstract class MusicPlayer {
  Future<void> load(MusicTrack track);
  Future<void> volume(double value);
  void start();
  Future<void> pause();
  Future<void> dispose();
}

/// Native audio playback; play's Future lasts for the entire loop, so it must
/// never block scene transitions. Loading/loop configuration remain awaited.
class DeviceMusicPlayer implements MusicPlayer {
  final _player = AudioPlayer();
  @override
  Future<void> load(MusicTrack track) async {
    await _player.setAsset(track.asset);
    await _player.setLoopMode(LoopMode.one);
  }

  @override
  Future<void> volume(double value) => _player.setVolume(value);
  @override
  void start() {
    unawaited(
      _player.play().catchError((Object error) {
        debugPrint('Music playback: $error');
      }),
    );
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> dispose() => _player.dispose();
}

class MusicSettings {
  const MusicSettings({this.enabled = true, this.volume = .35});
  final bool enabled;
  final double volume;
}

abstract class MusicSettingsStore {
  Future<MusicSettings> load();
  Future<void> save(MusicSettings settings);
}

class PreferencesMusicSettings implements MusicSettingsStore {
  @override
  Future<MusicSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getDouble('lost_canopy.music.volume') ?? .35;
    return MusicSettings(
      enabled: prefs.getBool('lost_canopy.music.enabled') ?? true,
      volume: volume.isFinite ? volume.clamp(0, 1) : .35,
    );
  }

  @override
  Future<void> save(MusicSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lost_canopy.music.enabled', settings.enabled);
    await prefs.setDouble('lost_canopy.music.volume', settings.volume);
  }
}

/// One player for the entire app. Scene requests are coalesced, serialized and
/// checked after every await, so a stale load cannot play after mute/background.
class MusicController extends ChangeNotifier {
  MusicController({
    required MusicPlayer player,
    MusicSettingsStore? store,
    this.fadeStep = const Duration(milliseconds: 40),
  }) : _player = player,
       _store = store;
  factory MusicController.device() => MusicController(
    player: DeviceMusicPlayer(),
    store: PreferencesMusicSettings(),
  );
  final MusicPlayer _player;
  final MusicSettingsStore? _store;
  final Duration fadeStep;
  GameEngine? _game;
  bool enabled = true;
  double volume = .35;
  bool available = true;
  bool _foreground = true, _mapOpen = false, _closed = false;
  bool _ready = false, _playing = false;
  int _settingsRevision = 0, _revision = 0;
  double _gain = 0, _desiredGain = 0;
  MusicTrack? _desired, _loaded;
  Future<void>? _syncFuture;
  Future<void> _saveFuture = Future.value();
  MusicTrack? get selectedTrack => _desired;

  Future<void> initialize() async {
    final revision = _settingsRevision;
    try {
      final settings = await _store?.load();
      if (!_closed && revision == _settingsRevision && settings != null) {
        enabled = settings.enabled;
        volume = settings.volume.clamp(0, 1);
      }
    } catch (error) {
      debugPrint('Music settings: $error');
    }
    if (_closed) return;
    _ready = true;
    notifyListeners();
    _request();
  }

  void attach(GameEngine game) {
    _game?.removeListener(_request);
    _game = game;
    game.addListener(_request);
    _request();
  }

  void setMapOpen(bool value) {
    _mapOpen = value;
    _request();
  }

  void setForeground(bool value) {
    _foreground = value;
    _request();
  }

  void setEnabled(bool value) {
    enabled = value;
    _settingsRevision++;
    notifyListeners();
    _save();
    _request();
  }

  void setVolume(double value) {
    if (!value.isFinite) return;
    volume = value.clamp(0, 1);
    _settingsRevision++;
    notifyListeners();
    _save();
    _request();
  }

  void _save() {
    final settings = MusicSettings(enabled: enabled, volume: volume);
    _saveFuture = _saveFuture.then((_) async {
      try {
        await _store?.save(settings);
      } catch (error) {
        debugPrint('Music settings save: $error');
      }
    });
  }

  void _request() {
    if (_closed) return;
    final game = _game;
    final track = !_ready || !_foreground || !enabled || volume == 0
        ? null
        : game == null
        ? MusicTrack.mainTheme
        : musicForGame(game, mapOpen: _mapOpen);
    final gain = track == null
        ? 0.0
        : volume * (game?.gathering?.paused == true ? .45 : 1);
    if (track == _desired && gain == _desiredGain) return;
    _desired = track;
    _desiredGain = gain;
    _revision++;
    _syncFuture ??= _sync().whenComplete(() {
      _syncFuture = null;
    });
  }

  bool _current(int revision) => !_closed && revision == _revision;
  Future<void> _fade(double target, int revision) async {
    final start = _gain;
    for (var step = 1; step <= 12 && _current(revision); step++) {
      _gain = start + (target - start) * step / 12;
      await _player.volume(_gain);
      if (fadeStep != Duration.zero) await Future<void>.delayed(fadeStep);
    }
  }

  Future<void> _sync() async {
    var applied = -1;
    while (!_closed && applied != _revision) {
      final revision = _revision;
      final track = _desired;
      try {
        if (track == null) {
          // Lifecycle and mute pause immediately, without waiting for a fade.
          await _player.pause();
          _playing = false;
          await _player.volume(0);
          _gain = 0;
        } else {
          if (track != _loaded) {
            if (_playing) await _fade(0, revision);
            if (!_current(revision)) continue;
            await _player.pause();
            _playing = false;
            await _player.volume(0);
            _gain = 0;
            await _player.load(track);
            _loaded = track;
          }
          if (!_current(revision)) continue;
          if (!_playing) {
            _player.start();
            _playing = true;
          }
          await _fade(_desiredGain, revision);
        }
        if (!_closed && !available) {
          available = true;
          notifyListeners();
        }
      } catch (error) {
        _playing = false;
        debugPrint('Music unavailable: $error');
        if (!_closed) {
          available = false;
          notifyListeners();
        }
      }
      applied = revision;
    }
  }

  Future<void> get settled async {
    await _syncFuture;
    await _saveFuture;
  }

  @override
  void dispose() {
    _closed = true;
    _revision++;
    _game?.removeListener(_request);
    final pending = _syncFuture ?? Future<void>.value();
    unawaited(pending.then((_) => _player.dispose()));
    super.dispose();
  }
}
