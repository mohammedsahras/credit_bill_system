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
  late UpdateProfileUseCase useCase;

  UserEntity storedUser({
    String email = 'ada@example.com',
    String? passwordHash,
  }) {
    return UserEntity(
      id: 'user-1',
      email: email,
      fullName: 'Ada Lovelace',
      passwordHash: passwordHash ?? PasswordHasher.hash('Secret123!'),
      createdAt: DateTime(2026, 1, 1),
      isEmailVerified: true,
      phone: '+94 77 123 4567',
    );
  }

  void stubProfileUpdate({Either<Failure, UserEntity>? result}) {
    when(
      () => repository.updateUserProfile(
        currentEmail: any(named: 'currentEmail'),
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        photo: any(named: 'photo'),
      ),
    ).thenAnswer(
      (_) async =>
          result ??
          Right<Failure, UserEntity>(storedUser(email: 'ada@example.com')),
    );
  }

  setUp(() {
    repository = MockUserRepository();
    useCase = UpdateProfileUseCase(repository: repository);
  });

  group('validation runs before any write', () {
    test('rejects an empty name', () async {
      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: '   ',
        email: 'ada@example.com',
      );

      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(
        (result.leftOrNull! as ValidationFailure).message,
        'Name cannot be empty.',
      );
      verifyNever(
        () => repository.updateUserProfile(
          currentEmail: any(named: 'currentEmail'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          photo: any(named: 'photo'),
        ),
      );
    });

    test('rejects a malformed email', () async {
      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada',
        email: 'not-an-email',
      );

      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(
        (result.leftOrNull! as ValidationFailure).message,
        'Enter a valid email address.',
      );
    });

    test('rejects a malformed phone number', () async {
      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada',
        email: 'ada@example.com',
        phone: 'call-me',
      );

      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(
        (result.leftOrNull! as ValidationFailure).message,
        'Enter a valid phone number.',
      );
    });

    test('rejects a photo that is not valid base64', () async {
      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada',
        email: 'ada@example.com',
        photo: '!!!not-base64!!!',
      );

      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(
        (result.leftOrNull! as ValidationFailure).message,
        contains('photo could not be read'),
      );
    });

    test('rejects an oversized photo', () async {
      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada',
        email: 'ada@example.com',
        photo: 'A' * (400 * 1024 + 1),
      );

      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(
        (result.leftOrNull! as ValidationFailure).message,
        contains('smaller photo'),
      );
    });
  });

  group('successful updates', () {
    test('normalises the values and passes them to the repository', () async {
      stubProfileUpdate();

      final result = await useCase.execute(
        currentEmail: '  ada@example.com ',
        fullName: '  Ada Lovelace  ',
        email: 'ada@example.com',
        phone: '',
      );

      expect(result.isRight, isTrue);
      verify(
        () => repository.updateUserProfile(
          currentEmail: 'ada@example.com',
          fullName: 'Ada Lovelace',
          email: 'ada@example.com',
          phone: null,
          photo: null,
        ),
      ).called(1);
    });

    test('keeps an empty phone as null instead of an empty string', () async {
      stubProfileUpdate();

      await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada Lovelace',
        email: 'ada@example.com',
        phone: '   ',
      );

      verify(
        () => repository.updateUserProfile(
          currentEmail: any(named: 'currentEmail'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          phone: null,
          photo: null,
        ),
      ).called(1);
    });
  });

  group('email changes require the current password', () {
    test('are blocked without a password', () async {
      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada Lovelace',
        email: 'new@example.com',
      );

      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(
        (result.leftOrNull! as ValidationFailure).message,
        contains('current password'),
      );
      verifyNever(() => repository.findUserByEmail(any()));
      verifyNever(
        () => repository.updateUserProfile(
          currentEmail: any(named: 'currentEmail'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          photo: any(named: 'photo'),
        ),
      );
    });

    test('are rejected when the password is wrong', () async {
      when(() => repository.findUserByEmail('ada@example.com'))
          .thenAnswer((_) async => Right<Failure, UserEntity?>(storedUser()));

      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada Lovelace',
        email: 'new@example.com',
        currentPassword: 'wrong-password',
      );

      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(
        (result.leftOrNull! as ValidationFailure).message,
        'Current password is incorrect.',
      );
      // No database write happened for the rejected change.
      verifyNever(
        () => repository.updateUserProfile(
          currentEmail: any(named: 'currentEmail'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          photo: any(named: 'photo'),
        ),
      );
    });

    test('are accepted when the password is correct', () async {
      when(() => repository.findUserByEmail('ada@example.com'))
          .thenAnswer((_) async => Right<Failure, UserEntity?>(storedUser()));
      stubProfileUpdate(
        result: Right<Failure, UserEntity>(
          storedUser(email: 'new@example.com'),
        ),
      );

      final result = await useCase.execute(
        currentEmail: 'ada@example.com',
        fullName: 'Ada Lovelace',
        email: 'new@example.com',
        currentPassword: 'Secret123!',
      );

      expect(result.isRight, isTrue);
      verify(
        () => repository.updateUserProfile(
          currentEmail: 'ada@example.com',
          fullName: 'Ada Lovelace',
          email: 'new@example.com',
          phone: any(named: 'phone'),
          photo: any(named: 'photo'),
        ),
      ).called(1);
    });

    test('still work for legacy FNV-1a accounts', () async {
      when(() => repository.findUserByEmail('legacy@example.com')).thenAnswer(
        (_) async => Right<Failure, UserEntity?>(
          storedUser(
            email: 'legacy@example.com',
            passwordHash: PasswordHasher.legacyHash('old-password'),
          ),
        ),
      );
      stubProfileUpdate();

      final result = await useCase.execute(
        currentEmail: 'legacy@example.com',
        fullName: 'Legacy User',
        email: 'legacy2@example.com',
        currentPassword: 'old-password',
      );

      expect(result.isRight, isTrue);
    });

    test('surface a missing account as NotFound', () async {
      when(() => repository.findUserByEmail('ghost@example.com'))
          .thenAnswer((_) async => const Right<Failure, UserEntity?>(null));

      final result = await useCase.execute(
        currentEmail: 'ghost@example.com',
        fullName: 'Ghost',
        email: 'ghost2@example.com',
        currentPassword: 'whatever',
      );

      expect(result.leftOrNull, isA<NotFoundFailure>());
      verifyNever(
        () => repository.updateUserProfile(
          currentEmail: any(named: 'currentEmail'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          photo: any(named: 'photo'),
        ),
      );
    });
  });

  test('propagates repository failures such as a duplicate email', () async {
    when(
      () => repository.updateUserProfile(
        currentEmail: any(named: 'currentEmail'),
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        photo: any(named: 'photo'),
      ),
    ).thenAnswer(
      (_) async => const Left<Failure, UserEntity>(
        ConflictFailure('That email address is already in use.'),
      ),
    );
    when(() => repository.findUserByEmail('ada@example.com'))
        .thenAnswer((_) async => Right(storedUser()));

    final result = await useCase.execute(
      currentEmail: 'ada@example.com',
      fullName: 'Ada Lovelace',
      email: 'taken@example.com',
      currentPassword: 'Secret123!',
    );

    expect(result.leftOrNull, isA<ConflictFailure>());
  });
}
