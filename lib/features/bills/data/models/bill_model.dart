import '../../domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.cardId,
    required super.cycleMonth,
    required super.statementDate,
    required super.dueDate,
    required super.totalAmountDue,
    required super.minimumAmountDue,
    required super.amountPaid,
    required super.status,
    required super.updatedAt,
  });

  factory BillModel.fromMap(Map<String, Object?> map) {
    return BillModel(
      id: map['id'] as String,
      cardId: map['card_id'] as String,
      cycleMonth: map['cycle_month'] as String,
      statementDate: _parseDate(map['statement_date'] as String),
      dueDate: _parseDate(map['due_date'] as String),
      totalAmountDue: (map['total_amount_due'] as num).toDouble(),
      minimumAmountDue: (map['minimum_amount_due'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      status: _statusFromDatabase(map['status'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'cycle_month': cycleMonth,
      'statement_date': _formatDate(statementDate),
      'due_date': _formatDate(dueDate),
      'total_amount_due': totalAmountDue,
      'minimum_amount_due': minimumAmountDue,
      'amount_paid': amountPaid,
      'status': _statusToDatabase(status),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory BillModel.fromEntity(BillEntity bill) {
    return BillModel(
      id: bill.id,
      cardId: bill.cardId,
      cycleMonth: bill.cycleMonth,
      statementDate: bill.statementDate,
      dueDate: bill.dueDate,
      totalAmountDue: bill.totalAmountDue,
      minimumAmountDue: bill.minimumAmountDue,
      amountPaid: bill.amountPaid,
      status: bill.status,
      updatedAt: bill.updatedAt,
    );
  }

  static DateTime _parseDate(String value) {
    final parsed = DateTime.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static BillStatus _statusFromDatabase(String value) {
    return switch (value) {
      'unpaid' => BillStatus.unpaid,
      'partially_paid' => BillStatus.partiallyPaid,
      'paid' => BillStatus.paid,
      _ => throw FormatException('Unknown bill status: $value'),
    };
  }

  static String _statusToDatabase(BillStatus value) {
    return switch (value) {
      BillStatus.unpaid => 'unpaid',
      BillStatus.partiallyPaid => 'partially_paid',
      BillStatus.paid => 'paid',
    };
  }

  static String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
