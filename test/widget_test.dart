import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/database/database_helper.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/repositories/card_repository.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/archive_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/delete_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/get_cards_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/update_card_usecase.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_bloc.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/wallet_home_page.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/add_card_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:credit_bill_system/app.dart';

class MockCardRepository extends Mock implements CardRepository {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockCardRepository mockCardRepository;
  late GetCardsUseCase getCardsUseCase;
  late AddCardUseCase addCardUseCase;

  setUpAll(() {
    registerFallbackValue(
      CardEntity(
        id: 'fallback',
        bankName: 'Bank',
        nickname: 'Nick',
        lastFour: '0000',
        network: 'Visa',
        totalLimit: 1000,
        billingDay: 1,
        dueDay: 1,
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockCardRepository = MockCardRepository();
    getCardsUseCase = GetCardsUseCase(mockCardRepository);
    addCardUseCase = AddCardUseCase(mockCardRepository);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<CardBloc>(
        create: (_) => CardBloc(
          getCardsUseCase: getCardsUseCase,
          addCardUseCase: addCardUseCase,
          updateCardUseCase: UpdateCardUseCase(mockCardRepository),
          archiveCardUseCase: ArchiveCardUseCase(mockCardRepository),
          deleteCardUseCase: DeleteCardUseCase(mockCardRepository),
        ),
        child: const WalletHomePage(),
      ),
    );
  }

  testWidgets('shows empty wallet UI when no cards exist', (tester) async {
    when(() => mockCardRepository.getActiveCards())
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Your Wallet is Empty'), findsOneWidget);
    expect(find.text('Add Your First Card'), findsOneWidget);
    expect(find.byKey(const Key('fabAddCard')), findsOneWidget);
  });

  testWidgets(
    'AddCardPage enforces validation: requires 4 digits and limit > 0',
    (tester) async {
      when(() => mockCardRepository.getActiveCards())
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Add Card FAB
      await tester.tap(find.byKey(const Key('fabAddCard')));
      await tester.pumpAndSettle();

      expect(find.byType(AddCardPage), findsOneWidget);

      // Scroll to and tap Save without entering data
      await tester.ensureVisible(find.byKey(const Key('saveCardButton')));
      await tester.tap(find.byKey(const Key('saveCardButton')));
      await tester.pumpAndSettle();

      expect(find.text('Bank name cannot be empty.'), findsOneWidget);
      expect(find.text('Card nickname cannot be empty.'), findsOneWidget);
      expect(find.text('Must be exactly 4 digits'), findsOneWidget);
      expect(find.text('Credit limit is required.'), findsOneWidget);

      // Verify CVV and full card number fields do not exist
      expect(find.text('CVV'), findsNothing);
      expect(find.text('CVC'), findsNothing);
      expect(find.text('Card Number'), findsNothing);
    },
  );

  testWidgets('AddCardPage shows the specified errors for invalid card data', (
    tester,
  ) async {
    when(() => mockCardRepository.getActiveCards())
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fabAddCard')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('bankNameField')), 'HDFC');
    await tester.enterText(find.byKey(const Key('nicknameField')), 'Millennia');
    await tester.enterText(find.byKey(const Key('lastFourField')), '482');
    await tester.enterText(find.byKey(const Key('totalLimitField')), '0');
    await tester.enterText(find.byKey(const Key('billingDayField')), '32');
    await tester.enterText(find.byKey(const Key('dueDayField')), '0');
    await tester.ensureVisible(find.byKey(const Key('saveCardButton')));
    await tester.tap(find.byKey(const Key('saveCardButton')));
    await tester.pumpAndSettle();

    expect(find.text('Must be exactly 4 digits'), findsOneWidget);
    expect(find.text('Credit limit must be greater than zero'), findsOneWidget);
    expect(find.text('Day must be between 1 and 31'), findsNWidgets(2));
    verifyNever(() => mockCardRepository.addCard(any()));
  });

  testWidgets(
    'valid card submission returns to wallet and displays saved card',
    (tester) async {
      final cards = <CardEntity>[];
      when(() => mockCardRepository.getActiveCards())
          .thenAnswer((_) async => Right(cards));
      when(() => mockCardRepository.addCard(any()))
          .thenAnswer((invocation) async {
            final card = invocation.positionalArguments.single as CardEntity;
            cards.add(card);
            return Right(card);
          });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fabAddCard')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('bankNameField')), 'HDFC');
      await tester.enterText(
        find.byKey(const Key('nicknameField')),
        'Millennia',
      );
      await tester.enterText(find.byKey(const Key('lastFourField')), '4821');
      await tester.enterText(
        find.byKey(const Key('totalLimitField')),
        '150000',
      );
      await tester.enterText(find.byKey(const Key('billingDayField')), '12');
      await tester.enterText(find.byKey(const Key('dueDayField')), '2');
      await tester.ensureVisible(find.byKey(const Key('saveCardButton')));
      await tester.tap(find.byKey(const Key('saveCardButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddCardPage), findsNothing);
      expect(find.text('Millennia'), findsOneWidget);
      expect(find.text('HDFC'), findsOneWidget);
      expect(cards, hasLength(1));
      expect(
        cards.single.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    },
  );

  testWidgets(
    'production app wiring persists a valid card and displays it in wallet',
    (tester) async {
      final database = MockDatabase();
      final databaseHelper = DatabaseHelper(database: database);
      final storedCards = <Map<String, Object?>>[];

      when(
        () => database.query(
          DatabaseHelper.tableCards,
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          orderBy: any(named: 'orderBy'),
        ),
      ).thenAnswer((_) async => List.of(storedCards));
      when(
        () => database.insert(
          DatabaseHelper.tableCards,
          any(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).thenAnswer((invocation) async {
        final values =
            invocation.positionalArguments[1] as Map<String, Object?>;
        storedCards.add(Map.of(values));
        return 1;
      });

      await tester.pumpWidget(CreditBillApp(databaseHelper: databaseHelper));
      await tester.pumpAndSettle();
      expect(find.text('Your Wallet is Empty'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fabAddCard')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('bankNameField')), 'HDFC');
      await tester.enterText(
        find.byKey(const Key('nicknameField')),
        'Millennia',
      );
      await tester.enterText(find.byKey(const Key('lastFourField')), '4821');
      await tester.enterText(
        find.byKey(const Key('totalLimitField')),
        '150000',
      );
      await tester.enterText(find.byKey(const Key('billingDayField')), '12');
      await tester.enterText(find.byKey(const Key('dueDayField')), '2');
      await tester.ensureVisible(find.byKey(const Key('saveCardButton')));
      await tester.tap(find.byKey(const Key('saveCardButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddCardPage), findsNothing);
      expect(find.text('Millennia'), findsOneWidget);
      expect(find.text('HDFC'), findsOneWidget);
      expect(storedCards, hasLength(1));
    },
  );
}
