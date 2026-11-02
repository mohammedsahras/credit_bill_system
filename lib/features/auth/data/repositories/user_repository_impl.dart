import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/core/utils/password_hasher.dart';
import 'package:credit_bill_system/features/auth/data/datasources/user_local_data_source.dart';
import 'package:credit_bill_system/features/auth/data/models/user_model.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
import 'package:credit_bill_system/features/auth/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({required this.localDataSource});

  @override
  Future<bool> hasRegisteredUser() async {
    try {
      return await localDataSource.hasRegisteredUser();
    } catch (e) {
      throw DatabaseFailure('Failed to check registered users: $e');
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerUser(UserEntity user) async {
    try {
      final saved = await localDataSource.insertUser(
        UserModel.fromEntity(user),
      );
      return Right(saved);
    } catch (e) {
      return DatabaseFailure('Failed to register user: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final user = await localDataSource.authenticateUser(email, password);
      if (user == null) {
        return const ValidationFailure('Invalid email or password.').asLeft();
      }
      return Right(user);
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      return DatabaseFailure('Login failed: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> findUserByEmail(String email) async {
    try {
      final user = await localDataSource.getUserByEmail(email);
      return Right(user);
    } catch (e) {
      return DatabaseFailure('Failed to find user: $e').asLeft();
    }
  }

  @override
  Future<Either<Failure, UserEntity>> resetPassword(
    String email,
    String newPassword,
  ) async {
    try {
      final existing = await localDataSource.getUserByEmail(email);
      if (existing == null) {
        return const ValidationFailure('No account found with this email.')
            .asLeft();
      }
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      return DatabaseFailure('Failed to verify account: $e').asLeft();
    }

    try {
      final updated = await localDataSource.updatePassword(
        email,
        PasswordHasher.hash(newPassword),
      );
      if (updated == 0) {
        return const NotFoundFailure().asLeft();
      }
      final user = await localDataSource.getUserByEmail(email);
      if (user == null) {
        return const NotFoundFailure().asLeft();
      }
      return Right(user);
    } catch (e) {
      return DatabaseFailure('Failed to reset password: $e').asLeft();
    }
  }
}

extension FailureLeftExt on Failure {
  Either<Failure, T> asLeft<T>() => Left(this);
}
