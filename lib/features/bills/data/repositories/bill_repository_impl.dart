import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_local_data_source.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final BillLocalDataSource localDataSource;

  const BillRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, BillEntity>> saveUnpaidBill(BillEntity bill) async {
    try {
      final outcome = await localDataSource.saveUnpaidBill(
        BillModel.fromEntity(bill),
      );
      switch (outcome.type) {
        case BillSaveOutcomeType.saved:
          final saved = outcome.bill;
          if (saved == null) {
            return const DatabaseFailure(
              'The saved bill was not returned by storage.',
            ).asLeft();
          }
          return Right(saved);
        case BillSaveOutcomeType.cardUnavailable:
          return const NotFoundFailure().asLeft();
        case BillSaveOutcomeType.paymentAlreadyRecorded:
          return const ConflictFailure(
            'A bill cannot be edited after a payment has been recorded.',
          ).asLeft();
      }
    } catch (error) {
      return DatabaseFailure('Failed to save bill: $error').asLeft();
    }
  }

  @override
  Future<Either<Failure, List<BillEntity>>> getActiveBills() async {
    try {
      return Right(await localDataSource.getActiveBills());
    } catch (error) {
      return DatabaseFailure('Failed to load bills: $error').asLeft();
    }
  }
}

extension _FailureLeftExt on Failure {
  Either<Failure, T> asLeft<T>() => Left(this);
}
