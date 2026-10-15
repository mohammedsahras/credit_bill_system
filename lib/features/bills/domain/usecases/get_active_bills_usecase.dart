import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class GetActiveBillsUseCase {
  final BillRepository repository;

  const GetActiveBillsUseCase(this.repository);

  Future<Either<Failure, List<BillEntity>>> execute() {
    return repository.getActiveBills();
  }
}
