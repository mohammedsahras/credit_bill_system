import 'package:equatable/equatable.dart';

enum BillStatus { unpaid, partiallyPaid, paid }

class BillEntity extends Equatable {
  final String id;
  final String cardId;
  final String cycleMonth;
  final DateTime statementDate;
  final DateTime dueDate;
  final double totalAmountDue;
  final double minimumAmountDue;
  final double amountPaid;
  final BillStatus status;
  final DateTime updatedAt;

  const BillEntity({
    required this.id,
    required this.cardId,
    required this.cycleMonth,
    required this.statementDate,
    required this.dueDate,
    required this.totalAmountDue,
    required this.minimumAmountDue,
    required this.amountPaid,
    required this.status,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    cardId,
    cycleMonth,
    statementDate,
    dueDate,
    totalAmountDue,
    minimumAmountDue,
    amountPaid,
    status,
    updatedAt,
  ];
}
