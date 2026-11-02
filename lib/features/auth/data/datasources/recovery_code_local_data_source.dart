import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';

abstract class RecoveryCodeLocalDataSource {
  Future<String> generateAndStoreCode(String email);
  Future<bool> verifyCode(String email, String code);
  Future<void> markCodeUsed(String email, String code);
  Future<void> invalidatePreviousCodes(String email);
}

class RecoveryCodeLocalDataSourceImpl implements RecoveryCodeLocalDataSource {
  final DatabaseHelper databaseHelper;
  final _uuid = const Uuid();
  final _random = Random.secure();

  RecoveryCodeLocalDataSourceImpl({required this.databaseHelper});

  static const int _expirationMinutes = 10;
  static const int _maxAttempts = 5;

  @override
  Future<String> generateAndStoreCode(String email) async {
    final db = await databaseHelper.database;

    // Invalidate previous codes
    await invalidatePreviousCodes(email);

    // Generate cryptographically secure 6-digit code
    final code = _generateCode();
    final codeHash = BCrypt.hashpw(code, BCrypt.gensalt());
    final expiresAt = DateTime.now().add(
      const Duration(minutes: _expirationMinutes),
    );

    await db.insert(DatabaseHelper.tableRecoveryCodes, {
      DatabaseHelper.columnRecoveryId: _uuid.v4(),
      DatabaseHelper.columnRecoveryEmail: email.toLowerCase().trim(),
      DatabaseHelper.columnRecoveryCodeHash: codeHash,
      DatabaseHelper.columnRecoveryExpiresAt: expiresAt.toIso8601String(),
      DatabaseHelper.columnRecoveryAttempts: 0,
      DatabaseHelper.columnRecoveryMaxAttempts: _maxAttempts,
      DatabaseHelper.columnRecoveryUsed: 0,
      DatabaseHelper.columnRecoveryCreatedAt: DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return code; // Return plaintext code for "email delivery" (in production, this goes via backend)
  }

  @override
  Future<bool> verifyCode(String email, String code) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableRecoveryCodes,
      where:
          '${DatabaseHelper.columnRecoveryEmail} = ? AND ${DatabaseHelper.columnRecoveryUsed} = 0',
      whereArgs: [email.toLowerCase().trim()],
      orderBy: '${DatabaseHelper.columnRecoveryCreatedAt} DESC',
      limit: 1,
    );

    if (maps.isEmpty) return false;

    final row = maps.first;
    final expiresAt = DateTime.parse(
      row[DatabaseHelper.columnRecoveryExpiresAt] as String,
    );
    if (DateTime.now().isAfter(expiresAt)) return false; // Expired

    final attempts = row[DatabaseHelper.columnRecoveryAttempts] as int;
    final maxAttempts = row[DatabaseHelper.columnRecoveryMaxAttempts] as int;
    if (attempts >= maxAttempts) return false; // Too many attempts

    // Increment attempts
    await db.update(
      DatabaseHelper.tableRecoveryCodes,
      {DatabaseHelper.columnRecoveryAttempts: attempts + 1},
      where: '${DatabaseHelper.columnRecoveryId} = ?',
      whereArgs: [row[DatabaseHelper.columnRecoveryId]],
    );

    // Verify code against hash
    final codeHash = row[DatabaseHelper.columnRecoveryCodeHash] as String;
    try {
      return BCrypt.checkpw(code, codeHash);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markCodeUsed(String email, String code) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseHelper.tableRecoveryCodes,
      {DatabaseHelper.columnRecoveryUsed: 1},
      where:
          '${DatabaseHelper.columnRecoveryEmail} = ? AND ${DatabaseHelper.columnRecoveryUsed} = 0',
      whereArgs: [email.toLowerCase().trim()],
    );
  }

  @override
  Future<void> invalidatePreviousCodes(String email) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseHelper.tableRecoveryCodes,
      {DatabaseHelper.columnRecoveryUsed: 1},
      where:
          '${DatabaseHelper.columnRecoveryEmail} = ? AND ${DatabaseHelper.columnRecoveryUsed} = 0',
      whereArgs: [email.toLowerCase().trim()],
    );
  }

  String _generateCode() {
    // Generate a 6-digit code using secure random
    final code = _random.nextInt(900000) + 100000;
    return code.toString();
  }
}
