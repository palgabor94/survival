import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One snapshot contains both active run and persistent profile. Writes must
/// report failures so the UI cannot replace an unrecorded completed journey.
abstract class RunStorage {
  Future<Map<String, dynamic>?> load();
  Future<Map<String, dynamic>?> loadBackup() async => null;
  Future<void> save(Map<String, dynamic> run);
}

class PreferencesRunStorage extends RunStorage {
  static const _key = 'lost_canopy.run';
  static const _backup = 'lost_canopy.run.backup';
  String? _lastGood;
  Map<String, dynamic>? _decode(String? raw) {
    try {
      final j = jsonDecode(raw!) as Map<String, dynamic>;
      return {1, 2, 3}.contains(j['version']) && j['state'] is Map ? j : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    final p = await SharedPreferences.getInstance();
    final primary = p.getString(_key), backup = p.getString(_backup);
    _lastGood = _decode(primary) != null
        ? primary
        : _decode(backup) != null
        ? backup
        : null;
    return _decode(_lastGood);
  }

  @override
  Future<Map<String, dynamic>?> loadBackup() async {
    final backup = (await SharedPreferences.getInstance()).getString(_backup);
    _lastGood = _decode(backup) != null ? backup : null;
    return _decode(_lastGood);
  }

  @override
  Future<void> save(Map<String, dynamic> run) async {
    final encoded = jsonEncode(run);
    final p = await SharedPreferences.getInstance();
    final old = _lastGood ?? p.getString(_key);
    if (_decode(old) != null && !await p.setString(_backup, old!)) {
      throw StateError('Could not preserve previous save');
    }
    // A single preferences value replaces the whole envelope, never half a
    // profile followed by half a run. Engine serializes concurrent requests.
    if (!await p.setString(_key, encoded)) {
      throw StateError('Could not save journey');
    }
    _lastGood = encoded;
  }
}

class MemoryRunStorage extends RunStorage {
  MemoryRunStorage([this.saved]);
  Map<String, dynamic>? saved;
  int saves = 0;
  @override
  Future<Map<String, dynamic>?> load() async =>
      saved == null ? null : jsonDecode(jsonEncode(saved));
  @override
  Future<void> save(Map<String, dynamic> run) async {
    saves++;
    saved = jsonDecode(jsonEncode(run)) as Map<String, dynamic>;
  }
}
