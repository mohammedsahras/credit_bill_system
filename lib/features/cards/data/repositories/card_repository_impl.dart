import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_local_data_source.dart';
import '../models/card_model.dart';

class CardRepositoryImpl implements CardRepository {
  final CardLocalDataSource localDataSource;

  CardRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, CardEntity>> addCard(CardEntity card) async {
    try {
      final model = CardModel.fromEntity(card);
      final savedModel = await localDataSource.insertCard(model);
      return Right(savedModel);
    } catch (e) {
      return DatabaseFailure('Failed to save card: ${e.toString()}').asLeft();
    }
  }

  @override
  Future<Either<Failure, List<CardEntity>>> getActiveCards() async {
    try {
      final models = await localDataSource.getActiveCards();
      return Right(models);
    } catch (e) {
      return DatabaseFailure('Failed to fetch cards: ${e.toString()}').asLeft();
    }
  }

  @override
  Future<Either<Failure, CardEntity?>> getCardById(String id) async {
    try {
      final model = await localDataSource.getCardById(id);
      return Right(model);
    } catch (e) {
      return DatabaseFailure('Failed to fetch card: ${e.toString()}').asLeft();
    }
  }
}

extension FailureLeftExt on Failure {
  Either<Failure, T> asLeft<T>() => Left(this);
}
