import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/domain/entities/credit_transaction_entity.dart';

abstract class CreditTransactionRepository {
  Future<Either<Failure, List<CreditTransactionEntity>>>
  getTransactionsByCustomer(String customerId);
  Future<Either<Failure, CreditTransactionEntity>> addTransaction(
    CreditTransactionEntity transaction,
  );
  Future<Either<Failure, int>> getTransactionOutstanding(String transactionId);
}
