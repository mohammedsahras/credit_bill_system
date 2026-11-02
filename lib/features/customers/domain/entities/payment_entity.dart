import 'package:equatable/equatable.dart';

/// A payment recorded for a customer.
/// Amount is stored in minor units (integer) for precision.
class PaymentEntity extends Equatable {
  final String id;
  final String customerId;
  final int amountMinor;
  final DateTime paymentDate;
  final String paymentType; // 'full' or 'partial'
  final DateTime createdAt;

  const PaymentEntity({
    required this.id,
    required this.customerId,
    required this.amountMinor,
    required this.paymentDate,
    required this.paymentType,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    customerId,
    amountMinor,
    paymentDate,
    paymentType,
    createdAt,
  ];
}
