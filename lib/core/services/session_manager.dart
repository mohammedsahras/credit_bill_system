import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Manages login session persistence using a local file.
class SessionManager {
  static const String _fileName = 'session.json';

  static Future<File> _sessionFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Saves the login session.
  static Future<void> saveSession({
    required String email,
    required String fullName,
  }) async {
    final file = await _sessionFile();
    await file.writeAsString(
      jsonEncode({'is_logged_in': true, 'email': email, 'full_name': fullName}),
    );
  }

  /// Clears the login session (logout).
  static Future<void> clearSession() async {
    final file = await _sessionFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Checks if a session exists.
  static Future<bool> hasSession() async {
    final file = await _sessionFile();
    if (!await file.exists()) return false;
    try {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return data['is_logged_in'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Gets the saved session data.
  static Future<Map<String, String>?> getSession() async {
    final file = await _sessionFile();
    if (!await file.exists()) return null;
    try {
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
