import '../../../../core/database/database_helper.dart';
import '../../domain/entities/bill_entity.dart';
import '../models/bill_model.dart';

enum BillSaveOutcomeType { saved, cardUnavailable, paymentAlreadyRecorded }

class BillSaveOutcome {
  final BillSaveOutcomeType type;
  final BillModel? bill;

  const BillSaveOutcome(this.type, [this.bill]);
}

abstract class BillLocalDataSource {
  Future<BillSaveOutcome> saveUnpaidBill(BillModel bill);
  Future<List<BillModel>> getActiveBills();
}

class BillLocalDataSourceImpl implements BillLocalDataSource {
  final DatabaseHelper databaseHelper;

  const BillLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<BillSaveOutcome> saveUnpaidBill(BillModel bill) async {
    final db = await databaseHelper.database;
    return db.transaction((transaction) async {
      final activeCards = await transaction.query(
        DatabaseHelper.tableCards,
        columns: [DatabaseHelper.columnCardId],
        where:
            '${DatabaseHelper.columnCardId} = ? AND ${DatabaseHelper.columnIsArchived} = ?',
        whereArgs: [bill.cardId, 0],
        limit: 1,
      );
      if (activeCards.isEmpty) {
        return const BillSaveOutcome(BillSaveOutcomeType.cardUnavailable);
      }

      final existingRows = await transaction.query(
        DatabaseHelper.tableBills,
        where:
            '${DatabaseHelper.columnBillCardId} = ? AND ${DatabaseHelper.columnCycleMonth} = ?',
        whereArgs: [bill.cardId, bill.cycleMonth],
        limit: 1,
      );
      if (existingRows.isNotEmpty) {
        final existing = BillModel.fromMap(existingRows.single);
        if (existing.amountPaid > 0 || existing.status != BillStatus.unpaid) {
          return const BillSaveOutcome(
            BillSaveOutcomeType.paymentAlreadyRecorded,
          );
        }
        final updated = BillModel(
          id: existing.id,
          cardId: bill.cardId,
          cycleMonth: bill.cycleMonth,
          statementDate: bill.statementDate,
          dueDate: bill.dueDate,
          totalAmountDue: bill.totalAmountDue,
          minimumAmountDue: bill.minimumAmountDue,
          amountPaid: existing.amountPaid,
          status: existing.status,
          updatedAt: bill.updatedAt,
        );
        final changed = await transaction.update(
          DatabaseHelper.tableBills,
          updated.toMap()..remove(DatabaseHelper.columnBillId),
          where:
              '${DatabaseHelper.columnBillId} = ? AND ${DatabaseHelper.columnBillStatus} = ? AND ${DatabaseHelper.columnAmountPaid} = ?',
          whereArgs: [existing.id, BillStatus.unpaid.name, 0],
        );
        if (changed != 1) {
          return const BillSaveOutcome(
            BillSaveOutcomeType.paymentAlreadyRecorded,
          );
        }
        return BillSaveOutcome(BillSaveOutcomeType.saved, updated);
      }

      await transaction.insert(DatabaseHelper.tableBills, bill.toMap());
      return BillSaveOutcome(BillSaveOutcomeType.saved, bill);
    });
  }

  @override
  Future<List<BillModel>> getActiveBills() async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT bills.*
      FROM ${DatabaseHelper.tableBills} AS bills
      INNER JOIN ${DatabaseHelper.tableCards} AS cards
        ON cards.${DatabaseHelper.columnCardId} = bills.${DatabaseHelper.columnBillCardId}
      WHERE cards.${DatabaseHelper.columnIsArchived} = ?
      ORDER BY bills.${DatabaseHelper.columnBillDueDate} ASC
      ''',
      [0],
    );
    return rows.map(BillModel.fromMap).toList();
  }
}
