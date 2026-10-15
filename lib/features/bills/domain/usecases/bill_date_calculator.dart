import '../../../cards/domain/entities/card_entity.dart';

class BillCycleDates {
  final DateTime statementDate;
  final DateTime dueDate;

  const BillCycleDates({required this.statementDate, required this.dueDate});
}

class BillDateCalculator {
  const BillDateCalculator();

  BillCycleDates defaultsFor(CardEntity card, DateTime cycleMonth) {
    final statementMonth = DateTime(cycleMonth.year, cycleMonth.month);
    final statementDate = _dayInMonth(
      statementMonth.year,
      statementMonth.month,
      card.billingDay,
    );
    final dueMonth = DateTime(statementMonth.year, statementMonth.month + 1);
    final dueDate = _dayInMonth(dueMonth.year, dueMonth.month, card.dueDay);
    return BillCycleDates(statementDate: statementDate, dueDate: dueDate);
  }

  DateTime dueDateAfterStatementChange(
    CardEntity card,
    DateTime statementDate,
    DateTime currentDueDate,
  ) {
    final statement = DateTime(
      statementDate.year,
      statementDate.month,
      statementDate.day,
    );
    final due = DateTime(
      currentDueDate.year,
      currentDueDate.month,
      currentDueDate.day,
    );
    return due.isBefore(statement) ? defaultsFor(card, statement).dueDate : due;
  }

  DateTime _dayInMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay).toInt());
  }

  int daysUntil(DateTime dueDate, DateTime today) {
    final due = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
    final localToday = DateTime.utc(today.year, today.month, today.day);
    return due.difference(localToday).inDays;
  }
}
