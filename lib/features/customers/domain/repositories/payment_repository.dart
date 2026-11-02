import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/domain/entities/payment_entity.dart';
import 'package:credit_bill_system/features/customers/domain/entities/payment_allocation_entity.dart';

abstract class PaymentRepository {
  Future<Either<Failure, PaymentEntity>> recordPayment({
    required PaymentEntity payment,
    required List<PaymentAllocationEntity> allocations,
  });
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByCustomer(
    String customerId,
  );
  Future<Either<Failure, int>> getCustomerTotalPaid(String customerId);
}
