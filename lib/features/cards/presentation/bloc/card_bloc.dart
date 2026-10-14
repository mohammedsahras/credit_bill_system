import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_card_usecase.dart';
import '../../domain/usecases/get_cards_usecase.dart';
import 'card_event.dart';
import 'card_state.dart';

class CardBloc extends Bloc<CardEvent, CardState> {
  final GetCardsUseCase getCardsUseCase;
  final AddCardUseCase addCardUseCase;

  CardBloc({
    required this.getCardsUseCase,
    required this.addCardUseCase,
  }) : super(const CardInitialState()) {
    on<LoadCardsEvent>(_onLoadCards);
    on<AddCardEvent>(_onAddCard);
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

  Future<void> _onAddCard(
    AddCardEvent event,
    Emitter<CardState> emit,
  ) async {
    emit(const CardLoadingState());
    final result = await addCardUseCase.execute(event.card);
    result.fold(
      (failure) => emit(CardErrorState(failure.message)),
      (card) {
        emit(CardAddedSuccessState(card));
        add(const LoadCardsEvent());
      },
    );
  }
}
