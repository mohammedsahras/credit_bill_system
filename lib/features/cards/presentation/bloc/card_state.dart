import 'package:equatable/equatable.dart';
import '../../domain/entities/card_entity.dart';

abstract class CardState extends Equatable {
  const CardState();

  @override
  List<Object?> get props => [];
}

class CardInitialState extends CardState {
  const CardInitialState();
}

class CardLoadingState extends CardState {
  const CardLoadingState();
}

class CardLoadedState extends CardState {
  final List<CardEntity> cards;

  const CardLoadedState(this.cards);

  @override
  List<Object?> get props => [cards];
}

class CardAddedSuccessState extends CardState {
  final CardEntity card;

  const CardAddedSuccessState(this.card);

  @override
  List<Object?> get props => [card];
}

class CardErrorState extends CardState {
  final String message;

  const CardErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
