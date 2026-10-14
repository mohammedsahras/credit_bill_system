import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/card_repository.dart';

class ArchiveCardUseCase {
  final CardRepository repository;

  const ArchiveCardUseCase(this.repository);

  Future<Either<Failure, bool>> execute(String id) {
    return repository.archiveActiveCard(id);
  }
}
