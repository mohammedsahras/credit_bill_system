import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:credit_bill_system/features/customers/domain/entities/customer_entity.dart';
import 'package:credit_bill_system/features/customers/domain/usecases/customer_usecases.dart';

abstract class CustomerEvent {}

class LoadCustomersEvent extends CustomerEvent {}

class SearchCustomersEvent extends CustomerEvent {
  final String query;
  SearchCustomersEvent(this.query);
}

class AddCustomerEvent extends CustomerEvent {
  final CustomerEntity customer;
  AddCustomerEvent(this.customer);
}

class UpdateCustomerEvent extends CustomerEvent {
  final CustomerEntity customer;
  UpdateCustomerEvent(this.customer);
}

class DeactivateCustomerEvent extends CustomerEvent {
  final String id;
  DeactivateCustomerEvent(this.id);
}

abstract class CustomerState {}

class CustomerInitialState extends CustomerState {}

class CustomerLoadingState extends CustomerState {}

class CustomerLoadedState extends CustomerState {
  final List<CustomerEntity> customers;
  final String? searchQuery;
  CustomerLoadedState({required this.customers, this.searchQuery});
}

class CustomerErrorState extends CustomerState {
  final String message;
  CustomerErrorState(this.message);
}

class CustomerSuccessState extends CustomerState {
  final String message;
  CustomerSuccessState(this.message);
}

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final SearchCustomersUseCase searchCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeactivateCustomerUseCase deactivateCustomerUseCase;

  CustomerBloc({
    required this.getCustomersUseCase,
    required this.searchCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deactivateCustomerUseCase,
  }) : super(CustomerInitialState()) {
    on<LoadCustomersEvent>(_onLoad);
    on<SearchCustomersEvent>(_onSearch);
    on<AddCustomerEvent>(_onAdd);
    on<UpdateCustomerEvent>(_onUpdate);
    on<DeactivateCustomerEvent>(_onDeactivate);
  }

  Future<void> _onLoad(
    LoadCustomersEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoadingState());
    final result = await getCustomersUseCase.execute();
    result.fold(
      (failure) => emit(CustomerErrorState(failure.message)),
      (customers) => emit(CustomerLoadedState(customers: customers)),
    );
  }

  Future<void> _onSearch(
    SearchCustomersEvent event,
    Emitter<CustomerState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(LoadCustomersEvent());
      return;
    }
    emit(CustomerLoadingState());
    final result = await searchCustomersUseCase.execute(event.query);
    result.fold(
      (failure) => emit(CustomerErrorState(failure.message)),
      (customers) => emit(
        CustomerLoadedState(customers: customers, searchQuery: event.query),
      ),
    );
  }

  Future<void> _onAdd(
    AddCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoadingState());
    final result = await addCustomerUseCase.execute(event.customer);
    result.fold((failure) => emit(CustomerErrorState(failure.message)), (
      customer,
    ) {
      emit(
        CustomerSuccessState('Customer "${customer.name}" added successfully.'),
      );
      add(LoadCustomersEvent());
    });
  }

  Future<void> _onUpdate(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoadingState());
    final result = await updateCustomerUseCase.execute(event.customer);
    result.fold((failure) => emit(CustomerErrorState(failure.message)), (_) {
      emit(CustomerSuccessState('Customer updated successfully.'));
      add(LoadCustomersEvent());
    });
  }

  Future<void> _onDeactivate(
    DeactivateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoadingState());
    final result = await deactivateCustomerUseCase.execute(event.id);
    result.fold((failure) => emit(CustomerErrorState(failure.message)), (_) {
      emit(CustomerSuccessState('Customer deactivated.'));
      add(LoadCustomersEvent());
    });
  }
}
