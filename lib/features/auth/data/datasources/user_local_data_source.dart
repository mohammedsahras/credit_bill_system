import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/password_hasher.dart';
import '../models/user_model.dart';

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

  /// Seeds a default demo user when none exist.
  Future<bool> seedDefaultUser();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DatabaseHelper databaseHelper;

  UserLocalDataSourceImpl({required this.databaseHelper});

  static const String tableUsers = 'users';

  static const String _columnId = 'id';
  static const String _columnEmail = 'email';
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
      where: '$_columnEmail = ?',
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
      if (user.passwordHash == _legacyHash(plainPassword)) {
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
      where: '$_columnEmail = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
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
        email: 'demo@creditbill.com',
        fullName: 'Demo User',
        passwordHash: 'fnv1a:1773485738',
        createdAt: DateTime(2026, 1, 1),
        isEmailVerified: true,
      ),
    );
    return true;
  }

  static String _legacyHash(String password) {
    var hash = 0x811c9dc5;
    for (final unit in password.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'fnv1a:$hash';
  }
}
