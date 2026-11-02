import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/credit_transaction_model.dart';

abstract class CreditTransactionLocalDataSource {
  Future<List<CreditTransactionModel>> getTransactionsByCustomer(
    String customerId,
  );
  Future<CreditTransactionModel> insertTransaction(
    CreditTransactionModel transaction,
  );
  Future<int> getTransactionAllocatedAmount(String transactionId);
}

class CreditTransactionLocalDataSourceImpl
    implements CreditTransactionLocalDataSource {
  final DatabaseHelper databaseHelper;

  CreditTransactionLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<CreditTransactionModel>> getTransactionsByCustomer(
    String customerId,
  ) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCreditTransactions,
      where: '${DatabaseHelper.columnCreditTransactionCustomerId} = ?',
      whereArgs: [customerId],
      orderBy: '${DatabaseHelper.columnCreditTransactionCreatedAt} DESC',
    );
    return maps.map((m) => CreditTransactionModel.fromMap(m)).toList();
  }

  @override
  Future<CreditTransactionModel> insertTransaction(
    CreditTransactionModel transaction,
  ) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableCreditTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return transaction;
  }

  @override
  Future<int> getTransactionAllocatedAmount(String transactionId) async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(${DatabaseHelper.columnAllocationAmount}), 0) as total FROM ${DatabaseHelper.tablePaymentAllocations} WHERE ${DatabaseHelper.columnAllocationTransactionId} = ?',
      [transactionId],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
