import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/app/presentation/wallet_composition_page.dart';
import 'package:credit_bill_system/features/bills/domain/entities/bill_entity.dart';
import 'package:credit_bill_system/features/bills/domain/repositories/bill_repository.dart';
import 'package:credit_bill_system/features/bills/domain/usecases/get_active_bills_usecase.dart';
import 'package:credit_bill_system/features/bills/domain/usecases/save_bill_usecase.dart';
import 'package:credit_bill_system/features/bills/presentation/bloc/bill_bloc.dart';
import 'package:credit_bill_system/features/bills/presentation/bloc/bill_event.dart';
import 'package:credit_bill_system/features/bills/presentation/pages/update_bill_page.dart';
import 'package:credit_bill_system/features/bills/presentation/widgets/bill_countdown_badge.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/repositories/card_repository.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/archive_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/delete_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/get_cards_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/update_card_usecase.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_bloc.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/card_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBillRepository extends Mock implements BillRepository {}

class _MockCardRepository extends Mock implements CardRepository {}

void main() {
  late _MockBillRepository billRepository;
  late _MockCardRepository cardRepository;
  final card = CardEntity(
    id: 'bill-card',
    bankName: 'Sample Bank',
    nickname: 'Everyday',
    lastFour: '4821',
    network: 'Visa',
    totalLimit: 150000,
    billingDay: 12,
    dueDay: 2,
    createdAt: DateTime.utc(2026, 10, 14),
  );

  setUpAll(() {
    registerFallbackValue(
      BillEntity(
        id: 'fallback',
        cardId: 'fallback',
        cycleMonth: '2026-10',
        statementDate: DateTime(2026, 10, 12),
        dueDate: DateTime(2026, 11, 2),
        totalAmountDue: 100,
        minimumAmountDue: 10,
        amountPaid: 0,
        status: BillStatus.unpaid,
        updatedAt: DateTime.utc(2026, 10, 14),
      ),
    );
    registerFallbackValue(card);
  });

  setUp(() {
    billRepository = _MockBillRepository();
    cardRepository = _MockCardRepository();
    when(() => billRepository.getActiveBills())
        .thenAnswer((_) async => const Right<Failure, List<BillEntity>>([]));
  });

  BillBloc createBillBloc() => BillBloc(
    getActiveBillsUseCase: GetActiveBillsUseCase(billRepository),
    saveBillUseCase: SaveBillUseCase(
      billRepository: billRepository,
      cardRepository: cardRepository,
    ),
  );

  CardBloc createCardBloc() => CardBloc(
    getCardsUseCase: GetCardsUseCase(cardRepository),
    addCardUseCase: AddCardUseCase(cardRepository),
    updateCardUseCase: UpdateCardUseCase(cardRepository),
    archiveCardUseCase: ArchiveCardUseCase(cardRepository),
    deleteCardUseCase: DeleteCardUseCase(cardRepository),
  );

  testWidgets('wallet and card detail show the stored bill countdown', (
    tester,
  ) async {
    final dueDate = DateTime.now().add(const Duration(days: 8));
    final bill = _bill(card.id, dueDate);
    when(() => cardRepository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => billRepository.getActiveBills())
        .thenAnswer((_) async => Right([bill]));
    final cardsBloc = createCardBloc();
    final billsBloc = createBillBloc();
    addTearDown(cardsBloc.close);
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cardsBloc),
            BlocProvider.value(value: billsBloc),
          ],
          child: const WalletCompositionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BillCountdownBadge), findsOneWidget);
    expect(find.text('8 days left'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walletCard_0')));
    await tester.pumpAndSettle();
    expect(find.byType(CardDetailPage), findsOneWidget);
    expect(find.byType(BillCountdownBadge), findsOneWidget);
    expect(find.byKey(const Key('logBillAction')), findsOneWidget);
  });

  testWidgets('countdown badge applies red, amber, and green boundaries', (
    tester,
  ) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final cases = <(int, Color)>[
      (-1, theme.colorScheme.error),
      (0, theme.colorScheme.error),
      (2, theme.colorScheme.error),
      (3, Colors.amber.shade800),
      (7, Colors.amber.shade800),
      (8, Colors.green.shade700),
    ];

    for (final (days, expectedColor) in cases) {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day + days);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: BillCountdownBadge(
              bill: _bill(card.id, dueDate),
              clock: () => now,
            ),
          ),
        ),
      );
      final badge = tester.widget<Container>(
        find.byKey(const Key('billCountdownBadge')),
      );
      expect(
        (badge.decoration! as BoxDecoration).color,
        expectedColor,
        reason: '$days local calendar days until due',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('countdown badge refreshes after local midnight', (tester) async {
    var now = DateTime(2026, 10, 14, 23, 59);
    final bill = _bill(card.id, DateTime(2026, 10, 15));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BillCountdownBadge(bill: bill, clock: () => now),
        ),
      ),
    );
    expect(find.text('Due in 1 d'), findsOneWidget);

    now = DateTime(2026, 10, 15);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('Due today'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('card detail updates an existing current-cycle bill', (
    tester,
  ) async {
    final dueDate = DateTime.now().add(const Duration(days: 8));
    final existing = _currentCycleBill(card.id, dueDate);
    when(() => cardRepository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => billRepository.getActiveBills())
        .thenAnswer((_) async => Right([existing]));
    when(() => cardRepository.getCardById(card.id))
        .thenAnswer((_) async => Right(card));
    when(() => billRepository.saveUnpaidBill(any()))
        .thenAnswer((invocation) async {
          final submitted = invocation.positionalArguments.single as BillEntity;
          return Right(
            BillEntity(
              id: existing.id,
              cardId: submitted.cardId,
              cycleMonth: submitted.cycleMonth,
              statementDate: submitted.statementDate,
              dueDate: submitted.dueDate,
              totalAmountDue: submitted.totalAmountDue,
              minimumAmountDue: submitted.minimumAmountDue,
              amountPaid: existing.amountPaid,
              status: existing.status,
              updatedAt: submitted.updatedAt,
            ),
          );
        });
    final cardsBloc = createCardBloc();
    final billsBloc = createBillBloc();
    addTearDown(cardsBloc.close);
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cardsBloc),
            BlocProvider.value(value: billsBloc),
          ],
          child: const WalletCompositionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walletCard_0')));
    await tester.pumpAndSettle();
    expect(find.text('Update Current Cycle Bill'), findsOneWidget);
    await tester.tap(find.byKey(const Key('logBillAction')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('totalAmountDueField')))
          .controller!
          .text,
      '1000.00',
    );
    await tester.ensureVisible(find.byKey(const Key('saveBillButton')));
    await tester.tap(find.byKey(const Key('saveBillButton')));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateBillPage), findsNothing);
    expect(find.text('Update Current Cycle Bill'), findsOneWidget);
    verify(() => billRepository.saveUnpaidBill(any())).called(1);
  });

  testWidgets('bill form validates and saves an active-card bill', (
    tester,
  ) async {
    when(() => cardRepository.getCardById(card.id))
        .thenAnswer((_) async => Right(card));
    when(() => billRepository.saveUnpaidBill(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.single as BillEntity),
    );
    final billsBloc = createBillBloc();
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: billsBloc,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                key: const Key('openBillForm'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => UpdateBillPage(card: card),
                  ),
                ),
                child: const Text('Open bill form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('openBillForm')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saveBillButton')));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a valid non-negative total amount.'),
      findsOneWidget,
    );
    expect(
      find.text('Enter a valid non-negative minimum amount.'),
      findsOneWidget,
    );
    verifyNever(() => billRepository.saveUnpaidBill(any()));

    await tester.enterText(
      find.byKey(const Key('totalAmountDueField')),
      '1250.75',
    );
    await tester.enterText(
      find.byKey(const Key('minimumAmountDueField')),
      '125.50',
    );
    await tester.ensureVisible(find.byKey(const Key('saveBillButton')));
    await tester.tap(find.byKey(const Key('saveBillButton')));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateBillPage), findsNothing);
    final savedBill =
        verify(() => billRepository.saveUnpaidBill(captureAny()))
                .captured
                .single
            as BillEntity;
    expect(savedBill.cardId, card.id);
    expect(
      savedBill.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(savedBill.totalAmountDue, 1250.75);
    expect(savedBill.minimumAmountDue, 125.5);
    expect(savedBill.status, BillStatus.unpaid);
    expect(
      savedBill.cycleMonth,
      '${DateTime.now().year.toString().padLeft(4, '0')}-'
      '${DateTime.now().month.toString().padLeft(2, '0')}',
    );
  });

  testWidgets('settled bill form is read-only', (tester) async {
    final bill = _bill(card.id, DateTime(2026, 11, 2)).copyWithPaid();
    final billsBloc = createBillBloc();
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: billsBloc,
          child: UpdateBillPage(card: card, existingBill: bill),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settledBillEditRestriction')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('saveBillButton')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('totalAmountDueField')))
          .enabled,
      isFalse,
    );
  });

  testWidgets('bill persistence errors remain visible in the entry form', (
    tester,
  ) async {
    when(() => cardRepository.getCardById(card.id))
        .thenAnswer((_) async => Right(card));
    when(() => billRepository.saveUnpaidBill(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('Could not save bill')),
    );
    final billsBloc = createBillBloc();
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: billsBloc,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                key: const Key('openBillForm'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => UpdateBillPage(card: card),
                  ),
                ),
                child: const Text('Open bill form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('openBillForm')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('totalAmountDueField')),
      '1250',
    );
    await tester.enterText(
      find.byKey(const Key('minimumAmountDueField')),
      '100',
    );
    await tester.ensureVisible(find.byKey(const Key('saveBillButton')));
    await tester.tap(find.byKey(const Key('saveBillButton')));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateBillPage), findsOneWidget);
    expect(find.text('Could not save bill'), findsOneWidget);
  });

  testWidgets('wallet surfaces bill-load errors without hiding active cards', (
    tester,
  ) async {
    when(() => cardRepository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => billRepository.getActiveBills()).thenAnswer(
      (_) async => const Left(DatabaseFailure('Could not load bills')),
    );
    final cardsBloc = createCardBloc();
    final billsBloc = createBillBloc();
    addTearDown(cardsBloc.close);
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cardsBloc),
            BlocProvider.value(value: billsBloc),
          ],
          child: const WalletCompositionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('walletCard_0')), findsOneWidget);
    expect(find.text('Could not load bills'), findsOneWidget);
  });

  testWidgets('wallet retains loaded bill badges after reload failure', (
    tester,
  ) async {
    final dueDate = DateTime.now().add(const Duration(days: 8));
    final existing = _currentCycleBill(card.id, dueDate);
    var loadCount = 0;
    when(() => cardRepository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => billRepository.getActiveBills()).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 1) return Right([existing]);
      return const Left(DatabaseFailure('Could not reload bills'));
    });
    final cardsBloc = createCardBloc();
    final billsBloc = createBillBloc();
    addTearDown(cardsBloc.close);
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cardsBloc),
            BlocProvider.value(value: billsBloc),
          ],
          child: const WalletCompositionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BillCountdownBadge), findsOneWidget);

    billsBloc.add(const LoadActiveBillsEvent());
    await tester.pumpAndSettle();

    expect(find.byType(BillCountdownBadge), findsOneWidget);
    expect(find.text('Could not reload bills'), findsOneWidget);
  });

  testWidgets('wallet shows saved bill when the following refresh fails', (
    tester,
  ) async {
    final existing = _currentCycleBill(
      card.id,
      DateTime.now().add(const Duration(days: 8)),
    );
    var loadCount = 0;
    when(() => cardRepository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => billRepository.getActiveBills()).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 1) return Right([existing]);
      return const Left(DatabaseFailure('Could not refresh bills'));
    });
    when(() => cardRepository.getCardById(card.id))
        .thenAnswer((_) async => Right(card));
    when(() => billRepository.saveUnpaidBill(any()))
        .thenAnswer((invocation) async {
          final submitted = invocation.positionalArguments.single as BillEntity;
          return Right(
            BillEntity(
              id: existing.id,
              cardId: submitted.cardId,
              cycleMonth: submitted.cycleMonth,
              statementDate: submitted.statementDate,
              dueDate: submitted.dueDate,
              totalAmountDue: submitted.totalAmountDue,
              minimumAmountDue: submitted.minimumAmountDue,
              amountPaid: 0,
              status: BillStatus.unpaid,
              updatedAt: submitted.updatedAt,
            ),
          );
        });
    final cardsBloc = createCardBloc();
    final billsBloc = createBillBloc();
    addTearDown(cardsBloc.close);
    addTearDown(billsBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cardsBloc),
            BlocProvider.value(value: billsBloc),
          ],
          child: const WalletCompositionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    billsBloc.add(
      SaveBillEvent(
        cardId: card.id,
        statementDate: DateTime(now.year, now.month, 12),
        dueDate: DateTime(now.year, now.month, now.day + 3),
        totalAmountDue: 1200,
        minimumAmountDue: 120,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Due in 3 d'), findsOneWidget);
    expect(find.text('Could not refresh bills'), findsOneWidget);
  });
}

