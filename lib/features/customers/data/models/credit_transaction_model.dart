import 'package:credit_bill_system/features/customers/domain/entities/credit_transaction_entity.dart';

class CreditTransactionModel extends CreditTransactionEntity {
  const CreditTransactionModel({
    required super.id,
    required super.customerId,
    required super.amountMinor,
    super.description,
    required super.dueDate,
    required super.createdAt,
  });

  factory CreditTransactionModel.fromMap(Map<String, dynamic> map) {
    return CreditTransactionModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      amountMinor: map['amount_minor'] as int,
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['due_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount_minor': amountMinor,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CreditTransactionModel.fromEntity(CreditTransactionEntity entity) {
    return CreditTransactionModel(
      id: entity.id,
      customerId: entity.customerId,
      amountMinor: entity.amountMinor,
      description: entity.description,
      dueDate: entity.dueDate,
      createdAt: entity.createdAt,
    );
  }
}
