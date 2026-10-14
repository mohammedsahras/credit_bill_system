import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

class AddCardUseCase {
  final CardRepository repository;

  const AddCardUseCase(this.repository);

  Future<Either<Failure, CardEntity>> execute(CardEntity card) async {
    if (card.bankName.trim().isEmpty) {
      return const Left(ValidationFailure('Bank name cannot be empty.'));
    }
    if (card.nickname.trim().isEmpty) {
      return const Left(ValidationFailure('Card nickname cannot be empty.'));
    }
    final isFourDigits = RegExp(r'^[0-9]{4}$').hasMatch(card.lastFour);
    if (!isFourDigits) {
      return const Left(ValidationFailure('Must be exactly 4 digits'));
    }
    if (!card.totalLimit.isFinite || card.totalLimit <= 0) {
      return const Left(
        ValidationFailure('Credit limit must be greater than zero'),
      );
    }
    if (card.billingDay < 1 || card.billingDay > 31) {
      return const Left(ValidationFailure('Day must be between 1 and 31'));
    }
    if (card.dueDay < 1 || card.dueDay > 31) {
      return const Left(ValidationFailure('Day must be between 1 and 31'));
    }

    return await repository.addCard(card);
  }
}
