import 'package:equatable/equatable.dart';

/// Allocation of a payment to a specific credit transaction.
class PaymentAllocationEntity extends Equatable {
  final String id;
  final String paymentId;
  final String creditTransactionId;
  final int allocatedAmountMinor;
  final DateTime createdAt;

  const PaymentAllocationEntity({
    required this.id,
    required this.paymentId,
    required this.creditTransactionId,
    required this.allocatedAmountMinor,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    paymentId,
    creditTransactionId,
    allocatedAmountMinor,
    createdAt,
  ];
}
