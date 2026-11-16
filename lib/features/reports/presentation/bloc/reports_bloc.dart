import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:credit_bill_system/core/database/database_helper.dart';

abstract class ReportsEvent {}

class LoadReportsEvent extends ReportsEvent {}

abstract class ReportsState {}

class ReportsInitialState extends ReportsState {}

class ReportsLoadingState extends ReportsState {}

class ReportsLoadedState extends ReportsState {
  final int totalCustomers;
  final int totalCreditMinor;
  final int totalPaidMinor;
  final int totalTransactions;
  ReportsLoadedState({
    required this.totalCustomers,
    required this.totalCreditMinor,
    required this.totalPaidMinor,
    required this.totalTransactions,
  });
  int get outstandingMinor => totalCreditMinor - totalPaidMinor;
}

class ReportsErrorState extends ReportsState {
  final String message;
  ReportsErrorState(this.message);
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final DatabaseHelper databaseHelper;
  ReportsBloc({required this.databaseHelper}) : super(ReportsInitialState()) {
    on<LoadReportsEvent>(_onLoad);
  }

  Future<void> _onLoad(LoadReportsEvent event, Emitter<ReportsState> emit) async {
    emit(ReportsLoadingState());
    try {
      final db = await databaseHelper.database;
      final customers = await db.rawQuery(
          'SELECT COUNT(*) as c FROM customers WHERE is_active = 1');
      final totalCustomers = (customers.first['c'] as int?) ?? 0;
      final credit = await db.rawQuery(
          'SELECT COALESCE(SUM(amount_minor), 0) as t FROM credit_transactions');
      final totalCredit = (credit.first['t'] as int?) ?? 0;
      final paid = await db.rawQuery(
          'SELECT COALESCE(SUM(amount_minor), 0) as t FROM payments');
      final totalPaid = (paid.first['t'] as int?) ?? 0;
      final txCount = await db.rawQuery(
          'SELECT COUNT(*) as c FROM credit_transactions');
      final totalTx = (txCount.first['c'] as int?) ?? 0;
      emit(ReportsLoadedState(
        totalCustomers: totalCustomers,
        totalCreditMinor: totalCredit,
        totalPaidMinor: totalPaid,
        totalTransactions: totalTx,
      ));
    } catch (e) {
      emit(ReportsErrorState('Failed to load reports: $e'));
    }
  }
}