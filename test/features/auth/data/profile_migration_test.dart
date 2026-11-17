import 'package:credit_bill_system/core/database/database_helper.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/core/utils/password_hasher.dart';
import 'package:credit_bill_system/features/auth/data/datasources/user_local_data_source.dart';
import 'package:credit_bill_system/features/auth/data/models/user_model.dart';
import 'package:credit_bill_system/features/auth/data/repositories/user_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// v5 schema (everything that existed before the profile columns), used to
/// prove the v6 upgrade is strictly additive.
Future<void> createV5Schema(Database db) async {
  await db.execute('''
    CREATE TABLE cards (
      id TEXT PRIMARY KEY,
      bank_name TEXT NOT NULL,
      nickname TEXT NOT NULL,
      last_four TEXT NOT NULL
        CHECK(last_four GLOB '[0-9][0-9][0-9][0-9]'),
      network TEXT NOT NULL,
      total_limit REAL NOT NULL CHECK(total_limit > 0),
      billing_day INTEGER NOT NULL CHECK(billing_day BETWEEN 1 AND 31),
      due_day INTEGER NOT NULL CHECK(due_day BETWEEN 1 AND 31),
      color_gradient_idx INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_cards_archived ON cards(is_archived)',
  );
  await db.execute('''
    CREATE TABLE bills (
      id TEXT PRIMARY KEY NOT NULL,
      card_id TEXT NOT NULL,
      cycle_month TEXT NOT NULL,
      statement_date TEXT NOT NULL,
      due_date TEXT NOT NULL,
      total_amount_due REAL NOT NULL CHECK(total_amount_due >= 0),
      minimum_amount_due REAL NOT NULL DEFAULT 0,
      amount_paid REAL NOT NULL DEFAULT 0 CHECK(amount_paid >= 0),
      status TEXT NOT NULL CHECK(status IN ('unpaid', 'partially_paid', 'paid')),
      updated_at TEXT NOT NULL,
      FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE,
      UNIQUE (card_id, cycle_month)
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_bills_card_due ON bills(card_id, due_date)',
  );
  // v5 users table: no phone / photo yet.
  await db.execute('''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      full_name TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL,
      is_email_verified INTEGER NOT NULL DEFAULT 1
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
  );
  await db.execute('''
    CREATE TABLE customers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL UNIQUE,
      address,
      created_at TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_customers_active ON customers(is_active)',
  );
  await db.execute('''
    CREATE TABLE credit_transactions (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      amount_minor INTEGER NOT NULL CHECK(amount_minor > 0),
      description,
      due_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_credit_transactions_customer '
    'ON credit_transactions(customer_id)',
  );
  await db.execute('''
    CREATE TABLE payments (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      amount_minor INTEGER NOT NULL CHECK(amount_minor > 0),
      payment_date TEXT NOT NULL,
      payment_type TEXT NOT NULL CHECK(payment_type IN ('full', 'partial')),
      created_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)',
  );
  await db.execute('''
    CREATE TABLE payment_allocations (
      id TEXT PRIMARY KEY,
      payment_id TEXT NOT NULL,
      credit_transaction_id TEXT NOT NULL,
      allocated_amount_minor INTEGER NOT NULL CHECK(allocated_amount_minor > 0),
      created_at TEXT NOT NULL,
      FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
      FOREIGN KEY (credit_transaction_id) REFERENCES credit_transactions(id)
        ON DELETE CASCADE,
      UNIQUE (payment_id, credit_transaction_id)
    )
  ''');
  await db.execute('''
    CREATE TABLE recovery_codes (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      code_hash TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      max_attempts INTEGER NOT NULL DEFAULT 5,
      used INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_recovery_email ON recovery_codes(email)',
  );
}

Future<void> seedV5Data(Database db) async {
  final now = DateTime.utc(2026, 10, 1).toIso8601String();

  await db.insert('cards', {
    'id': 'card-1',
    'bank_name': 'HDFC',
    'nickname': 'Millennia',
    'last_four': '4821',
    'network': 'Visa',
    'total_limit': 150000,
    'billing_day': 12,
    'due_day': 2,
    'color_gradient_idx': 3,
    'is_archived': 0,
    'created_at': now,
  });
  await db.insert('bills', {
    'id': 'bill-1',
    'card_id': 'card-1',
    'cycle_month': '2026-10',
    'statement_date': now,
    'due_date': now,
    'total_amount_due': 1250,
    'minimum_amount_due': 100,
    'amount_paid': 0,
    'status': 'unpaid',
    'updated_at': now,
  });
  await db.insert('users', {
    'id': 'user-bcrypt',
    'email': 'ada@example.com',
    'full_name': 'Ada Lovelace',
    'password_hash': PasswordHasher.hash('Secret123!'),
    'created_at': now,
    'is_email_verified': 1,
  });
  await db.insert('users', {
    'id': 'user-legacy',
    'email': 'legacy@example.com',
    'full_name': 'Legacy User',
    'password_hash': PasswordHasher.legacyHash('old-password'),
    'created_at': now,
    'is_email_verified': 1,
  });
  await db.insert('customers', {
    'id': 'customer-1',
    'name': 'Ravi',
    'phone': '+94 77 000 1111',
    'address': 'Colombo',
    'created_at': now,
    'is_active': 1,
  });
  await db.insert('credit_transactions', {
    'id': 'txn-1',
    'customer_id': 'customer-1',
    'amount_minor': 50000,
    'description': 'Stock',
    'due_date': now,
    'created_at': now,
  });
  await db.insert('payments', {
    'id': 'payment-1',
    'customer_id': 'customer-1',
    'amount_minor': 25000,
    'payment_date': now,
    'payment_type': 'partial',
    'created_at': now,
  });
  await db.insert('payment_allocations', {
    'id': 'alloc-1',
    'payment_id': 'payment-1',
    'credit_transaction_id': 'txn-1',
    'allocated_amount_minor': 25000,
    'created_at': now,
  });
  await db.insert('recovery_codes', {
    'id': 'recovery-1',
    'email': 'ada@example.com',
    'code_hash': 'hash',
    'expires_at': now,
    'attempts': 0,
    'max_attempts': 5,
    'used': 0,
    'created_at': now,
  });
}

void main() {
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseHelper = DatabaseHelper();
  });

  Future<String> databaseFilePath() async {
    return p.join(await getDatabasesPath(), 'credit_bill_system.db');
  }

  setUp(() async {
    await databaseHelper.close();
    await deleteDatabase(await databaseFilePath());
  });

  tearDownAll(() async {
    await databaseHelper.close();
  });

  test(
    'v5 database upgrades to v6 with additive profile columns and intact data',
    () async {
      // Build a genuine v5 database with rows in every business table.
      final path = await databaseFilePath();
      final legacyDb = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            await createV5Schema(db);
            await seedV5Data(db);
          },
        ),
      );
      expect(await legacyDb.getVersion(), 5);
      await legacyDb.close();

      // Opening through DatabaseHelper triggers the 5 -> 6 upgrade.
      final db = await databaseHelper.database;

      final version = await db.rawQuery('PRAGMA user_version;');
      expect(version.single.values.single, 6);

      // Profile columns exist, are nullable, and nothing else changed.
      final columns = await db.rawQuery('PRAGMA table_info(users);');
      final phone = columns.singleWhere((row) => row['name'] == 'phone');
      final photo = columns.singleWhere((row) => row['name'] == 'photo');
      expect(phone['notnull'], 0);
      expect(photo['notnull'], 0);
      expect(phone['type'], 'TEXT');
      expect(photo['type'], 'TEXT');

      // Every pre-existing row survived the migration untouched.
      expect(
        (await db.query('users')).map((row) => row['id']).toSet(),
        {'user-bcrypt', 'user-legacy'},
      );
      final ada = (await db.query('users', where: 'email = ?', whereArgs: [
        'ada@example.com',
      ])).single;
      expect(ada['full_name'], 'Ada Lovelace');
      expect(ada['phone'], isNull);
      expect(ada['photo'], isNull);
      expect(await db.query('cards'), hasLength(1));
      expect(await db.query('bills'), hasLength(1));
      expect(await db.query('customers'), hasLength(1));
      expect(await db.query('credit_transactions'), hasLength(1));
      expect(await db.query('payments'), hasLength(1));
      expect(await db.query('payment_allocations'), hasLength(1));
      expect(await db.query('recovery_codes'), hasLength(1));

      // Login still works for both modern (bcrypt) and legacy hashes.
      final dataSource = UserLocalDataSourceImpl(
        databaseHelper: databaseHelper,
      );
      final bcryptLogin = await dataSource.authenticateUser(
        'ada@example.com',
        'Secret123!',
      );
      expect(bcryptLogin, isNotNull);
      expect(bcryptLogin!.id, 'user-bcrypt');

      final legacyLogin = await dataSource.authenticateUser(
        'legacy@example.com',
        'old-password',
      );
      expect(legacyLogin, isNotNull);
      expect(legacyLogin!.id, 'user-legacy');

      expect(
        await dataSource.authenticateUser('ada@example.com', 'wrong'),
        isNull,
      );
    },
  );

  test('fresh install at v6 creates the profile columns too', () async {
    final db = await databaseHelper.database;
    final columns = await db.rawQuery('PRAGMA table_info(users);');
    final names = columns.map((row) => row['name']).toSet();
    expect(names, containsAll(['phone', 'photo']));
    expect(await db.getVersion(), 6);
  });

  test('updateProfile persists edits across a reopen', () async {
    final dataSource = UserLocalDataSourceImpl(
      databaseHelper: databaseHelper,
    );
    await dataSource.insertUser(
      UserModel(
        id: 'user-1',
        email: 'ada@example.com',
        fullName: 'Ada',
        passwordHash: PasswordHasher.hash('Secret123!'),
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    const resizedPhoto = 'aGVsbG8gd29ybGQ='; // "hello world"
    final updated = await dataSource.updateProfile(
      currentEmail: 'ada@example.com',
      fullName: 'Ada Lovelace',
      email: 'ada.lovelace@example.com',
      phone: '+94 77 123 4567',
      photo: resizedPhoto,
    );

    expect(updated, isNotNull);
    expect(updated!.fullName, 'Ada Lovelace');
    expect(updated.email, 'ada.lovelace@example.com');
    expect(updated.phone, '+94 77 123 4567');
    expect(updated.photo, resizedPhoto);

    // Reopen the database (fresh read) to prove the values persisted.
    await databaseHelper.close();
    final reopened = await databaseHelper.database;
    final rows = await reopened.query('users');
    expect(rows, hasLength(1));
    expect(rows.single['full_name'], 'Ada Lovelace');
    expect(rows.single['email'], 'ada.lovelace@example.com');
    expect(rows.single['phone'], '+94 77 123 4567');
    expect(rows.single['photo'], resizedPhoto);

    // Login with the untouched password still works after the edit.
    final login = await dataSource.authenticateUser(
      'ada.lovelace@example.com',
      'Secret123!',
    );
    expect(login, isNotNull);
  });

  test('updateProfile rejects a duplicate email without any partial write',
      () async {
    final dataSource = UserLocalDataSourceImpl(
      databaseHelper: databaseHelper,
    );
    await dataSource.insertUser(
      UserModel(
        id: 'user-ada',
        email: 'ada@example.com',
        fullName: 'Ada',
        passwordHash: PasswordHasher.hash('Secret123!'),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    await dataSource.insertUser(
      UserModel(
        id: 'user-grace',
        email: 'grace@example.com',
        fullName: 'Grace',
        passwordHash: PasswordHasher.hash('Secret123!'),
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await expectLater(
      dataSource.updateProfile(
        currentEmail: 'ada@example.com',
        fullName: 'Hijacked Name',
        email: 'grace@example.com',
        phone: '+1 000 000 0000',
      ),
      throwsA(isA<DuplicateEmailException>()),
    );

    // Neither account was modified by the rejected attempt.
    final ada = await dataSource.getUserByEmail('ada@example.com');
    expect(ada!.fullName, 'Ada');
    expect(ada.email, 'ada@example.com');
    expect(ada.phone, isNull);
    final grace = await dataSource.getUserByEmail('grace@example.com');
    expect(grace!.fullName, 'Grace');
    expect(grace.email, 'grace@example.com');

    // Repository surfaces the conflict as a typed Failure.
    final repository = UserRepositoryImpl(localDataSource: dataSource);
    final result = await repository.updateUserProfile(
      currentEmail: 'ada@example.com',
      fullName: 'Ada',
      email: 'grace@example.com',
    );
    expect(result.isLeft, isTrue);
    expect(result.leftOrNull, isA<ConflictFailure>());
    expect(
      (await repository.findUserByEmail('grace@example.com')).rightOrNull!.id,
      'user-grace',
    );
  });

  test('updateProfile on an unknown account reports NotFound', () async {
    final repository = UserRepositoryImpl(
      localDataSource: UserLocalDataSourceImpl(
        databaseHelper: databaseHelper,
      ),
    );
    final result = await repository.updateUserProfile(
      currentEmail: 'ghost@example.com',
      fullName: 'Ghost',
      email: 'ghost@example.com',
    );
    expect(result.leftOrNull, isA<NotFoundFailure>());
  });
}
