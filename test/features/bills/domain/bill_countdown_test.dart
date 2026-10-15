import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/bills/domain/entities/bill_entity.dart';
import 'package:credit_bill_system/features/bills/domain/repositories/bill_repository.dart';
import 'package:credit_bill_system/features/bills/domain/usecases/bill_date_calculator.dart';
import 'package:credit_bill_system/features/bills/domain/usecases/save_bill_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/repositories/card_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = BillDateCalculator();

  test('countdown uses local calendar days and covers urgency boundaries', () {
    final today = DateTime(2026, 10, 14, 23, 59);
    expect(calculator.daysUntil(DateTime(2026, 10, 13), today), -1);
    expect(calculator.daysUntil(DateTime(2026, 10, 14), today), 0);
    expect(calculator.daysUntil(DateTime(2026, 10, 16), today), 2);
    expect(calculator.daysUntil(DateTime(2026, 10, 17), today), 3);
    expect(calculator.daysUntil(DateTime(2026, 10, 21), today), 7);
    expect(calculator.daysUntil(DateTime(2026, 10, 22), today), 8);
  });

  test('default due day is in the following month and clamps short months', () {
    final card = CardEntity(
      id: 'date-card',
      bankName: 'HDFC',
      nickname: 'Millennia',
      lastFour: '4821',
      network: 'Visa',
      totalLimit: 150000,
      billingDay: 31,
      dueDay: 31,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final dates = calculator.defaultsFor(card, DateTime(2026, 1));
    expect(dates.statementDate, DateTime(2026, 1, 31));
    expect(dates.dueDate, DateTime(2026, 2, 28));
  });

  test('statement date changes repair only due dates that precede it', () {
    final card = CardEntity(
      id: 'date-card',
      bankName: 'HDFC',
      nickname: 'Millennia',
      lastFour: '4821',
      network: 'Visa',
      totalLimit: 150000,
      billingDay: 12,
      dueDay: 31,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    expect(
      const BillDateCalculator().dueDateAfterStatementChange(
        card,
        DateTime(2026, 1, 12),
        DateTime(2026, 1, 2),
      ),
      DateTime(2026, 2, 28),
    );
    expect(
      const BillDateCalculator().dueDateAfterStatementChange(
        card,
        DateTime(2026, 1, 12),
        DateTime(2026, 3, 5),
      ),
      DateTime(2026, 3, 5),
    );
  });

  test(
    'save use case rejects invalid amounts and due dates before lookup',
    () async {
      final cards = _CardRepository();
      final bills = _BillRepository();
      final useCase = SaveBillUseCase(
        billRepository: bills,
        cardRepository: cards,
      );

      final amountResult = await useCase.execute(
        cardId: 'unused',
        statementDate: DateTime(2026, 10, 12),
        dueDate: DateTime(2026, 11, 2),
        totalAmountDue: 100,
        minimumAmountDue: 101,
      );
      final dateResult = await useCase.execute(
        cardId: 'unused',
        statementDate: DateTime(2026, 10, 12),
        dueDate: DateTime(2026, 10, 11),
        totalAmountDue: 100,
        minimumAmountDue: 10,
      );

      expect(amountResult.leftOrNull, isA<ValidationFailure>());
      expect(dateResult.leftOrNull, isA<ValidationFailure>());
      expect(cards.lookupCount, 0);
      expect(bills.saveCount, 0);
    },
  );
}

class _CardRepository implements CardRepository {
  int lookupCount = 0;

  @override
  Future<Either<Failure, CardEntity>> getCardById(String id) async {
    lookupCount++;
    return const Left(DatabaseFailure('lookup error'));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BillRepository implements BillRepository {
  int saveCount = 0;

  @override
  Future<Either<Failure, BillEntity>> saveUnpaidBill(BillEntity bill) async {
    saveCount++;
    return Right(bill);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
