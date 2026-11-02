import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/domain/entities/credit_transaction_entity.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/credit_transaction_repository.dart';

class GetCustomerTransactionsUseCase {
  final CreditTransactionRepository repository;
  GetCustomerTransactionsUseCase({required this.repository});
  Future<Either<Failure, List<CreditTransactionEntity>>> execute(
    String customerId,
  ) => repository.getTransactionsByCustomer(customerId);
}

class AddCreditTransactionUseCase {
  final CreditTransactionRepository repository;
  AddCreditTransactionUseCase({required this.repository});
  Future<Either<Failure, CreditTransactionEntity>> execute(
    CreditTransactionEntity transaction,
  ) => repository.addTransaction(transaction);
}
