import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'credit_bill_system.db';
  static const int _databaseVersion = 1;

  static const String tableCards = 'cards';
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
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
