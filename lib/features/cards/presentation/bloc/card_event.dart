import 'package:equatable/equatable.dart';

import '../../domain/entities/card_entity.dart';

abstract class CardEvent extends Equatable {
  const CardEvent();

  @override
  List<Object?> get props => [];
}

class LoadCardsEvent extends CardEvent {
  const LoadCardsEvent();
}

class AddCardEvent extends CardEvent {
  final CardEntity card;

  const AddCardEvent(this.card);

  @override
  List<Object?> get props => [card];
}

class UpdateCardEvent extends CardEvent {
  final CardEntity card;

  const UpdateCardEvent(this.card);

  @override
  List<Object?> get props => [card];
}

class ArchiveCardEvent extends CardEvent {
  final String cardId;

  const ArchiveCardEvent(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class DeleteCardEvent extends CardEvent {
  final String cardId;

  const DeleteCardEvent(this.cardId);

  @override
  List<Object?> get props => [cardId];
}
