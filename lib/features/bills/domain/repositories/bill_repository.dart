import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bill_entity.dart';

abstract class BillRepository {
  Future<Either<Failure, BillEntity>> saveUnpaidBill(BillEntity bill);
  Future<Either<Failure, List<BillEntity>>> getActiveBills();
}
