import 'dart:convert';

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

/// Loads the stored profile of a registered user for the settings and
/// edit-profile screens.
class GetProfileUseCase {
  final UserRepository repository;
  GetProfileUseCase({required this.repository});

  /// Returns the user matching [email], or `Right(null)` when no account
  /// exists for that address.
  Future<Either<Failure, UserEntity?>> execute({required String email}) {
    return repository.findUserByEmail(email);
  }
}

/// Updates the signed-in user's profile (name, email, phone, photo).
///
/// Validation happens before any write, and changing the email address
/// additionally requires the account's current password — verified against
/// the stored hash — so an unattended device cannot re-point the account.
class UpdateProfileUseCase {
  final UserRepository repository;
  UpdateProfileUseCase({required this.repository});

  static final RegExp _emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9()\-\s]{6,20}$');

  /// Upper bound for the stored base64 photo (~300 KB of binary data).
  static const int _maxPhotoLength = 400 * 1024;

  Future<Either<Failure, UserEntity>> execute({
    required String currentEmail,
    required String fullName,
    required String email,
    String? phone,
    String? photo,
    String? currentPassword,
  }) async {
    final name = fullName.trim();
    final newEmail = email.trim();
    final newPhone = (phone ?? '').trim();
    final newPhoto = (photo == null || photo.isEmpty) ? null : photo;

    if (name.isEmpty) {
      return Left(const ValidationFailure('Name cannot be empty.'));
    }
    if (!_emailRegex.hasMatch(newEmail)) {
      return Left(const ValidationFailure('Enter a valid email address.'));
    }
    if (newPhone.isNotEmpty && !_phoneRegex.hasMatch(newPhone)) {
      return Left(const ValidationFailure('Enter a valid phone number.'));
    }
    if (newPhoto != null) {
      if (newPhoto.length > _maxPhotoLength) {
        return Left(
          const ValidationFailure(
            'Please choose a smaller photo (max 300 KB).',
          ),
        );
      }
      try {
        base64Decode(newPhoto);
      } catch (_) {
        return Left(
          const ValidationFailure(
            'The selected photo could not be read. Please choose another image.',
          ),
        );
      }
    }

    final emailChanged =
        newEmail.toLowerCase() != currentEmail.trim().toLowerCase();
    if (emailChanged) {
      if (currentPassword == null || currentPassword.isEmpty) {
        return Left(
          const ValidationFailure(
            'Enter your current password to change your email address.',
          ),
        );
      }
      final existing = await repository.findUserByEmail(currentEmail.trim());
      if (existing.isLeft) return Left(existing.leftOrNull!);
      final user = existing.rightOrNull;
      if (user == null) {
        return Left(
          const NotFoundFailure('No account found with this email.'),
        );
      }
      if (!PasswordHasher.verifyWithLegacy(
        currentPassword,
        user.passwordHash,
      )) {
        return Left(const ValidationFailure('Current password is incorrect.'));
      }
    }

    return repository.updateUserProfile(
      currentEmail: currentEmail.trim(),
      fullName: name,
      email: newEmail,
      phone: newPhone.isEmpty ? null : newPhone,
      photo: newPhoto,
    );
  }
}

/// Changes the signed-in user's password after verifying the current one.
///
/// The current password is checked against the stored hash with the
/// legacy-aware hasher (the same code path login and the email-change
/// confirmation use), and the new value is re-hashed with bcrypt by the
/// existing [UserRepository.resetPassword] — no plain-text password ever
/// reaches the database, and no new repository/schema surface is added.
class ChangePasswordUseCase {
  final UserRepository repository;
  ChangePasswordUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> execute({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final address = email.trim();
    if (currentPassword.isEmpty) {
      return Left(const ValidationFailure('Enter your current password.'));
    }
    if (newPassword.length < 6) {
      return Left(
        const ValidationFailure('Password must be at least 6 characters.'),
      );
    }
    if (newPassword == currentPassword) {
      return Left(
        const ValidationFailure(
          'New password must be different from your current password.',
        ),
      );
    }

    final existing = await repository.findUserByEmail(address);
    if (existing.isLeft) return Left(existing.leftOrNull!);
    final user = existing.rightOrNull;
    if (user == null) {
      return Left(const NotFoundFailure('No account found with this email.'));
    }
    if (!PasswordHasher.verifyWithLegacy(currentPassword, user.passwordHash)) {
      return Left(const ValidationFailure('Current password is incorrect.'));
    }
    return repository.resetPassword(address, newPassword);
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
