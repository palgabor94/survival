import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keeps one saved run. Implementations must never throw: a broken save
/// simply starts a fresh run.
abstract class RunStorage {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> run);
}

class PreferencesRunStorage implements RunStorage {
  static const _key = 'lost_canopy.run';

  @override
  Future<Map<String, dynamic>?> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> run) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode(run),
      );
    } catch (_) {
      // Saving is best effort; the run continues in memory.
    }
  }
}

class MemoryRunStorage implements RunStorage {
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
