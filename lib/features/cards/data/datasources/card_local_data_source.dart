import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/card_model.dart';

abstract class CardLocalDataSource {
  Future<CardModel> insertCard(CardModel card);
  Future<List<CardModel>> getActiveCards();
  Future<CardModel?> getCardById(String id);
  Future<int> updateActiveCard(CardModel card);
  Future<int> archiveActiveCard(String id);
  Future<int> deleteActiveCard(String id);
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

  @override
  Future<int> updateActiveCard(CardModel card) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableCards,
      {
        DatabaseHelper.columnTotalLimit: card.totalLimit,
        DatabaseHelper.columnBillingDay: card.billingDay,
        DatabaseHelper.columnDueDay: card.dueDay,
        DatabaseHelper.columnColorGradientIdx: card.colorGradientIdx,
      },
      where:
          '${DatabaseHelper.columnCardId} = ? AND ${DatabaseHelper.columnIsArchived} = ?',
      whereArgs: [card.id, 0],
    );
  }

  @override
  Future<int> archiveActiveCard(String id) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableCards,
      {DatabaseHelper.columnIsArchived: 1},
      where:
          '${DatabaseHelper.columnCardId} = ? AND ${DatabaseHelper.columnIsArchived} = ?',
      whereArgs: [id, 0],
    );
  }

  @override
  Future<int> deleteActiveCard(String id) async {
    final db = await databaseHelper.database;
    return db.delete(
      DatabaseHelper.tableCards,
      where:
          '${DatabaseHelper.columnCardId} = ? AND ${DatabaseHelper.columnIsArchived} = ?',
      whereArgs: [id, 0],
    );
  }
}
