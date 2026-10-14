import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_engine.dart';
import '../game/game_sound.dart';
import '../game/rescue_progress.dart';
import '../game/run_state.dart';

enum AmbientSound {
  jungle(.28),
  night(.28),
  river(.38),
  rain(.42),
  campfire(.30);

  const AmbientSound(this.gain);
  final double gain;
  String get asset => 'assets/sounds/$name.mp3';
}

List<AmbientSound> ambienceForGame(GameEngine game, {bool mapOpen = false}) {
  final state = game.state;
  if (state.phase == RunPhase.gameOver) return [];
  if (state.rescued) return [AmbientSound.jungle];
  final rain =
      state.rescueStage == RescueStage.storm ||
      state.weather.toLowerCase().contains('rain') ||
      state.weather.toLowerCase().contains('storm');
  final base = rain
      ? AmbientSound.rain
      : state.phase == RunPhase.night
      ? AmbientSound.night
      : !mapOpen &&
            {
              'fishing_pond',
              'riverbank',
              'mangrove_shallows',
            }.contains(state.locationId)
      ? AmbientSound.river
      : AmbientSound.jungle;
  final atCamp =
      !mapOpen &&
      !state.rescued &&
      state.locationId == 'camp' &&
      game.expedition == null &&
      game.fishing == null &&
      game.ruinsPuzzle == null &&
      game.gathering == null &&
      game.pendingEvent?.trigger != 'explore';
  return [base, if (atCamp) AmbientSound.campfire];
}

abstract class SoundPlayer {
  Future<void> load(String asset, {required bool loop});
  Future<void> volume(double value);
  void start();
  Future<void> pause();
  Future<void> dispose();
}

class DeviceSoundPlayer implements SoundPlayer {
  AudioPlayer? _native;
  AudioPlayer get _player => _native ??= AudioPlayer();
  @override
  Future<void> load(String asset, {required bool loop}) async {
    await _player.setAsset(asset);
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
  }

  @override
  Future<void> volume(double value) async => _native?.setVolume(value);
  @override
  void start() {
    unawaited(
      _player.play().catchError((Object error) {
        debugPrint('Sound playback: $error');
      }),
    );
  }

  @override
  Future<void> pause() async => _native?.pause();
  @override
  Future<void> dispose() async => _native?.dispose();
}

class SoundSettings {
  const SoundSettings({this.enabled = true, this.volume = .6});
  final bool enabled;
  final double volume;
}

abstract class SoundSettingsStore {
  Future<SoundSettings> load();
  Future<void> save(SoundSettings settings);
}

class PreferencesSoundSettings implements SoundSettingsStore {
  @override
  Future<SoundSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getDouble('lost_canopy.sounds.volume') ?? .6;
    return SoundSettings(
      enabled: prefs.getBool('lost_canopy.sounds.enabled') ?? true,
      volume: volume.isFinite ? volume.clamp(0, 1) : .6,
    );
  }

  @override
  Future<void> save(SoundSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lost_canopy.sounds.enabled', settings.enabled);
    await prefs.setDouble('lost_canopy.sounds.volume', settings.volume);
  }
}

/// Each channel serializes source changes and checks revisions after awaits.
/// No old load may start after mute, background or a newer scene request.
class _Channel {
  _Channel(this.player, this.loop, this.fadeStep, this.onError);
  final SoundPlayer player;
  final bool loop;
  final Duration fadeStep;
  final void Function(Object) onError;
  String? _desired, _loaded;
  double _desiredGain = 0, _gain = 0;
  bool _closed = false, _playing = false;
  int _revision = 0, _handled = 0;
  Future<void>? _future;
  bool _current(int revision) => !_closed && revision == _revision;
  void request(String? asset, double gain) {
    if (_closed || (loop && asset == _desired && gain == _desiredGain)) return;
    _desired = asset;
    _desiredGain = gain;
    _revision++;
    _future ??= _sync().whenComplete(() => _future = null);
  }

  Future<void> _fade(double target, int revision) async {
    final start = _gain;
    for (var i = 1; i <= 6 && _current(revision); i++) {
      _gain = start + (target - start) * i / 6;
      await player.volume(_gain);
      if (fadeStep != Duration.zero) await Future<void>.delayed(fadeStep);
    }
  }

  Future<void> _sync() async {
    while (!_closed && _handled != _revision) {
      final revision = _revision;
      final asset = _desired;
      try {
        if (asset == null) {
          await player.pause();
          _playing = false;
          _gain = 0;
        } else {
          if (!loop || asset != _loaded) {
            if (loop && _playing) await _fade(0, revision);
            if (!_current(revision)) continue;
            await player.pause();
            _playing = false;
            if (!_current(revision)) continue;
            await player.load(asset, loop: loop);
            _loaded = asset;
            if (!_current(revision)) continue;
            await player.volume(0);
            _gain = 0;
          }
          if (!_current(revision)) continue;
          if (!loop) {
            await player.volume(_desiredGain);
            if (!_current(revision)) continue;
          }
          if (!_playing) {
            player.start();
            _playing = true;
          }
          if (loop) await _fade(_desiredGain, revision);
        }
      } catch (error) {
        _playing = false;
        _loaded = null;
        try {
          await player.pause();
        } catch (_) {
          /* Backend unavailable. */
        }
        onError(error);
      }
      _handled = revision;
    }
  }

  Future<void> get settled async {
    while (_future != null) {
      await _future;
    }
  }

