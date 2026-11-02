import 'package:credit_bill_system/features/customers/domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.customerId,
    required super.amountMinor,
    required super.paymentDate,
    required super.paymentType,
    required super.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      amountMinor: map['amount_minor'] as int,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentType: map['payment_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount_minor': amountMinor,
      'payment_date': paymentDate.toIso8601String(),
      'payment_type': paymentType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      customerId: entity.customerId,
      amountMinor: entity.amountMinor,
      paymentDate: entity.paymentDate,
      paymentType: entity.paymentType,
      createdAt: entity.createdAt,
    );
  }
}
