import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/password_hasher.dart';
import '../models/user_model.dart';

/// Thrown inside [UserLocalDataSourceImpl.updateProfile] when the requested
/// email is already owned by another account. The surrounding transaction is
/// rolled back, so no partial write can happen.
class DuplicateEmailException implements Exception {
  final String email;

  const DuplicateEmailException(this.email);

  @override
  String toString() => 'DuplicateEmailException($email)';
}

abstract class UserLocalDataSource {
  /// Returns true when at least one user is registered.
  Future<bool> hasRegisteredUser();

  /// Inserts a new user and returns the saved model.
  Future<UserModel> insertUser(UserModel user);

  /// Looks up a user by email, returns null when not found.
  Future<UserModel?> getUserByEmail(String email);

  /// Authenticates a user by email and plain-text password.
  Future<UserModel?> authenticateUser(String email, String plainPassword);

  /// Updates a user's password hash.
  Future<int> updatePassword(String email, String newPasswordHash);

  /// Updates the profile fields of the user identified by [currentEmail].
  ///
  /// Returns the refreshed model, or null when no matching row exists.
  /// Throws [DuplicateEmailException] when [email] is already taken by a
  /// different account. The uniqueness check and the update run inside one
  /// transaction so a rejected save can never partially modify the row.
  Future<UserModel?> updateProfile({
    required String currentEmail,
    required String fullName,
    required String email,
    String? phone,
    String? photo,
  });

  /// Seeds a default demo user when none exist.
  Future<bool> seedDefaultUser();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DatabaseHelper databaseHelper;

  UserLocalDataSourceImpl({required this.databaseHelper});

  static const String tableUsers = 'users';

  static const String _columnId = 'id';
  static const String _columnEmail = 'email';
  static const String _columnFullName = 'full_name';
  static const String _columnPhone = 'phone';
  static const String _columnPhoto = 'photo';
  static const String _columnPasswordHash = 'password_hash';

  @override
  Future<bool> hasRegisteredUser() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(tableUsers, columns: [_columnId], limit: 1);
      return maps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserModel> insertUser(UserModel user) async {
    final db = await databaseHelper.database;
    await db.insert(
      tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return user;
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      tableUsers,
      where: 'LOWER($_columnEmail) = ?',
      whereArgs: [email.toLowerCase().trim()],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<UserModel?> authenticateUser(
    String email,
    String plainPassword,
  ) async {
    final user = await getUserByEmail(email);
    if (user == null) {
      return null;
    }
    // Support both bcrypt and legacy FNV-1a hashes during migration
    if (user.passwordHash.startsWith(r'$2')) {
      if (PasswordHasher.verify(plainPassword, user.passwordHash)) {
        return user;
      }
    } else {
      // Legacy FNV-1a hash
      if (user.passwordHash == PasswordHasher.legacyHash(plainPassword)) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<int> updatePassword(String email, String newPasswordHash) async {
    final db = await databaseHelper.database;
    return db.update(
      tableUsers,
      {_columnPasswordHash: newPasswordHash},
      where: 'LOWER($_columnEmail) = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
  }

  @override
  Future<UserModel?> updateProfile({
    required String currentEmail,
    required String fullName,
    required String email,
    String? phone,
    String? photo,
  }) async {
    final db = await databaseHelper.database;
    final currentKey = currentEmail.toLowerCase().trim();
    final newKey = email.toLowerCase().trim();

    return db.transaction<UserModel?>((txn) async {
      // Uniqueness check inside the same transaction as the write, so a
      // concurrent registration can never produce a partial profile update.
      if (newKey != currentKey) {
        final existing = await txn.query(
          tableUsers,
          columns: [_columnId],
          where: 'LOWER($_columnEmail) = ?',
          whereArgs: [newKey],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          throw DuplicateEmailException(email.trim());
        }
      }

      final updated = await txn.update(
        tableUsers,
        {
          _columnFullName: fullName.trim(),
          _columnEmail: email.trim(),
          _columnPhone: phone,
          _columnPhoto: photo,
        },
        where: 'LOWER($_columnEmail) = ?',
        whereArgs: [currentKey],
      );
      if (updated == 0) return null;

      final rows = await txn.query(
        tableUsers,
        where: 'LOWER($_columnEmail) = ?',
        whereArgs: [newKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return UserModel.fromMap(rows.first);
    });
  }

  @override
  Future<bool> seedDefaultUser() async {
    final hasUser = await hasRegisteredUser();
    if (hasUser) {
      return false;
    }
    await insertUser(
      UserModel(
        id: 'demo-user-0000-0000-0000-000000000001',
        email: 'mohammedsahras850@gmail.com',
        fullName: 'Demo User',
       passwordHash: PasswordHasher.hash('sa3002sa'),// passwordHash: 'sa3002sa',
        createdAt: DateTime(2026, 1, 1),
        isEmailVerified: true,
      ),
    ); //fnv1a:1773485738
    return true;
  }
}
