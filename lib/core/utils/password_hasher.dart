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
}
