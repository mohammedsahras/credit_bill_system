import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Manages login session persistence using a local file.
/// On Web, file-based storage is unavailable, so session persistence
/// gracefully degrades to in-memory (session lost on refresh).
class SessionManager {
  static const String _fileName = 'session.json';

  // In-memory fallback for Web where dart:io File is unavailable.
  static Map<String, String>? _webSession;

  static Future<File?> _sessionFile() async {
    // On Web, dart:io File and getApplicationDocumentsDirectory are unavailable.
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  /// Saves the login session.
  static Future<void> saveSession({
    required String email,
    required String fullName,
  }) async {
    if (kIsWeb) {
      // Web: use in-memory session (persists for this tab session only).
      _webSession = {'email': email, 'fullName': fullName};
      return;
    }
    try {
      final file = await _sessionFile();
      if (file == null) return;
      await file.writeAsString(
        jsonEncode({'is_logged_in': true, 'email': email, 'full_name': fullName}),
      );
    } catch (e) {
      // Session persistence is a convenience; failure must not block auth.
      debugPrint('Session save failed: $e');
    }
  }

  /// Clears the login session (logout).
  static Future<void> clearSession() async {
    if (kIsWeb) {
      _webSession = null;
      return;
    }
    try {
      final file = await _sessionFile();
      if (file == null) return;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Session clear failed: $e');
    }
  }

  /// Checks if a session exists.
  static Future<bool> hasSession() async {
    if (kIsWeb) {
      return _webSession != null;
    }
    try {
      final file = await _sessionFile();
      if (file == null) return false;
      if (!await file.exists()) return false;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return data['is_logged_in'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Gets the saved session data.
  static Future<Map<String, String>?> getSession() async {
    if (kIsWeb) {
      return _webSession;
    }
    try {
      final file = await _sessionFile();
      if (file == null) return null;
      if (!await file.exists()) return null;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (data['is_logged_in'] != true) return null;
      final email = data['email'] as String?;
      if (email == null) return null;
      return {'email': email, 'fullName': (data['full_name'] as String?) ?? ''};
    } catch (_) {
      return null;
    }
  }
}
