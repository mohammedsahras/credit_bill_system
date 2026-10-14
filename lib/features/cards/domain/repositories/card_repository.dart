import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/card_entity.dart';

abstract class CardRepository {
  Future<Either<Failure, CardEntity>> addCard(CardEntity card);
  Future<Either<Failure, List<CardEntity>>> getActiveCards();
  Future<Either<Failure, CardEntity?>> getCardById(String id);
}
