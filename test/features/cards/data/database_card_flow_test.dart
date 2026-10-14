import 'package:credit_bill_system/core/database/database_helper.dart';
import 'package:credit_bill_system/features/cards/data/datasources/card_local_data_source.dart';
import 'package:credit_bill_system/features/cards/data/repositories/card_repository_impl.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/get_cards_usecase.dart';
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

    final database = await databaseHelper.database;
    final cards = await database.query(DatabaseHelper.tableCards);
    expect(cards, hasLength(1));
    expect(cards.single[DatabaseHelper.columnCardId], card.id);
    expect(cards.single[DatabaseHelper.columnLastFour], '4821');
    expect(
      (cards.single[DatabaseHelper.columnTotalLimit] as num).toDouble(),
      150000,
    );
  });

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
