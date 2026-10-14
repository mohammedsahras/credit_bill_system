import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

class UpdateCardUseCase {
  final CardRepository repository;

  const UpdateCardUseCase(this.repository);

  Future<Either<Failure, CardEntity>> execute(CardEntity card) async {
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
    if (card.colorGradientIdx < 0 ||
        card.colorGradientIdx >= CardEntity.gradientThemeCount) {
      return const Left(ValidationFailure('Select a valid card theme.'));
    }
    if (card.isArchived) {
      return const Left(NotFoundFailure());
    }
    return repository.updateActiveCard(card);
  }
}
