import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';
import '../models/payment_model.dart';

abstract class PaymentLocalDataSource {
  Future<PaymentModel> insertPayment(PaymentModel payment);
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId);
  Future<int> getCustomerTotalPaid(String customerId);
  Future<void> insertAllocation({
    required String paymentId,
    required String transactionId,
    required int allocatedAmountMinor,
  });
}

class PaymentLocalDataSourceImpl implements PaymentLocalDataSource {
  final DatabaseHelper databaseHelper;

  PaymentLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<PaymentModel> insertPayment(PaymentModel payment) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tablePayments,
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return payment;
  }

  @override
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tablePayments,
      where: '${DatabaseHelper.columnPaymentCustomerId} = ?',
      whereArgs: [customerId],
      orderBy: '${DatabaseHelper.columnPaymentDate} DESC',
    );
    return maps.map((m) => PaymentModel.fromMap(m)).toList();
  }

  @override
  Future<int> getCustomerTotalPaid(String customerId) async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(${DatabaseHelper.columnPaymentAmount}), 0) as total FROM ${DatabaseHelper.tablePayments} WHERE ${DatabaseHelper.columnPaymentCustomerId} = ?',
      [customerId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<void> insertAllocation({
    required String paymentId,
    required String transactionId,
    required int allocatedAmountMinor,
  }) async {
    final db = await databaseHelper.database;
    await db.insert(DatabaseHelper.tablePaymentAllocations, {
      'id': const Uuid().v4(),
      DatabaseHelper.columnAllocationPaymentId: paymentId,
      DatabaseHelper.columnAllocationTransactionId: transactionId,
      DatabaseHelper.columnAllocationAmount: allocatedAmountMinor,
      DatabaseHelper.columnAllocationCreatedAt: DateTime.now()
          .toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }
}
