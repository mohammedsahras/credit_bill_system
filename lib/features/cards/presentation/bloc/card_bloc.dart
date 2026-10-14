import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/add_card_usecase.dart';
import '../../domain/usecases/archive_card_usecase.dart';
import '../../domain/usecases/delete_card_usecase.dart';
import '../../domain/usecases/get_cards_usecase.dart';
import '../../domain/usecases/update_card_usecase.dart';
import 'card_event.dart';
import 'card_state.dart';

class CardBloc extends Bloc<CardEvent, CardState> {
  final GetCardsUseCase getCardsUseCase;
  final AddCardUseCase addCardUseCase;
  final UpdateCardUseCase updateCardUseCase;
  final ArchiveCardUseCase archiveCardUseCase;
  final DeleteCardUseCase deleteCardUseCase;

  CardBloc({
    required this.getCardsUseCase,
    required this.addCardUseCase,
    required this.updateCardUseCase,
    required this.archiveCardUseCase,
    required this.deleteCardUseCase,
  }) : super(const CardInitialState()) {
    on<LoadCardsEvent>(_onLoadCards);
    on<AddCardEvent>(_onAddCard);
    on<UpdateCardEvent>(_onUpdateCard);
    on<ArchiveCardEvent>(_onArchiveCard);
    on<DeleteCardEvent>(_onDeleteCard);
  }

  Future<void> _onLoadCards(
    LoadCardsEvent event,
    Emitter<CardState> emit,
  ) async {
    emit(const CardLoadingState());
    final result = await getCardsUseCase.execute();
    result.fold(
      (failure) => emit(CardErrorState(failure.message)),
      (cards) => emit(CardLoadedState(cards)),
    );
  }

  Future<void> _onAddCard(AddCardEvent event, Emitter<CardState> emit) async {
    emit(const CardLoadingState());
    final result = await addCardUseCase.execute(event.card);
    result.fold((failure) => emit(CardErrorState(failure.message)), (card) {
      emit(CardAddedSuccessState(card));
      add(const LoadCardsEvent());
    });
  }

  Future<void> _onUpdateCard(
    UpdateCardEvent event,
    Emitter<CardState> emit,
  ) async {
    emit(const CardLoadingState());
    final result = await updateCardUseCase.execute(event.card);
    result.fold(
      (failure) {
        emit(CardErrorState(failure.message));
        add(const LoadCardsEvent());
      },
      (card) {
        emit(CardUpdatedSuccessState(card));
        add(const LoadCardsEvent());
      },
    );
  }

  Future<void> _onArchiveCard(
    ArchiveCardEvent event,
    Emitter<CardState> emit,
  ) async {
    emit(const CardLoadingState());
    final result = await archiveCardUseCase.execute(event.cardId);
    result.fold(
      (failure) {
        emit(CardErrorState(failure.message));
        add(const LoadCardsEvent());
      },
      (_) {
        emit(CardArchivedSuccessState(event.cardId));
        add(const LoadCardsEvent());
      },
    );
  }

  Future<void> _onDeleteCard(
    DeleteCardEvent event,
    Emitter<CardState> emit,
  ) async {
    emit(const CardLoadingState());
    final result = await deleteCardUseCase.execute(event.cardId);
    result.fold(
      (failure) {
        emit(CardErrorState(failure.message));
        add(const LoadCardsEvent());
      },
      (_) {
        emit(CardDeletedSuccessState(event.cardId));
        add(const LoadCardsEvent());
      },
    );
  }
}
