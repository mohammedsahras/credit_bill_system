import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/data/datasources/credit_transaction_local_data_source.dart';
import 'package:credit_bill_system/features/customers/data/models/credit_transaction_model.dart';
import 'package:credit_bill_system/features/customers/domain/entities/credit_transaction_entity.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/credit_transaction_repository.dart';

class CreditTransactionRepositoryImpl implements CreditTransactionRepository {
  final CreditTransactionLocalDataSource localDataSource;

  CreditTransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<CreditTransactionEntity>>>
  getTransactionsByCustomer(String customerId) async {
    try {
      final models = await localDataSource.getTransactionsByCustomer(
        customerId,
      );
      return Right(models);
    } catch (e) {
      return DatabaseFailure('Failed to fetch transactions: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, CreditTransactionEntity>> addTransaction(
    CreditTransactionEntity transaction,
  ) async {
    try {
      final saved = await localDataSource.insertTransaction(
        CreditTransactionModel.fromEntity(transaction),
      );
      return Right(saved);
    } catch (e) {
      return DatabaseFailure('Failed to add transaction: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, int>> getTransactionOutstanding(
    String transactionId,
  ) async {
    try {
      final allocated = await localDataSource.getTransactionAllocatedAmount(
        transactionId,
      );
      return Right(allocated);
    } catch (e) {
      return DatabaseFailure('Failed to get outstanding: $e').asLeft();
    }
  }
}

extension FailureLeftExt on Failure {
  Either<Failure, T> asLeft<T>() => Left(this);
}
