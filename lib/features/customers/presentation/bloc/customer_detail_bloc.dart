import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/customers/domain/entities/credit_transaction_entity.dart';
import 'package:credit_bill_system/features/customers/domain/entities/customer_entity.dart';
import 'package:credit_bill_system/features/customers/domain/entities/payment_entity.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/credit_transaction_repository.dart';
import 'package:credit_bill_system/features/customers/domain/repositories/payment_repository.dart';
import 'package:credit_bill_system/features/customers/domain/usecases/customer_usecases.dart';

abstract class CustomerDetailEvent {}

class LoadCustomerDetailEvent extends CustomerDetailEvent {
  final String customerId;
  LoadCustomerDetailEvent(this.customerId);
}

abstract class CustomerDetailState {}

class CustomerDetailInitialState extends CustomerDetailState {}

class CustomerDetailLoadingState extends CustomerDetailState {}

class CustomerDetailLoadedState extends CustomerDetailState {
  final CustomerEntity customer;
  final List<CreditTransactionEntity> transactions;
  final List<PaymentEntity> payments;
  final int totalCreditMinor;
  final int totalPaidMinor;

  CustomerDetailLoadedState({
    required this.customer,
    required this.transactions,
    required this.payments,
    required this.totalCreditMinor,
    required this.totalPaidMinor,
  });

  int get outstandingMinor => totalCreditMinor - totalPaidMinor;
}

class CustomerDetailErrorState extends CustomerDetailState {
  final String message;
  CustomerDetailErrorState(this.message);
}

class CustomerDetailBloc extends Bloc<CustomerDetailEvent, CustomerDetailState> {
  final GetCustomerByIdUseCase getCustomerByIdUseCase;
  final CreditTransactionRepository creditTransactionRepository;
  final PaymentRepository paymentRepository;

  CustomerDetailBloc({
    required this.getCustomerByIdUseCase,
    required this.creditTransactionRepository,
    required this.paymentRepository,
  }) : super(CustomerDetailInitialState()) {
    on<LoadCustomerDetailEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadCustomerDetailEvent event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(CustomerDetailLoadingState());
    final customerResult = await getCustomerByIdUseCase.execute(event.customerId);
    final customer = customerResult.fold<Failure?>(
      (f) => f,
      (c) => null,
    );
    if (customer != null) {
      // customer variable holds failure here; re-check
    }
    // Use fold properly
    CustomerEntity? foundCustomer;
    Failure? failure;
    customerResult.fold((f) => failure = f, (c) => foundCustomer = c);
    if (failure != null) {
      emit(CustomerDetailErrorState(failure!.message));
      return;
    }
    if (foundCustomer == null) {
      emit(CustomerDetailErrorState('Customer not found.'));
      return;
    }

    final txResult =
        await creditTransactionRepository.getTransactionsByCustomer(event.customerId);
    final payResult =
        await paymentRepository.getPaymentsByCustomer(event.customerId);
    final paidResult = await paymentRepository.getCustomerTotalPaid(event.customerId);

    txResult.fold((f) => failure = f, (_) => failure = null);
    if (failure != null) {
      emit(CustomerDetailErrorState(failure!.message));
      return;
    }
    payResult.fold((f) => failure = f, (_) => failure = null);
    if (failure != null) {
      emit(CustomerDetailErrorState(failure!.message));
      return;
    }
    paidResult.fold((f) => failure = f, (_) => failure = null);
    if (failure != null) {
      emit(CustomerDetailErrorState(failure!.message));
      return;
    }

    final transactions = txResult.fold((_) => <CreditTransactionEntity>[], (v) => v);
    final payments = payResult.fold((_) => <PaymentEntity>[], (v) => v);
    final totalPaid = paidResult.fold((_) => 0, (v) => v);
    final totalCredit =
        transactions.fold<int>(0, (sum, t) => sum + t.amountMinor);

    emit(CustomerDetailLoadedState(
      customer: foundCustomer!,
      transactions: transactions,
      payments: payments,
      totalCreditMinor: totalCredit,
      totalPaidMinor: totalPaid,
    ));
  }
}