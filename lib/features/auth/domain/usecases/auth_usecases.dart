import 'package:uuid/uuid.dart';
import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/core/utils/password_hasher.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
import 'package:credit_bill_system/features/auth/domain/repositories/user_repository.dart';
import 'package:credit_bill_system/core/config/dev_credentials.dart';

/// Authenticates an existing user by email and plain-text password.
class LoginUseCase {
  final UserRepository repository;
  LoginUseCase({required this.repository});
  Future<Either<Failure, UserEntity>> execute({
    required String email,
    required String password,
  }) async {
    return repository.loginUser(email, password);
  }
}

/// Initiates password recovery for a registered email address.
class ForgotPasswordUseCase {
  final UserRepository repository;
  ForgotPasswordUseCase({required this.repository});
  Future<Either<Failure, UserEntity?>> execute({required String email}) async {
    return repository.findUserByEmail(email);
  }
}

/// Resets a user's password to a new value.
class ResetPasswordUseCase {
  final UserRepository repository;
  ResetPasswordUseCase({required this.repository});
  Future<Either<Failure, UserEntity>> execute({
    required String email,
    required String newPassword,
  }) async {
    return repository.resetPassword(email, newPassword);
  }
}

/// Seeds a default demo user when the database is first created.
class SeedDefaultUserUseCase {
  final UserRepository repository;
  SeedDefaultUserUseCase({required this.repository});
  Future<Either<Failure, bool>> execute() async {
    final hasUser = await repository.hasRegisteredUser();
    if (hasUser) {
      return const Right(false);
    }
    final result = await repository.registerUser(
      UserEntity(
        id: 'demo-user-0000-0000-0000-000000000001',
        email: 'demo@creditbill.com',
        fullName: 'Demo User',
        passwordHash: PasswordHasher.hash('Demo@1234'),
        createdAt: DateTime(2026, 1, 1),
        isEmailVerified: true,
      ),
    );
    return result.fold((failure) => Left(failure), (_) => const Right(true));
  }
}

/// Seeds the development account from local credentials.
/// Reads from lib/core/config/dev_credentials.dart (gitignored).
/// If credentials are placeholders, skips seeding.
class SeedDevAccountUseCase {
  final UserRepository repository;
  SeedDevAccountUseCase({required this.repository});

  Future<Either<Failure, bool>> execute() async {
    // Skip if credentials are placeholders
    if (devPassword == 'CHANGE_ME_BEFORE_RUNNING' || devPassword.isEmpty) {
      return const Right(false);
    }

    // Check if account already exists
    final existing = await repository.findUserByEmail(devEmail);
    if (existing.isRight && existing.rightOrNull != null) {
      final user = existing.rightOrNull!;
      // Verify password hash matches; update if not
      if (!PasswordHasher.verify(devPassword, user.passwordHash)) {
        final updateResult = await repository.resetPassword(
          devEmail,
          devPassword,
        );
        return updateResult.fold(
          (failure) => Left(failure),
          (_) => const Right(true),
        );
      }
      return const Right(false); // Already exists with correct password
    }

    // Create the dev account with bcrypt-hashed password
    final result = await repository.registerUser(
      UserEntity(
        id: const Uuid().v4(),
        email: devEmail,
        fullName: devFullName,
        passwordHash: PasswordHasher.hash(devPassword),
        createdAt: DateTime.now(),
        isEmailVerified: true,
      ),
    );
    return result.fold((failure) => Left(failure), (_) => const Right(true));
  }
}
