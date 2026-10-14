import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

class GetCardsUseCase {
  final CardRepository repository;

  const GetCardsUseCase(this.repository);

  Future<Either<Failure, List<CardEntity>>> execute() async {
    return await repository.getActiveCards();
  }
}
