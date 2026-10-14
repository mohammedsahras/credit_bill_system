import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/repositories/card_repository.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';

class MockCardRepository extends Mock implements CardRepository {}

void main() {
  late AddCardUseCase useCase;
  late MockCardRepository mockRepository;

  final testDate = DateTime.parse('2026-10-13T10:00:00Z');

  final validCard = CardEntity(
    id: 'test-1',
    bankName: 'HDFC',
    nickname: 'Millennia',
    lastFour: '4821',
    network: 'Visa',
    totalLimit: 100000.0,
    billingDay: 15,
    dueDay: 5,
    createdAt: testDate,
  );

  setUpAll(() {
    registerFallbackValue(
      CardEntity(
        id: 'dummy',
        bankName: 'dummy',
        nickname: 'dummy',
        lastFour: '0000',
        network: 'Visa',
        totalLimit: 1000,
        billingDay: 1,
        dueDay: 1,
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockCardRepository();
    useCase = AddCardUseCase(mockRepository);
  });

  group('AddCardUseCase', () {
    test('returns Right(CardEntity) when card details are valid', () async {
      when(() => mockRepository.addCard(validCard))
          .thenAnswer((_) async => Right(validCard));

      final result = await useCase.execute(validCard);

      expect(result.isRight, true);
      expect(result.rightOrNull, equals(validCard));
      verify(() => mockRepository.addCard(validCard)).called(1);
    });

    test('returns Left(ValidationFailure) when bank name is empty', () async {
      final invalidCard = CardEntity(
        id: 'test-1',
        bankName: '  ',
        nickname: 'Millennia',
        lastFour: '4821',
        network: 'Visa',
        totalLimit: 100000.0,
        billingDay: 15,
        dueDay: 5,
        createdAt: testDate,
      );

      final result = await useCase.execute(invalidCard);

      expect(result.isLeft, true);
      expect(result.leftOrNull, isA<ValidationFailure>());
      verifyNever(() => mockRepository.addCard(any()));
    });

    test(
      'returns Left(ValidationFailure) when last 4 digits are not 4 digits',
      () async {
        final invalidCard = CardEntity(
          id: 'test-1',
          bankName: 'HDFC',
          nickname: 'Millennia',
          lastFour: '482', // only 3 digits
          network: 'Visa',
          totalLimit: 100000.0,
          billingDay: 15,
          dueDay: 5,
          createdAt: testDate,
        );

        final result = await useCase.execute(invalidCard);

        expect(result.isLeft, true);
        expect(result.leftOrNull, isA<ValidationFailure>());
        expect(result.leftOrNull?.message, 'Must be exactly 4 digits');
        verifyNever(() => mockRepository.addCard(any()));
      },
    );

    test(
      'returns Left(ValidationFailure) when total credit limit <= 0',
      () async {
        final invalidCard = CardEntity(
          id: 'test-1',
          bankName: 'HDFC',
          nickname: 'Millennia',
          lastFour: '4821',
          network: 'Visa',
          totalLimit: 0.0,
          billingDay: 15,
          dueDay: 5,
          createdAt: testDate,
        );

        final result = await useCase.execute(invalidCard);

        expect(result.isLeft, true);
        expect(result.leftOrNull, isA<ValidationFailure>());
        expect(
          result.leftOrNull?.message,
          'Credit limit must be greater than zero',
        );
        verifyNever(() => mockRepository.addCard(any()));
      },
    );

    test('rejects non-finite credit limits', () async {
      final invalidCard = CardEntity(
        id: 'test-1',
        bankName: 'HDFC',
        nickname: 'Millennia',
        lastFour: '4821',
        network: 'Visa',
        totalLimit: double.infinity,
        billingDay: 15,
        dueDay: 5,
        createdAt: testDate,
      );

      final result = await useCase.execute(invalidCard);

      expect(result.isLeft, true);
      expect(result.leftOrNull, isA<ValidationFailure>());
      verifyNever(() => mockRepository.addCard(any()));
    });

    test('returns Left(ValidationFailure) when billing day is out of bounds (1-31)', () async {
      final invalidCard = CardEntity(
        id: 'test-1',
        bankName: 'HDFC',
        nickname: 'Millennia',
        lastFour: '4821',
        network: 'Visa',
        totalLimit: 100000.0,
        billingDay: 32,
        dueDay: 5,
        createdAt: testDate,
      );

      final result = await useCase.execute(invalidCard);

      expect(result.isLeft, true);
      expect(result.leftOrNull, isA<ValidationFailure>());
      expect(result.leftOrNull?.message, 'Day must be between 1 and 31');
      verifyNever(() => mockRepository.addCard(any()));
    });

    test(
      'returns Left(ValidationFailure) when due day is out of bounds (1-31)',
      () async {
        final invalidCard = CardEntity(
          id: 'test-1',
          bankName: 'HDFC',
          nickname: 'Millennia',
          lastFour: '4821',
          network: 'Visa',
          totalLimit: 100000.0,
          billingDay: 15,
          dueDay: 0,
          createdAt: testDate,
        );

        final result = await useCase.execute(invalidCard);

        expect(result.isLeft, true);
        expect(result.leftOrNull, isA<ValidationFailure>());
        verifyNever(() => mockRepository.addCard(any()));
      },
    );
  });
}
