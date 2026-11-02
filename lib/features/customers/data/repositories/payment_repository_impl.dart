import 'package:sqflite/sqflite.dart';
import 'package:credit_bill_system/core/database/database_helper.dart';
import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/data/datasources/payment_local_data_source.dart';
import 'package:credit_bill_system/features/customers/data/models/payment_model.dart';
import 'package:credit_bill_system/features/customers/domain/entities/payment_entity.dart';
import 'package:credit_bill_system/features/customers/domain/entities/payment_allocation_entity.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentLocalDataSource localDataSource;
  final DatabaseHelper databaseHelper;

  PaymentRepositoryImpl({
    required this.localDataSource,
    required this.databaseHelper,
  });

  @override
  Future<Either<Failure, PaymentEntity>> recordPayment({
    required PaymentEntity payment,
    required List<PaymentAllocationEntity> allocations,
  }) async {
    try {
      // Validate total allocations don't exceed payment amount
      final totalAllocated = allocations.fold<int>(
        0,
        (sum, a) => sum + a.allocatedAmountMinor,
      );
      if (totalAllocated > payment.amountMinor) {
        return const ValidationFailure(
          'Total allocations exceed payment amount.',
        ).asLeft();
      }

      final db = await databaseHelper.database;
      await db.transaction((txn) async {
        // Insert payment
        await txn.insert(
          DatabaseHelper.tablePayments,
          PaymentModel.fromEntity(payment).toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        // Insert allocations
        for (final alloc in allocations) {
          await txn.insert(DatabaseHelper.tablePaymentAllocations, {
            'id': alloc.id,
            DatabaseHelper.columnAllocationPaymentId: alloc.paymentId,
            DatabaseHelper.columnAllocationTransactionId:
                alloc.creditTransactionId,
            DatabaseHelper.columnAllocationAmount: alloc.allocatedAmountMinor,
            DatabaseHelper.columnAllocationCreatedAt: alloc.createdAt
                .toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.abort);
        }
      });

      return Right(payment);
    } catch (e) {
      return DatabaseFailure('Failed to record payment: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByCustomer(
    String customerId,
  ) async {
    try {
      final models = await localDataSource.getPaymentsByCustomer(customerId);
      return Right(models);
    } catch (e) {
      return DatabaseFailure('Failed to fetch payments: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, int>> getCustomerTotalPaid(String customerId) async {
    try {
      final total = await localDataSource.getCustomerTotalPaid(customerId);
      return Right(total);
    } catch (e) {
      return DatabaseFailure('Failed to get total paid: $e').asLeft();
    }
  }
}

extension FailureLeftExt on Failure {
  Either<Failure, T> asLeft<T>() => Left(this);
}
