import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';

/// Interface for user authentication & password recovery operations.
abstract class UserRepository {
  /// Returns true when at least one user is registered in the database.
  Future<bool> hasRegisteredUser();

  /// Pershes a newly registered user and returns the saved entity.
  Future<Either<Failure, UserEntity>> registerUser(UserEntity user);

  /// Authenticates a user by email + plain password.
  Future<Either<Failure, UserEntity>> loginUser(String email, String password);

  /// Looks up a user by email for password recovery.
  Future<Either<Failure, UserEntity?>> findUserByEmail(String email);

  /// Resets a user's password after validating recovery identity.
  Future<Either<Failure, UserEntity>> resetPassword(
    String email,
    String newPassword,
  );

  /// Updates the profile fields (name, email, phone, photo) of the user
  /// identified by [currentEmail] and returns the refreshed entity.
  ///
  /// Returns a [ConflictFailure] when the new email is already taken, and a
  /// [NotFoundFailure] when no account matches [currentEmail].
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String currentEmail,
    required String fullName,
    required String email,
    String? phone,
    String? photo,
  });
}
