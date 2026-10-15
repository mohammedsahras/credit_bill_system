import 'package:credit_bill_system/core/database/database_helper.dart';
import 'package:credit_bill_system/features/bills/data/datasources/bill_local_data_source.dart';
import 'package:credit_bill_system/features/bills/data/models/bill_model.dart';
import 'package:credit_bill_system/features/bills/domain/entities/bill_entity.dart';
import 'package:credit_bill_system/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:credit_bill_system/features/bills/domain/usecases/get_active_bills_usecase.dart';
import 'package:credit_bill_system/features/bills/domain/usecases/save_bill_usecase.dart';
import 'package:credit_bill_system/features/cards/data/datasources/card_local_data_source.dart';
import 'package:credit_bill_system/features/cards/data/repositories/card_repository_impl.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late BillLocalDataSourceImpl billDataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseHelper = DatabaseHelper();
    billDataSource = BillLocalDataSourceImpl(databaseHelper: databaseHelper);
  });

  setUp(() async {
    await databaseHelper.close();
    await deleteDatabase(
      p.join(await getDatabasesPath(), 'credit_bill_system.db'),
    );
  });

  tearDownAll(() async {
    await databaseHelper.close();
  });

  test('v1 migration preserves cards and creates bill storage', () async {
    final path = p.join(await getDatabasesPath(), 'credit_bill_system.db');
    final v1 = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cards (
            id TEXT PRIMARY KEY,
            bank_name TEXT NOT NULL,
            nickname TEXT NOT NULL,
            last_four TEXT NOT NULL,
            network TEXT NOT NULL,
            total_limit REAL NOT NULL,
            billing_day INTEGER NOT NULL,
            due_day INTEGER NOT NULL,
            color_gradient_idx INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.insert('cards', {
          'id': 'legacy-card',
          'bank_name': 'HDFC',
          'nickname': 'Legacy',
          'last_four': '4321',
          'network': 'Visa',
          'total_limit': 25000,
          'billing_day': 12,
          'due_day': 2,
          'color_gradient_idx': 1,
          'is_archived': 0,
          'created_at': '2025-01-01T00:00:00.000Z',
        });
      },
    );
    await v1.close();

    final upgraded = await databaseHelper.database;
    final cardRows = await upgraded.query(DatabaseHelper.tableCards);
    final billTables = await upgraded.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'bills'",
    );
    expect(cardRows, hasLength(1));
    expect(cardRows.single['id'], 'legacy-card');
    expect(billTables, hasLength(1));
    final saved = await billDataSource.saveUnpaidBill(
      BillModel.fromEntity(_bill('legacy-bill', 'legacy-card')),
    );
    final migratedBills = await billDataSource.getActiveBills();
    expect(saved.type, BillSaveOutcomeType.saved);
    expect(migratedBills, hasLength(1));
    expect(migratedBills.single.id, 'legacy-bill');
  });

  test(
    'saves one bill per card cycle and updates the same unpaid row',
    () async {
      final cards = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      await cards.addCard(_card('card-upsert'));
      final first = _bill('bill-first', 'card-upsert');
      final created = await billDataSource.saveUnpaidBill(
        BillModel.fromEntity(first),
      );
      final replacement = _bill(
        'bill-replacement-id',
        'card-upsert',
        total: 1250.75,
        dueDate: DateTime(2026, 11, 8),
      );
      final updated = await billDataSource.saveUnpaidBill(
        BillModel.fromEntity(replacement),
      );

      expect(created.type, BillSaveOutcomeType.saved);
      expect(updated.bill!.id, first.id);
      expect(updated.bill!.totalAmountDue, 1250.75);
      final rows = await (await databaseHelper.database).query(
        DatabaseHelper.tableBills,
      );
      expect(rows, hasLength(1));
      expect(rows.single['id'], first.id);
      expect(rows.single['cycle_month'], '2026-10');
    },
  );

  test(
    'bill use cases persist and reload through repositories in SQLite',
    () async {
      final cardRepository = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      await cardRepository.addCard(_card('card-use-case'));
      final billRepository = BillRepositoryImpl(
        localDataSource: billDataSource,
      );
      final saveBill = SaveBillUseCase(
        billRepository: billRepository,
        cardRepository: cardRepository,
      );

      final saved = await saveBill.execute(
        cardId: 'card-use-case',
        statementDate: DateTime(2026, 10, 12),
        dueDate: DateTime(2026, 11, 2),
        totalAmountDue: 1250,
        minimumAmountDue: 100,
      );
      final loaded = await GetActiveBillsUseCase(billRepository).execute();

      expect(saved.rightOrNull?.cycleMonth, '2026-10');
      expect(loaded.rightOrNull, hasLength(1));
      expect(loaded.rightOrNull!.single.totalAmountDue, 1250);
    },
  );

  test('rejects missing or archived cards without creating bills', () async {
    final cards = CardRepositoryImpl(
      localDataSource: CardLocalDataSourceImpl(databaseHelper: databaseHelper),
    );
    await cards.addCard(_card('card-archived'));
    await billDataSource.saveUnpaidBill(
      BillModel.fromEntity(_bill('archived-bill', 'card-archived')),
    );
    await cards.archiveActiveCard('card-archived');

    final archivedUpdate = await billDataSource.saveUnpaidBill(
      BillModel.fromEntity(_bill('replacement', 'card-archived')),
    );
    final missing = await billDataSource.saveUnpaidBill(
      BillModel.fromEntity(_bill('missing-bill', 'missing-card')),
    );
    final rows = await (await databaseHelper.database).query(
      DatabaseHelper.tableBills,
    );

    expect(archivedUpdate.type, BillSaveOutcomeType.cardUnavailable);
    expect(missing.type, BillSaveOutcomeType.cardUnavailable);
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'archived-bill');
    expect(await billDataSource.getActiveBills(), isEmpty);
  });

  test(
    'rejects edits after partial payment without changing bill history',
    () async {
      final cards = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      await cards.addCard(_card('card-paid'));
      await billDataSource.saveUnpaidBill(
        BillModel.fromEntity(_bill('bill-paid', 'card-paid')),
      );
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableBills,
        {
          DatabaseHelper.columnAmountPaid: 100,
          DatabaseHelper.columnBillStatus: 'partially_paid',
        },
        where: '${DatabaseHelper.columnBillId} = ?',
        whereArgs: ['bill-paid'],
      );
      final before = (await db.query(DatabaseHelper.tableBills)).single;
      final result = await billDataSource.saveUnpaidBill(
        BillModel.fromEntity(_bill('replacement', 'card-paid', total: 1400)),
      );
      final after = (await db.query(DatabaseHelper.tableBills)).single;

      expect(result.type, BillSaveOutcomeType.paymentAlreadyRecorded);
      expect(after, before);
    },
  );

  test(
    'rejects edits after full payment without changing bill history',
    () async {
      final cards = CardRepositoryImpl(
        localDataSource: CardLocalDataSourceImpl(
          databaseHelper: databaseHelper,
        ),
      );
      await cards.addCard(_card('card-fully-paid'));
      await billDataSource.saveUnpaidBill(
        BillModel.fromEntity(_bill('bill-fully-paid', 'card-fully-paid')),
      );
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableBills,
        {
          DatabaseHelper.columnAmountPaid: 1000,
          DatabaseHelper.columnBillStatus: 'paid',
        },
        where: '${DatabaseHelper.columnBillId} = ?',
        whereArgs: ['bill-fully-paid'],
      );
      final before = (await db.query(DatabaseHelper.tableBills)).single;
      final result = await billDataSource.saveUnpaidBill(
        BillModel.fromEntity(
          _bill('replacement-paid', 'card-fully-paid', total: 1400),
        ),
      );
      final after = (await db.query(DatabaseHelper.tableBills)).single;

      expect(result.type, BillSaveOutcomeType.paymentAlreadyRecorded);
      expect(after, before);
    },
  );

  test('bill rows cascade on permanent card deletion', () async {
    final cards = CardRepositoryImpl(
      localDataSource: CardLocalDataSourceImpl(databaseHelper: databaseHelper),
    );
    await cards.addCard(_card('card-delete'));
    await billDataSource.saveUnpaidBill(
      BillModel.fromEntity(_bill('bill-delete', 'card-delete')),
    );

    await cards.deleteActiveCard('card-delete');

    final rows = await (await databaseHelper.database).query(
      DatabaseHelper.tableBills,
    );
    expect(rows, isEmpty);
  });

  test('SQLite stores partially paid status in the specified format', () async {
    final model = BillModel.fromEntity(
      _bill('partial-bill', 'card-partial').copyWithPartialStatus(),
    );
    expect(model.toMap()['status'], 'partially_paid');
    expect(BillModel.fromMap(model.toMap()).status, BillStatus.partiallyPaid);
  });
}

