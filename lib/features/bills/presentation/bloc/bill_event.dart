import 'package:equatable/equatable.dart';

abstract class BillEvent extends Equatable {
  const BillEvent();

  @override
  List<Object?> get props => [];
}

class LoadActiveBillsEvent extends BillEvent {
  const LoadActiveBillsEvent();
}

class SaveBillEvent extends BillEvent {
  final String cardId;
  final DateTime statementDate;
  final DateTime dueDate;
  final double totalAmountDue;
  final double minimumAmountDue;

  const SaveBillEvent({
    required this.cardId,
    required this.statementDate,
    required this.dueDate,
    required this.totalAmountDue,
    required this.minimumAmountDue,
  });

  @override
  List<Object?> get props => [
    cardId,
    statementDate,
    dueDate,
    totalAmountDue,
    minimumAmountDue,
  ];
}
