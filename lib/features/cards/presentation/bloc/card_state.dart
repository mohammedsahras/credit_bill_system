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

class CardUpdatedSuccessState extends CardState {
  final CardEntity card;

  const CardUpdatedSuccessState(this.card);

  @override
  List<Object?> get props => [card];
}

class CardArchivedSuccessState extends CardState {
  final String cardId;

  const CardArchivedSuccessState(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class CardDeletedSuccessState extends CardState {
  final String cardId;

  const CardDeletedSuccessState(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class CardErrorState extends CardState {
  final String message;

  const CardErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
