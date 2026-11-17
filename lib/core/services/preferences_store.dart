import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:path_provider/path_provider.dart';

/// Local, offline key/value store for app preferences (theme mode today;
/// further settings as they land).
///
/// Follows the [SessionManager] pattern: a JSON file in the app documents
/// directory on native platforms, an in-memory fallback on web where
/// `dart:io` is unavailable. Nothing here ever leaves the device.
class PreferencesStore {
  PreferencesStore({this.fileName = defaultFileName});

  static const String defaultFileName = 'preferences.json';

  /// Shared instance used by the app.
  static final PreferencesStore instance = PreferencesStore();

  final String fileName;

  // In-memory fallback for Web where dart:io File is unavailable.
  Map<String, dynamic>? _memory;

  Future<File?> _prefsFile() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$fileName');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _read() async {
    if (kIsWeb) return _memory ??= <String, dynamic>{};
    try {
      final file = await _prefsFile();
      if (file == null || !await file.exists()) return <String, dynamic>{};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      // A corrupt/unreadable file behaves like "nothing stored yet".
      return <String, dynamic>{};
    }
  }

  Future<void> _write(Map<String, dynamic> prefs) async {
    if (kIsWeb) {
      _memory = prefs;
      return;
    }
    try {
      final file = await _prefsFile();
      if (file == null) return;
      await file.writeAsString(jsonEncode(prefs));
    } catch (e) {
      // Preferences are a convenience; persistence failure must not crash.
      debugPrint('Preferences save failed: $e');
    }
  }

  /// Last chosen theme mode, or [ThemeMode.system] when unset/unknown.
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await _read();
    switch (prefs['theme_mode'] as String?) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Persists the theme mode.
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _read();
    prefs['theme_mode'] = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _write(prefs);
  }
}
