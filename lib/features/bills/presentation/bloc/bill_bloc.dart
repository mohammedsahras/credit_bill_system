import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_active_bills_usecase.dart';
import '../../domain/usecases/save_bill_usecase.dart';
import 'bill_event.dart';
import 'bill_state.dart';

class BillBloc extends Bloc<BillEvent, BillState> {
  final GetActiveBillsUseCase getActiveBillsUseCase;
  final SaveBillUseCase saveBillUseCase;

  BillBloc({required this.getActiveBillsUseCase, required this.saveBillUseCase})
    : super(const BillInitialState()) {
    on<LoadActiveBillsEvent>(_onLoadActiveBills);
    on<SaveBillEvent>(_onSaveBill);
  }

  Future<void> _onLoadActiveBills(
    LoadActiveBillsEvent event,
    Emitter<BillState> emit,
  ) async {
    final previousBills = state.bills;
    emit(BillLoadingState(previousBills));
    final result = await getActiveBillsUseCase.execute();
    result.fold(
      (failure) => emit(BillLoadErrorState(failure.message, previousBills)),
      (bills) => emit(BillLoadedState(bills)),
    );
  }

  Future<void> _onSaveBill(SaveBillEvent event, Emitter<BillState> emit) async {
    final previousBills = state.bills;
    emit(BillSavingState(previousBills));
    final result = await saveBillUseCase.execute(
      cardId: event.cardId,
      statementDate: event.statementDate,
      dueDate: event.dueDate,
      totalAmountDue: event.totalAmountDue,
      minimumAmountDue: event.minimumAmountDue,
    );
    result.fold(
      (failure) {
        emit(BillSaveErrorState(failure.message, previousBills));
        add(const LoadActiveBillsEvent());
      },
      (bill) {
        final updatedBills = [
          ...previousBills.where(
            (existing) =>
                existing.id != bill.id &&
                !(existing.cardId == bill.cardId &&
                    existing.cycleMonth == bill.cycleMonth),
          ),
          bill,
        ]..sort((first, second) => first.dueDate.compareTo(second.dueDate));
        emit(BillSavedSuccessState(bill, updatedBills));
        add(const LoadActiveBillsEvent());
      },
    );
  }
}
