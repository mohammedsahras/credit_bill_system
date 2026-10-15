import 'package:uuid/uuid.dart';

import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../cards/domain/repositories/card_repository.dart';
import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class SaveBillUseCase {
  final BillRepository billRepository;
  final CardRepository cardRepository;
  final Uuid uuid;

  SaveBillUseCase({
    required this.billRepository,
    required this.cardRepository,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<Either<Failure, BillEntity>> execute({
    required String cardId,
    required DateTime statementDate,
    required DateTime dueDate,
    required double totalAmountDue,
    required double minimumAmountDue,
  }) async {
    if (!totalAmountDue.isFinite ||
        !minimumAmountDue.isFinite ||
        totalAmountDue < 0 ||
        minimumAmountDue < 0 ||
        minimumAmountDue > totalAmountDue) {
      return const Left(
        ValidationFailure(
          'Amounts must be non-negative and minimum due cannot exceed total due.',
        ),
      );
    }

    final statement = DateTime(
      statementDate.year,
      statementDate.month,
      statementDate.day,
    );
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(statement)) {
      return const Left(
        ValidationFailure('Due date must be on or after statement date.'),
      );
    }

    final cardResult = await cardRepository.getCardById(cardId);
    final cardFailure = cardResult.leftOrNull;
    if (cardFailure != null) return Left(cardFailure);
    final card = cardResult.rightOrNull;
    if (card == null || card.isArchived) {
      return const NotFoundFailure().asLeft();
    }

    final now = DateTime.now().toUtc();
    final bill = BillEntity(
      id: uuid.v4(),
      cardId: cardId,
      cycleMonth:
          '${statement.year.toString().padLeft(4, '0')}-${statement.month.toString().padLeft(2, '0')}',
      statementDate: statement,
      dueDate: due,
      totalAmountDue: double.parse(totalAmountDue.toStringAsFixed(2)),
      minimumAmountDue: double.parse(minimumAmountDue.toStringAsFixed(2)),
      amountPaid: 0,
      status: BillStatus.unpaid,
      updatedAt: now,
    );
    return billRepository.saveUnpaidBill(bill);
  }
}

extension _FailureLeftExt on Failure {
  Either<Failure, T> asLeft<T>() => Left(this);
}
