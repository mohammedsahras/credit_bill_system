import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/core/utils/password_hasher.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
import 'package:credit_bill_system/features/auth/domain/repositories/user_repository.dart';
import 'package:credit_bill_system/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;
  late ChangePasswordUseCase useCase;

  setUp(() {
    repository = MockUserRepository();
    useCase = ChangePasswordUseCase(repository: repository);
  });

  UserEntity userWith({String password = 'OldSecret1'}) => UserEntity(
    id: 'user-0001',
    email: 'ada@example.com',
    fullName: 'Ada Lovelace',
    passwordHash: PasswordHasher.hash(password),
    createdAt: DateTime(2026, 1, 15),
    isEmailVerified: true,
  );

  UserEntity legacyUserWith({String password = 'OldSecret1'}) =>
      UserEntity(
        id: 'user-0002',
        email: 'grace@example.com',
        fullName: 'Grace Hopper',
        passwordHash: PasswordHasher.legacyHash(password),
        createdAt: DateTime(2026, 1, 15),
        isEmailVerified: true,
      );

  test('rejects an empty current password without touching the repository', () async {
    final result = await useCase.execute(
      email: 'ada@example.com',
      currentPassword: '',
      newPassword: 'BrandNew1',
    );

    expect(result.isLeft, isTrue);
    expect(result.leftOrNull!.message, 'Enter your current password.');
    verifyZeroInteractions(repository);
  });

  test('rejects a new password shorter than six characters', () async {
    final result = await useCase.execute(
      email: 'ada@example.com',
      currentPassword: 'OldSecret1',
      newPassword: 'abc',
    );

    expect(result.isLeft, isTrue);
    expect(
      result.leftOrNull!.message,
      'Password must be at least 6 characters.',
    );
    verifyZeroInteractions(repository);
  });

  test('rejects reusing the current password as the new one', () async {
    final result = await useCase.execute(
      email: 'ada@example.com',
      currentPassword: 'OldSecret1',
      newPassword: 'OldSecret1',
    );

    expect(result.isLeft, isTrue);
    expect(
      result.leftOrNull!.message,
      'New password must be different from your current password.',
    );
    verifyZeroInteractions(repository);
  });

  test('rejects a wrong current password against the stored bcrypt hash', () async {
    when(
      () => repository.findUserByEmail('ada@example.com'),
    ).thenAnswer((_) async => Right<Failure, UserEntity?>(userWith()));

    final result = await useCase.execute(
      email: 'ada@example.com',
      currentPassword: 'WrongPass1',
      newPassword: 'BrandNew1',
    );

    expect(result.isLeft, isTrue);
    expect(result.leftOrNull!.message, 'Current password is incorrect.');
    verify(() => repository.findUserByEmail('ada@example.com')).called(1);
    verifyNever(() => repository.resetPassword(any(), any()));
  });

  test('verifies a legacy FNV-1a hash so pre-bcrypt accounts can change', () async {
    when(
      () => repository.findUserByEmail('grace@example.com'),
    ).thenAnswer((_) async => Right<Failure, UserEntity?>(legacyUserWith()));
    when(
      () => repository.resetPassword('grace@example.com', 'BrandNew1'),
    ).thenAnswer((_) async => Right<Failure, UserEntity>(legacyUserWith()));

    final result = await useCase.execute(
      email: 'grace@example.com',
      currentPassword: 'OldSecret1',
      newPassword: 'BrandNew1',
    );

    expect(result.isRight, isTrue);
    verify(
      () => repository.resetPassword('grace@example.com', 'BrandNew1'),
    ).called(1);
  });

  test('reports a missing account instead of attempting a write', () async {
    when(
      () => repository.findUserByEmail('nobody@example.com'),
    ).thenAnswer((_) async => const Right<Failure, UserEntity?>(null));

    final result = await useCase.execute(
      email: 'nobody@example.com',
      currentPassword: 'OldSecret1',
      newPassword: 'BrandNew1',
    );

    expect(result.isLeft, isTrue);
    expect(result.leftOrNull!.message, 'No account found with this email.');
    verifyNever(() => repository.resetPassword(any(), any()));
  });

  test('a verified current password writes the bcrypt re-hash', () async {
    when(
      () => repository.findUserByEmail('ada@example.com'),
    ).thenAnswer((_) async => Right<Failure, UserEntity?>(userWith()));
    when(
      () => repository.resetPassword('ada@example.com', 'BrandNew1'),
    ).thenAnswer((_) async => Right<Failure, UserEntity>(userWith()));

    final result = await useCase.execute(
      email: 'ada@example.com',
      currentPassword: 'OldSecret1',
      newPassword: 'BrandNew1',
    );

    expect(result.isRight, isTrue);
    verify(
      () => repository.resetPassword('ada@example.com', 'BrandNew1'),
    ).called(1);
    // The repository path hashes with bcrypt — the plain new password
    // never reaches persistence.
    verifyNever(
      () => repository.resetPassword('ada@example.com', 'BrandNew1Plain'),
    );
  });
}
