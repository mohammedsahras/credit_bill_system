import 'package:credit_bill_system/core/database/database_helper.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/cards/data/datasources/card_local_data_source.dart';
import 'package:credit_bill_system/features/cards/data/repositories/card_repository_impl.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/archive_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/delete_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/get_cards_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/update_card_usecase.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_bloc.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_event.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseHelper = DatabaseHelper();
  });

  setUp(() async {
    await databaseHelper.close();
    final databasePath = p.join(
      await getDatabasesPath(),
      'credit_bill_system.db',
    );
    await deleteDatabase(databasePath);
  });

  tearDownAll(() async {
    await databaseHelper.close();
  });

  test('valid card is emitted and persisted to SQLite', () async {
    final repository = CardRepositoryImpl(
      localDataSource: CardLocalDataSourceImpl(databaseHelper: databaseHelper),
    );
    final bloc = CardBloc(
      getCardsUseCase: GetCardsUseCase(repository),
      addCardUseCase: AddCardUseCase(repository),
      updateCardUseCase: UpdateCardUseCase(repository),
      archiveCardUseCase: ArchiveCardUseCase(repository),
      deleteCardUseCase: DeleteCardUseCase(repository),
    );
    addTearDown(bloc.close);
    final statesFuture = bloc.stream.take(4).toList();
    final card = CardEntity(
      id: '550e8400-e29b-41d4-a716-446655440000',
      bankName: 'HDFC',
      nickname: 'Millennia',
      lastFour: '4821',
      network: 'Visa',
      totalLimit: 150000,
      billingDay: 12,
      dueDay: 2,
      colorGradientIdx: 3,
      createdAt: DateTime.utc(2026, 10, 14),
    );

    bloc.add(AddCardEvent(card));
    final states = await statesFuture;

    expect(states.map((state) => state.runtimeType), [
      CardLoadingState,
      CardAddedSuccessState,
      CardLoadingState,
      CardLoadedState,
    ]);
    expect((states[1] as CardAddedSuccessState).card.id, card.id);
    expect((states[3] as CardLoadedState).cards.single.id, card.id);
    expect((states[3] as CardLoadedState).cards.single.colorGradientIdx, 3);

    final database = await databaseHelper.database;
    final cards = await database.query(DatabaseHelper.tableCards);
    expect(cards, hasLength(1));
    expect(cards.single[DatabaseHelper.columnCardId], card.id);
    expect(cards.single[DatabaseHelper.columnLastFour], '4821');
    expect(cards.single[DatabaseHelper.columnColorGradientIdx], 3);
    expect(
      (cards.single[DatabaseHelper.columnTotalLimit] as num).toDouble(),
      150000,
    );
  });

  test(
    'editing updates only allowed fields on the existing active row',
    () async {
      final repository = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      final original = CardEntity(
        id: 'card-edit',
        bankName: 'HDFC',
        nickname: 'Millennia',
        lastFour: '4821',
        network: 'Visa',
        totalLimit: 150000,
        billingDay: 12,
        dueDay: 2,
        colorGradientIdx: 1,
        createdAt: DateTime.utc(2026, 10, 14),
      );
      await repository.addCard(original);

      final edit = CardEntity(
        id: original.id,
        bankName: original.bankName,
        nickname: original.nickname,
        lastFour: original.lastFour,
        network: original.network,
        totalLimit: 175000,
        billingDay: 15,
        dueDay: 5,
        colorGradientIdx: 4,
        createdAt: original.createdAt,
      );
      final result = await UpdateCardUseCase(repository).execute(edit);

      expect(result.isRight, isTrue);
      final stored = await repository.getCardById(original.id);
      final savedCard = stored.rightOrNull!;
      expect(savedCard.totalLimit, 175000);
      expect(savedCard.billingDay, 15);
      expect(savedCard.dueDay, 5);
      expect(savedCard.colorGradientIdx, 4);
      expect(savedCard.id, original.id);
      expect(savedCard.bankName, original.bankName);
      expect(savedCard.nickname, original.nickname);
      expect(savedCard.lastFour, original.lastFour);
      expect(savedCard.network, original.network);
      expect(savedCard.createdAt, original.createdAt);
    },
  );

  test(
    'edit validation rejects invalid limits, days, and gradient indices',
    () async {
      final repository = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      final original = CardEntity(
        id: 'card-invalid-edit',
        bankName: 'HDFC',
        nickname: 'Millennia',
        lastFour: '4821',
        network: 'Visa',
        totalLimit: 150000,
        billingDay: 12,
        dueDay: 2,
        createdAt: DateTime.utc(2026, 10, 14),
      );
      await repository.addCard(original);
      final useCase = UpdateCardUseCase(repository);

      final invalidEdits = [
        CardEntity(
          id: original.id,
          bankName: original.bankName,
          nickname: original.nickname,
          lastFour: original.lastFour,
          network: original.network,
          totalLimit: double.infinity,
          billingDay: original.billingDay,
          dueDay: original.dueDay,
          colorGradientIdx: original.colorGradientIdx,
          createdAt: original.createdAt,
        ),
        CardEntity(
          id: original.id,
          bankName: original.bankName,
          nickname: original.nickname,
          lastFour: original.lastFour,
          network: original.network,
          totalLimit: original.totalLimit,
          billingDay: 32,
          dueDay: original.dueDay,
          colorGradientIdx: original.colorGradientIdx,
          createdAt: original.createdAt,
        ),
        CardEntity(
          id: original.id,
          bankName: original.bankName,
          nickname: original.nickname,
          lastFour: original.lastFour,
          network: original.network,
          totalLimit: original.totalLimit,
          billingDay: original.billingDay,
          dueDay: original.dueDay,
          colorGradientIdx: 99,
          createdAt: original.createdAt,
        ),
      ];

      for (final edit in invalidEdits) {
        final result = await useCase.execute(edit);
        expect(result.leftOrNull, isA<ValidationFailure>());
      }
      expect(
        (await repository.getCardById(original.id)).rightOrNull!.totalLimit,
        original.totalLimit,
      );
    },
  );

  test(
    'archive retains the card row and excludes it from active results',
    () async {
      final repository = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      final card = CardEntity(
        id: 'card-archive',
        bankName: 'ICICI',
        nickname: 'Amazon Pay',
        lastFour: '1234',
        network: 'Visa',
        totalLimit: 50000,
        billingDay: 20,
        dueDay: 10,
        createdAt: DateTime.utc(2026, 10, 14),
      );
      await repository.addCard(card);

      final result = await ArchiveCardUseCase(repository).execute(card.id);

      expect(result.rightOrNull, isTrue);
      expect((await repository.getActiveCards()).rightOrNull, isEmpty);
      final archived = (await repository.getCardById(card.id)).rightOrNull!;
      expect(archived.isArchived, isTrue);
      expect(archived.id, card.id);
    },
  );

  test(
    'delete removes an active row and archived or missing rows are not found',
    () async {
      final repository = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      final card = CardEntity(
        id: 'card-delete',
        bankName: 'ICICI',
        nickname: 'Amazon Pay',
        lastFour: '1234',
        network: 'Visa',
        totalLimit: 50000,
        billingDay: 20,
        dueDay: 10,
        createdAt: DateTime.utc(2026, 10, 14),
      );
      await repository.addCard(card);

      final deleted = await DeleteCardUseCase(repository).execute(card.id);
      expect(deleted.rightOrNull, isTrue);
      expect((await repository.getCardById(card.id)).rightOrNull, isNull);

      await repository.addCard(card);
      await ArchiveCardUseCase(repository).execute(card.id);
      expect(
        (await repository.archiveActiveCard(card.id)).leftOrNull,
        isA<NotFoundFailure>(),
      );
      expect(
        (await repository.archiveActiveCard('missing-card')).leftOrNull,
        isA<NotFoundFailure>(),
      );
      expect(
        (await repository.deleteActiveCard(card.id)).leftOrNull,
        isA<NotFoundFailure>(),
      );
      expect(
        (await repository.updateActiveCard(card)).leftOrNull,
        isA<NotFoundFailure>(),
      );
      expect(
        (await repository.deleteActiveCard('missing-card')).leftOrNull,
        isA<NotFoundFailure>(),
      );
      expect(
        (await repository.updateActiveCard(
          CardEntity(
            id: 'missing-card',
            bankName: card.bankName,
            nickname: card.nickname,
            lastFour: card.lastFour,
            network: card.network,
            totalLimit: card.totalLimit,
            billingDay: card.billingDay,
            dueDay: card.dueDay,
            createdAt: card.createdAt,
          ),
        )).leftOrNull,
        isA<NotFoundFailure>(),
      );
    },
  );

  test(
    'cards table enforces constraints and excludes sensitive fields',
    () async {
      final database = await databaseHelper.database;

      final foreignKeys = await database.rawQuery('PRAGMA foreign_keys;');
      expect(foreignKeys.single.values.single, 1);

      final columns = await database.rawQuery(
        'PRAGMA table_info(${DatabaseHelper.tableCards});',
      );
      final columnNames = columns.map((column) => column['name']).toSet();
      expect(
        columnNames.intersection({
          'cvv',
          'cvc',
          'pan',
          'card_number',
          'expiry',
        }),
        isEmpty,
      );

      await expectLater(
        database.insert(DatabaseHelper.tableCards, {
          DatabaseHelper.columnCardId: 'invalid-last-four',
          DatabaseHelper.columnBankName: 'HDFC',
          DatabaseHelper.columnNickname: 'Invalid',
          DatabaseHelper.columnLastFour: '482',
          DatabaseHelper.columnNetwork: 'Visa',
          DatabaseHelper.columnTotalLimit: 150000,
          DatabaseHelper.columnBillingDay: 12,
          DatabaseHelper.columnDueDay: 2,
          DatabaseHelper.columnCreatedAt: DateTime.now()
              .toUtc()
              .toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );
}
