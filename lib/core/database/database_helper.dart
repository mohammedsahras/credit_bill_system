import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'credit_bill_system.db';
  static const int _databaseVersion = 5;

  static const String tableCards = 'cards';
  static const String tableBills = 'bills';
  static const String tableUsers = 'users';
  static const String columnUserId = 'id';
  static const String columnUserEmail = 'email';
  static const String columnUserFullName = 'full_name';
  static const String columnUserPasswordHash = 'password_hash';
  static const String columnUserCreatedAt = 'created_at';
  static const String columnUserIsEmailVerified = 'is_email_verified';

  // --- Customer tables (v4) ---
  static const String tableCustomers = 'customers';
  static const String columnCustomerId = 'id';
  static const String columnCustomerName = 'name';
  static const String columnCustomerPhone = 'phone';
  static const String columnCustomerAddress = 'address';
  static const String columnCustomerCreatedAt = 'created_at';
  static const String columnCustomerIsActive = 'is_active';

  static const String tableCreditTransactions = 'credit_transactions';
  static const String columnCreditTransactionId = 'id';
  static const String columnCreditTransactionCustomerId = 'customer_id';
  static const String columnCreditTransactionAmount = 'amount_minor';
  static const String columnCreditTransactionDescription = 'description';
  static const String columnCreditTransactionDueDate = 'due_date';
  static const String columnCreditTransactionCreatedAt = 'created_at';

  static const String tablePayments = 'payments';
  static const String columnPaymentId = 'id';
  static const String columnPaymentCustomerId = 'customer_id';
  static const String columnPaymentAmount = 'amount_minor';
  static const String columnPaymentDate = 'payment_date';
  static const String columnPaymentType = 'payment_type';
  static const String columnPaymentCreatedAt = 'created_at';

  static const String tablePaymentAllocations = 'payment_allocations';
  static const String columnAllocationId = 'id';
  static const String columnAllocationPaymentId = 'payment_id';
  static const String columnAllocationTransactionId = 'credit_transaction_id';
  static const String columnAllocationAmount = 'allocated_amount_minor';
  static const String columnAllocationCreatedAt = 'created_at';

  // --- Password recovery (v5) ---
  static const String tableRecoveryCodes = 'recovery_codes';
  static const String columnRecoveryId = 'id';
  static const String columnRecoveryEmail = 'email';
  static const String columnRecoveryCodeHash = 'code_hash';
  static const String columnRecoveryExpiresAt = 'expires_at';
  static const String columnRecoveryAttempts = 'attempts';
  static const String columnRecoveryMaxAttempts = 'max_attempts';
  static const String columnRecoveryUsed = 'used';
  static const String columnRecoveryCreatedAt = 'created_at';
  static const String columnCardId = 'id';
  static const String columnBankName = 'bank_name';
  static const String columnNickname = 'nickname';
  static const String columnLastFour = 'last_four';
  static const String columnNetwork = 'network';
  static const String columnTotalLimit = 'total_limit';
  static const String columnBillingDay = 'billing_day';
  static const String columnDueDay = 'due_day';
  static const String columnColorGradientIdx = 'color_gradient_idx';
  static const String columnIsArchived = 'is_archived';
  static const String columnCreatedAt = 'created_at';
  static const String columnBillId = 'id';
  static const String columnBillCardId = 'card_id';
  static const String columnCycleMonth = 'cycle_month';
  static const String columnStatementDate = 'statement_date';
  static const String columnBillDueDate = 'due_date';
  static const String columnTotalAmountDue = 'total_amount_due';
  static const String columnMinimumAmountDue = 'minimum_amount_due';
  static const String columnAmountPaid = 'amount_paid';
  static const String columnBillStatus = 'status';
  static const String columnBillUpdatedAt = 'updated_at';

  static DatabaseHelper? _instance;
  Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper({Database? database}) {
    if (database != null) {
      final helper = DatabaseHelper._internal();
      helper._database = database;
      return helper;
    }
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCards (
        $columnCardId TEXT PRIMARY KEY,
        $columnBankName TEXT NOT NULL,
        $columnNickname TEXT NOT NULL,
        $columnLastFour TEXT NOT NULL
          CHECK($columnLastFour GLOB '[0-9][0-9][0-9][0-9]'),
        $columnNetwork TEXT NOT NULL,
        $columnTotalLimit REAL NOT NULL CHECK($columnTotalLimit > 0),
        $columnBillingDay INTEGER NOT NULL CHECK($columnBillingDay BETWEEN 1 AND 31),
        $columnDueDay INTEGER NOT NULL CHECK($columnDueDay BETWEEN 1 AND 31),
        $columnColorGradientIdx INTEGER NOT NULL DEFAULT 0,
        $columnIsArchived INTEGER NOT NULL DEFAULT 0,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cards_archived ON $tableCards($columnIsArchived);
    ''');
    await _createBillsTable(db);
    await _createUsersTable(db);
    await _createCustomerTables(db);
    await _createRecoveryCodesTable(db);
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnUserId TEXT PRIMARY KEY,
        $columnUserEmail TEXT NOT NULL UNIQUE,
        $columnUserFullName TEXT NOT NULL,
        $columnUserPasswordHash TEXT NOT NULL,
        $columnUserCreatedAt TEXT NOT NULL,
        $columnUserIsEmailVerified INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_users_email ON $tableUsers($columnUserEmail);
    ''');
  }

  Future<void> _migrateToUsersTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableUsers],
    );
    if (tables.isEmpty) {
      await _createUsersTable(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBillsTable(db);
    }
    if (oldVersion < 3) {
      await _migrateToUsersTable(db);
    }
    if (oldVersion < 4) {
      await _migrateToCustomerTables(db);
    }
    if (oldVersion < 5) {
      await _migrateToRecoveryCodesTable(db);
    }
  }

  Future<void> _createBillsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableBills (
        $columnBillId TEXT PRIMARY KEY NOT NULL,
        $columnBillCardId TEXT NOT NULL,
        $columnCycleMonth TEXT NOT NULL
          CHECK($columnCycleMonth GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
            AND CAST(substr($columnCycleMonth, 6, 2) AS INTEGER) BETWEEN 1 AND 12),
        $columnStatementDate TEXT NOT NULL,
        $columnBillDueDate TEXT NOT NULL,
        $columnTotalAmountDue REAL NOT NULL CHECK($columnTotalAmountDue >= 0),
        $columnMinimumAmountDue REAL NOT NULL DEFAULT 0
          CHECK($columnMinimumAmountDue >= 0 AND $columnMinimumAmountDue <= $columnTotalAmountDue),
        $columnAmountPaid REAL NOT NULL DEFAULT 0 CHECK($columnAmountPaid >= 0),
        $columnBillStatus TEXT NOT NULL
          CHECK($columnBillStatus IN ('unpaid', 'partially_paid', 'paid')),
        $columnBillUpdatedAt TEXT NOT NULL,
        FOREIGN KEY ($columnBillCardId) REFERENCES $tableCards($columnCardId) ON DELETE CASCADE,
        UNIQUE ($columnBillCardId, $columnCycleMonth)
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bills_card_due
      ON $tableBills($columnBillCardId, $columnBillDueDate)
    ''');
  }

  Future<void> _createCustomerTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableCustomers (
        $columnCustomerId TEXT PRIMARY KEY,
        $columnCustomerName TEXT NOT NULL,
        $columnCustomerPhone TEXT NOT NULL UNIQUE,
        $columnCustomerAddress TEXT,
        $columnCustomerCreatedAt TEXT NOT NULL,
        $columnCustomerIsActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_customers_phone ON $tableCustomers($columnCustomerPhone);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_customers_active ON $tableCustomers($columnCustomerIsActive);
    ''');

    await db.execute('''
      CREATE TABLE $tableCreditTransactions (
        $columnCreditTransactionId TEXT PRIMARY KEY,
        $columnCreditTransactionCustomerId TEXT NOT NULL,
        $columnCreditTransactionAmount INTEGER NOT NULL CHECK($columnCreditTransactionAmount > 0),
        $columnCreditTransactionDescription TEXT,
        $columnCreditTransactionDueDate TEXT NOT NULL,
        $columnCreditTransactionCreatedAt TEXT NOT NULL,
        FOREIGN KEY ($columnCreditTransactionCustomerId) REFERENCES $tableCustomers($columnCustomerId) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_credit_transactions_customer ON $tableCreditTransactions($columnCreditTransactionCustomerId);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_credit_transactions_due ON $tableCreditTransactions($columnCreditTransactionDueDate);
    ''');

    await db.execute('''
      CREATE TABLE $tablePayments (
        $columnPaymentId TEXT PRIMARY KEY,
        $columnPaymentCustomerId TEXT NOT NULL,
        $columnPaymentAmount INTEGER NOT NULL CHECK($columnPaymentAmount > 0),
        $columnPaymentDate TEXT NOT NULL,
        $columnPaymentType TEXT NOT NULL CHECK($columnPaymentType IN ('full', 'partial')),
        $columnPaymentCreatedAt TEXT NOT NULL,
        FOREIGN KEY ($columnPaymentCustomerId) REFERENCES $tableCustomers($columnCustomerId) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payments_customer ON $tablePayments($columnPaymentCustomerId);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payments_date ON $tablePayments($columnPaymentDate);
    ''');

    await db.execute('''
      CREATE TABLE $tablePaymentAllocations (
        $columnAllocationId TEXT PRIMARY KEY,
        $columnAllocationPaymentId TEXT NOT NULL,
        $columnAllocationTransactionId TEXT NOT NULL,
        $columnAllocationAmount INTEGER NOT NULL CHECK($columnAllocationAmount > 0),
        $columnAllocationCreatedAt TEXT NOT NULL,
        FOREIGN KEY ($columnAllocationPaymentId) REFERENCES $tablePayments($columnPaymentId) ON DELETE CASCADE,
        FOREIGN KEY ($columnAllocationTransactionId) REFERENCES $tableCreditTransactions($columnCreditTransactionId) ON DELETE CASCADE,
        UNIQUE ($columnAllocationPaymentId, $columnAllocationTransactionId)
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_allocations_payment ON $tablePaymentAllocations($columnAllocationPaymentId);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_allocations_transaction ON $tablePaymentAllocations($columnAllocationTransactionId);
    ''');
  }

  Future<void> _migrateToCustomerTables(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableCustomers],
    );
    if (tables.isEmpty) {
      await _createCustomerTables(db);
    }
  }

  Future<void> _createRecoveryCodesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableRecoveryCodes (
        $columnRecoveryId TEXT PRIMARY KEY,
        $columnRecoveryEmail TEXT NOT NULL,
        $columnRecoveryCodeHash TEXT NOT NULL,
        $columnRecoveryExpiresAt TEXT NOT NULL,
        $columnRecoveryAttempts INTEGER NOT NULL DEFAULT 0,
        $columnRecoveryMaxAttempts INTEGER NOT NULL DEFAULT 5,
        $columnRecoveryUsed INTEGER NOT NULL DEFAULT 0,
        $columnRecoveryCreatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recovery_email ON $tableRecoveryCodes($columnRecoveryEmail);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recovery_expires ON $tableRecoveryCodes($columnRecoveryExpiresAt);
    ''');
  }

  Future<void> _migrateToRecoveryCodesTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableRecoveryCodes],
    );
    if (tables.isEmpty) {
      await _createRecoveryCodesTable(db);
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
