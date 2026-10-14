import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/cards/data/datasources/card_local_data_source.dart';
import 'package:credit_bill_system/features/cards/data/models/card_model.dart';
import 'package:credit_bill_system/features/cards/data/repositories/card_repository_impl.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCardLocalDataSource extends Mock implements CardLocalDataSource {}

void main() {
  late _MockCardLocalDataSource localDataSource;
  late CardRepositoryImpl repository;

  final card = CardEntity(
    id: 'card-1',
    bankName: 'Sample Bank',
    nickname: 'Everyday',
    lastFour: '4821',
    network: 'Visa',
    totalLimit: 150000,
    billingDay: 12,
    dueDay: 2,
    createdAt: DateTime.utc(2026, 10, 14),
  );

  setUpAll(() {
    registerFallbackValue(CardModel.fromEntity(card));
  });

  setUp(() {
    localDataSource = _MockCardLocalDataSource();
    repository = CardRepositoryImpl(localDataSource: localDataSource);
  });

  test('maps update exceptions to database failures', () async {
    when(() => localDataSource.updateActiveCard(any()))
        .thenThrow(Exception('database unavailable'));

    expect(
      (await repository.updateActiveCard(card)).leftOrNull,
      isA<DatabaseFailure>(),
    );
  });

  test('maps archive exceptions to database failures', () async {
    when(() => localDataSource.archiveActiveCard(card.id))
        .thenThrow(Exception('database unavailable'));

    expect(
      (await repository.archiveActiveCard(card.id)).leftOrNull,
      isA<DatabaseFailure>(),
    );
  });

  test('maps delete exceptions to database failures', () async {
    when(() => localDataSource.deleteActiveCard(card.id))
        .thenThrow(Exception('database unavailable'));

    expect(
      (await repository.deleteActiveCard(card.id)).leftOrNull,
      isA<DatabaseFailure>(),
    );
  });
}