CardEntity _card(String id) => CardEntity(
  id: id,
  bankName: 'HDFC',
  nickname: 'Millennia',
  lastFour: '4821',
  network: 'Visa',
  totalLimit: 150000,
  billingDay: 12,
  dueDay: 2,
  createdAt: DateTime.utc(2026, 10, 14),
);

BillEntity _bill(
  String id,
  String cardId, {
  double total = 1000,
  DateTime? dueDate,
}) => BillEntity(
  id: id,
  cardId: cardId,
  cycleMonth: '2026-10',
  statementDate: DateTime(2026, 10, 12),
  dueDate: dueDate ?? DateTime(2026, 11, 2),
  totalAmountDue: total,
  minimumAmountDue: 100,
  amountPaid: 0,
  status: BillStatus.unpaid,
  updatedAt: DateTime.utc(2026, 10, 14),
);

extension on BillEntity {
  BillEntity copyWithPartialStatus() => BillEntity(
    id: id,
    cardId: cardId,
    cycleMonth: cycleMonth,
    statementDate: statementDate,
    dueDate: dueDate,
    totalAmountDue: totalAmountDue,
    minimumAmountDue: minimumAmountDue,
    amountPaid: 100,
    status: BillStatus.partiallyPaid,
    updatedAt: updatedAt,
  );
}