  Future<void> close() async {
    _closed = true;
    _revision++;
    await settled;
    try {
      await player.dispose();
    } catch (error) {
      onError(error);
    }
  }
}

class SoundsController extends ChangeNotifier {
  SoundsController({
    required SoundPlayer ambience,
    required SoundPlayer fire,
    required SoundPlayer steps,
    required SoundPlayer chopping,
    SoundSettingsStore? store,
    Duration fadeStep = const Duration(milliseconds: 40),
    this.stepInterval = const Duration(milliseconds: 380),
  }) : _store = store {
    _ambience = _Channel(ambience, true, fadeStep, _error);
    _fire = _Channel(fire, true, fadeStep, _error);
    _steps = _Channel(steps, false, Duration.zero, _error);
    _chopping = _Channel(chopping, false, Duration.zero, _error);
  }
  factory SoundsController.device() => SoundsController(
    ambience: DeviceSoundPlayer(),
    fire: DeviceSoundPlayer(),
    steps: DeviceSoundPlayer(),
    chopping: DeviceSoundPlayer(),
    store: PreferencesSoundSettings(),
  );
  late final _Channel _ambience, _fire, _steps, _chopping;
  final SoundSettingsStore? _store;
  final Duration stepInterval;
  GameEngine? _game;
  bool enabled = true, available = true;
  double volume = .6;
  bool _ready = false, _foreground = true, _closed = false, _mapOpen = false;
  int _settingsRevision = 0,
      _burstRevision = 0,
      _stepVariant = 0,
      _woodVariant = 0;
  Future<void> _saveFuture = Future.value();
  Future<void>? _burst;
  bool get _audible =>
      _ready &&
      enabled &&
      volume > 0 &&
      _foreground &&
      !_closed &&
      _game?.state.phase != RunPhase.gameOver;
  List<AmbientSound> get selectedAmbience =>
      _game == null ? [] : ambienceForGame(_game!, mapOpen: _mapOpen);
  void _error(Object error) {
    debugPrint('Sounds: $error');
    if (_closed) return;
    available = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    final revision = _settingsRevision;
    try {
      final settings = await _store?.load();
      if (!_closed && revision == _settingsRevision && settings != null) {
        enabled = settings.enabled;
        volume = settings.volume.isFinite ? settings.volume.clamp(0, 1) : .6;
      }
    } catch (error) {
      debugPrint('Sound settings: $error');
    }
    if (_closed) return;
    _ready = true;
    notifyListeners();
    _request();
  }

  void attach(GameEngine game) {
    _game?.removeListener(_request);
    _game?.removeSoundListener(_cue);
    _stopEffects();
    _game = game;
    game.addListener(_request);
    game.addSoundListener(_cue);
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
    // Cancel an in-flight one-shot so its old gain cannot ignore this setting.
    _stopEffects();
    _request();
  }

  void _save() {
    final settings = SoundSettings(enabled: enabled, volume: volume);
    _saveFuture = _saveFuture.then((_) async {
      try {
        await _store?.save(settings);
      } catch (error) {
        debugPrint('Sound settings save: $error');
      }
    });
  }

  void _stopEffects() {
    _burstRevision++;
    _steps.request(null, 0);
    _chopping.request(null, 0);
  }

  void _request() {
    if (_closed) return;
    final sounds = _audible ? selectedAmbience : <AmbientSound>[];
    final gain = volume * (_game?.gathering?.paused == true ? .45 : 1);
    final lightRain =
        sounds.firstOrNull == AmbientSound.rain &&
        _game?.state.weather == 'Light rain' &&
        _game?.state.rescueStage != RescueStage.storm;
    _ambience.request(
      sounds.firstOrNull?.asset,
      sounds.isEmpty ? 0 : gain * sounds.first.gain * (lightRain ? .55 : 1),
    );
    final fire = sounds.contains(AmbientSound.campfire);
    _fire.request(
      fire ? AmbientSound.campfire.asset : null,
      fire ? gain * AmbientSound.campfire.gain : 0,
    );
    if (!_audible || _game?.gathering?.paused == true) _stopEffects();
  }

  void _cue(GameSound sound) {
    if (!_audible || _game?.gathering?.paused == true) return;
    switch (sound) {
      case GameSound.woodChop:
        _woodVariant = _woodVariant % 3 + 1;
        _chopping.request('assets/sounds/wood_$_woodVariant.wav', volume * .8);
      case GameSound.travel:
        final revision = ++_burstRevision;
        _burst = _walk(revision);
    }
  }

  Future<void> _walk(int revision) async {
    for (var i = 0; i < 3; i++) {
      if (!_audible || revision != _burstRevision) return;
      _stepVariant = _stepVariant % 4 + 1;
      _steps.request('assets/sounds/step_$_stepVariant.wav', volume * .6);
      await _steps.settled;
      if (i < 2) await Future<void>.delayed(stepInterval);
    }
  }

  Future<void> get settled async {
    await _saveFuture;
    await _burst;
    await Future.wait([
      _ambience.settled,
      _fire.settled,
      _steps.settled,
      _chopping.settled,
    ]);
  }

  @override
  void dispose() {
    _game?.removeListener(_request);
    _game?.removeSoundListener(_cue);
    _closed = true;
    _burstRevision++;
    for (final channel in [_ambience, _fire, _steps, _chopping]) {
      unawaited(channel.close());
    }
    super.dispose();
  }
}
