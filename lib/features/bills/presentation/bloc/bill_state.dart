import 'package:equatable/equatable.dart';

import '../../domain/entities/bill_entity.dart';

abstract class BillState extends Equatable {
  final List<BillEntity> bills;

  const BillState([this.bills = const []]);

  @override
  List<Object?> get props => [bills];
}

class BillInitialState extends BillState {
  const BillInitialState();
}

class BillLoadingState extends BillState {
  const BillLoadingState([super.bills]);
}

class BillSavingState extends BillState {
  const BillSavingState([super.bills]);
}

class BillLoadedState extends BillState {
  const BillLoadedState(super.bills);
}

class BillSavedSuccessState extends BillState {
  final BillEntity bill;

  const BillSavedSuccessState(this.bill, [super.bills]);

  @override
  List<Object?> get props => [bill, ...super.props];
}

class BillErrorState extends BillState {
  final String message;

  const BillErrorState(this.message, [super.bills]);

  @override
  List<Object?> get props => [message, ...super.props];
}

class BillLoadErrorState extends BillErrorState {
  const BillLoadErrorState(super.message, [super.bills]);
}

class BillSaveErrorState extends BillErrorState {
  const BillSaveErrorState(super.message, [super.bills]);
}