BillEntity _bill(String cardId, DateTime dueDate) => BillEntity(
  id: 'bill-entry',
  cardId: cardId,
  cycleMonth:
      '${dueDate.year.toString().padLeft(4, '0')}-'
      '${dueDate.month.toString().padLeft(2, '0')}',
  statementDate: DateTime(dueDate.year, dueDate.month - 1, 12),
  dueDate: dueDate,
  totalAmountDue: 1000,
  minimumAmountDue: 100,
  amountPaid: 0,
  status: BillStatus.unpaid,
  updatedAt: DateTime.now().toUtc(),
);

BillEntity _currentCycleBill(String cardId, DateTime dueDate) {
  final now = DateTime.now();
  return BillEntity(
    id: 'current-cycle-bill',
    cardId: cardId,
    cycleMonth:
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}',
    statementDate: DateTime(now.year, now.month, 12),
    dueDate: dueDate,
    totalAmountDue: 1000,
    minimumAmountDue: 100,
    amountPaid: 0,
    status: BillStatus.unpaid,
    updatedAt: DateTime.now().toUtc(),
  );
}

extension on BillEntity {
  BillEntity copyWithPaid() => BillEntity(
    id: id,
    cardId: cardId,
    cycleMonth: cycleMonth,
    statementDate: statementDate,
    dueDate: dueDate,
    totalAmountDue: totalAmountDue,
    minimumAmountDue: minimumAmountDue,
    amountPaid: totalAmountDue,
    status: BillStatus.paid,
    updatedAt: updatedAt,
  );
}
