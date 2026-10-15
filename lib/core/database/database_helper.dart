import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'credit_bill_system.db';
  static const int _databaseVersion = 2;

  static const String tableCards = 'cards';
  static const String tableBills = 'bills';
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBillsTable(db);
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

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
