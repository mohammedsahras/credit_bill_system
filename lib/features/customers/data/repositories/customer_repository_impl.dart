import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:credit_bill_system/features/customers/data/models/customer_model.dart';
import 'package:credit_bill_system/features/customers/domain/entities/customer_entity.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<CustomerEntity>>> getActiveCustomers() async {
    try {
      final models = await localDataSource.getActiveCustomers();
      return Right(models);
    } catch (e) {
      return DatabaseFailure('Failed to fetch customers: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, CustomerEntity?>> getCustomerById(String id) async {
    try {
      final model = await localDataSource.getCustomerById(id);
      return Right(model);
    } catch (e) {
      return DatabaseFailure('Failed to fetch customer: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(
    String query,
  ) async {
    try {
      final models = await localDataSource.searchCustomers(query);
      return Right(models);
    } catch (e) {
      return DatabaseFailure('Failed to search customers: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> addCustomer(
    CustomerEntity customer,
  ) async {
    try {
      final duplicate = await localDataSource.hasDuplicatePhone(customer.phone);
      if (duplicate) {
        return const ValidationFailure(
          'A customer with this phone number already exists.',
        ).asLeft();
      }
      final saved = await localDataSource.insertCustomer(
        CustomerModel.fromEntity(customer),
      );
      return Right(saved);
    } catch (e) {
      return DatabaseFailure('Failed to add customer: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(
    CustomerEntity customer,
  ) async {
    try {
      final duplicate = await localDataSource.hasDuplicatePhone(
        customer.phone,
        excludeId: customer.id,
      );
      if (duplicate) {
        return const ValidationFailure(
          'A customer with this phone number already exists.',
        ).asLeft();
      }
      await localDataSource.updateCustomer(CustomerModel.fromEntity(customer));
      final updated = await localDataSource.getCustomerById(customer.id);
      if (updated == null) {
        return const NotFoundFailure('Customer not found.').asLeft();
      }
      return Right(updated);
    } catch (e) {
      return DatabaseFailure('Failed to update customer: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, bool>> deactivateCustomer(String id) async {
    try {
      final rows = await localDataSource.deactivateCustomer(id);
      if (rows == 0) {
        return const NotFoundFailure('Customer not found.').asLeft();
      }
      return const Right(true);
    } catch (e) {
      return DatabaseFailure('Failed to deactivate customer: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, bool>> hasDuplicatePhone(
    String phone, {
    String? excludeId,
  }) async {
    try {
      final result = await localDataSource.hasDuplicatePhone(
        phone,
        excludeId: excludeId,
      );
      return Right(result);
    } catch (e) {
      return DatabaseFailure('Failed to check duplicate phone: $e').asLeft();
    }
  }
}

extension FailureLeftExt on Failure {
  Either<Failure, T> asLeft<T>() => Left(this);
}
