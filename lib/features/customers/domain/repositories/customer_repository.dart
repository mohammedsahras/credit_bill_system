import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerEntity>>> getActiveCustomers();
  Future<Either<Failure, CustomerEntity?>> getCustomerById(String id);
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(String query);
  Future<Either<Failure, CustomerEntity>> addCustomer(CustomerEntity customer);
  Future<Either<Failure, CustomerEntity>> updateCustomer(
    CustomerEntity customer,
  );
  Future<Either<Failure, bool>> deactivateCustomer(String id);
  Future<Either<Failure, bool>> hasDuplicatePhone(
    String phone, {
    String? excludeId,
  });
}
