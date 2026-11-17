import 'package:bcrypt/bcrypt.dart';


/// Utility for secure password hashing using bcrypt.
class PasswordHasher {
  PasswordHasher._();

  /// Hashes a plaintext password using bcrypt.
  static String hash(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Verifies a plaintext password against a stored bcrypt hash.
  static bool verify(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (_) {
      return false;
    }
  }

  /// Verifies a password against both modern bcrypt hashes and the legacy
  /// FNV-1a format (`fnv1a:<hash>`), so pre-bcrypt accounts can confirm
  /// sensitive profile changes (e.g. an email change) with the password
  /// they actually log in with.
  static bool verifyWithLegacy(String password, String hash) {
    if (hash.startsWith(r'$2')) {
      return verify(password, hash);
    }
    return hash == legacyHash(password);
  }

  /// Legacy FNV-1a hash used before bcrypt was introduced.
  static String legacyHash(String password) {
    var hash = 0x811c9dc5;
    for (final unit in password.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'fnv1a:$hash';
  }
}
