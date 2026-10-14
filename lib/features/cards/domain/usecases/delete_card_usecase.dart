import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/card_repository.dart';

class DeleteCardUseCase {
  final CardRepository repository;

  const DeleteCardUseCase(this.repository);

  Future<Either<Failure, bool>> execute(String id) {
    return repository.deleteActiveCard(id);
  }
}
