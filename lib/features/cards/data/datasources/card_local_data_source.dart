import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/card_model.dart';

abstract class CardLocalDataSource {
  Future<CardModel> insertCard(CardModel card);
  Future<List<CardModel>> getActiveCards();
  Future<CardModel?> getCardById(String id);
}

class CardLocalDataSourceImpl implements CardLocalDataSource {
  final DatabaseHelper databaseHelper;

  CardLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<CardModel> insertCard(CardModel card) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableCards,
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return card;
  }

  @override
  Future<List<CardModel>> getActiveCards() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCards,
      where: '${DatabaseHelper.columnIsArchived} = ?',
      whereArgs: [0],
      orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
    );
    return maps.map((map) => CardModel.fromMap(map)).toList();
  }

  @override
  Future<CardModel?> getCardById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCards,
      where: '${DatabaseHelper.columnCardId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CardModel.fromMap(maps.first);
    }
    return null;
  }
}
