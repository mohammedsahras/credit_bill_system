import 'package:equatable/equatable.dart';

/// A credit transaction (bill) recorded for a customer.
/// Amount is stored in minor units (integer) for precision.
class CreditTransactionEntity extends Equatable {
  final String id;
  final String customerId;
  final int amountMinor;
  final String? description;
  final DateTime dueDate;
  final DateTime createdAt;

  const CreditTransactionEntity({
    required this.id,
    required this.customerId,
    required this.amountMinor,
    this.description,
    required this.dueDate,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    customerId,
    amountMinor,
    description,
    dueDate,
    createdAt,
  ];
}
