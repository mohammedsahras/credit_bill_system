import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/domain/entities/customer_entity.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository repository;
  GetCustomersUseCase({required this.repository});
  Future<Either<Failure, List<CustomerEntity>>> execute() =>
      repository.getActiveCustomers();
}

class SearchCustomersUseCase {
  final CustomerRepository repository;
  SearchCustomersUseCase({required this.repository});
  Future<Either<Failure, List<CustomerEntity>>> execute(String query) =>
      repository.searchCustomers(query);
}

class AddCustomerUseCase {
  final CustomerRepository repository;
  AddCustomerUseCase({required this.repository});
  Future<Either<Failure, CustomerEntity>> execute(CustomerEntity customer) =>
      repository.addCustomer(customer);
}

class UpdateCustomerUseCase {
  final CustomerRepository repository;
  UpdateCustomerUseCase({required this.repository});
  Future<Either<Failure, CustomerEntity>> execute(CustomerEntity customer) =>
      repository.updateCustomer(customer);
}

class DeactivateCustomerUseCase {
  final CustomerRepository repository;
  DeactivateCustomerUseCase({required this.repository});
  Future<Either<Failure, bool>> execute(String id) =>
      repository.deactivateCustomer(id);
}

class GetCustomerByIdUseCase {
  final CustomerRepository repository;
  GetCustomerByIdUseCase({required this.repository});
  Future<Either<Failure, CustomerEntity?>> execute(String id) =>
      repository.getCustomerById(id);
}
