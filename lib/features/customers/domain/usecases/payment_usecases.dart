import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/domain/entities/payment_entity.dart';
import 'package:credit_bill_system/features/customers/domain/entities/payment_allocation_entity.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/payment_repository.dart';

class RecordPaymentUseCase {
  final PaymentRepository repository;
  RecordPaymentUseCase({required this.repository});
  Future<Either<Failure, PaymentEntity>> execute({
    required PaymentEntity payment,
    required List<PaymentAllocationEntity> allocations,
  }) => repository.recordPayment(payment: payment, allocations: allocations);
}

class GetCustomerPaymentsUseCase {
  final PaymentRepository repository;
  GetCustomerPaymentsUseCase({required this.repository});
  Future<Either<Failure, List<PaymentEntity>>> execute(String customerId) =>
      repository.getPaymentsByCustomer(customerId);
}

class GetCustomerTotalPaidUseCase {
  final PaymentRepository repository;
  GetCustomerTotalPaidUseCase({required this.repository});
  Future<Either<Failure, int>> execute(String customerId) =>
      repository.getCustomerTotalPaid(customerId);
}
