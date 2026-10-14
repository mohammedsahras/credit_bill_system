import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/repositories/card_repository.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/archive_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/delete_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/get_cards_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/update_card_usecase.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_bloc.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/card_detail_page.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/edit_card_page.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/wallet_home_page.dart';
import 'package:credit_bill_system/features/cards/presentation/widgets/card_gradient_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCardRepository extends Mock implements CardRepository {}

void main() {
  late _MockCardRepository repository;
  final card = CardEntity(
    id: 'active-card',
    bankName: 'Sample Bank',
    nickname: 'Everyday',
    lastFour: '4821',
    network: 'Visa',
    totalLimit: 150000,
    billingDay: 12,
    dueDay: 2,
    colorGradientIdx: 1,
    createdAt: DateTime.utc(2026, 10, 14),
  );

  setUpAll(() {
    registerFallbackValue(card);
  });

  setUp(() {
    repository = _MockCardRepository();
  });

  CardBloc createBloc() => CardBloc(
    getCardsUseCase: GetCardsUseCase(repository),
    addCardUseCase: AddCardUseCase(repository),
    updateCardUseCase: UpdateCardUseCase(repository),
    archiveCardUseCase: ArchiveCardUseCase(repository),
    deleteCardUseCase: DeleteCardUseCase(repository),
  );

  Future<void> openCard(WidgetTester tester, CardBloc bloc) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const WalletHomePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walletCard_0')));
    await tester.pumpAndSettle();
    expect(find.byType(CardDetailPage), findsOneWidget);
  }

  testWidgets('edit form persists active card fields and selected theme', (
    tester,
  ) async {
    final storedCards = [card];
    when(() => repository.getActiveCards()).thenAnswer(
      (_) async =>
          Right(storedCards.where((item) => !item.isArchived).toList()),
    );
    when(() => repository.updateActiveCard(any()))
        .thenAnswer((invocation) async {
          final updated = invocation.positionalArguments.single as CardEntity;
          final index = storedCards.indexWhere((item) => item.id == updated.id);
          storedCards[index] = updated;
          return Right(updated);
        });
    final bloc = createBloc();
    addTearDown(bloc.close);

    await openCard(tester, bloc);
    await tester.tap(find.byKey(const Key('editCardAction')));
    await tester.pumpAndSettle();
    expect(find.byType(EditCardPage), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('editTotalLimitField')),
      '175000',
    );
    await tester.enterText(find.byKey(const Key('editBillingDayField')), '15');
    await tester.enterText(find.byKey(const Key('editDueDayField')), '5');
    await tester.ensureVisible(find.byKey(const Key('editGradientOption_4')));
    await tester.tap(find.byKey(const Key('editGradientOption_4')));
    await tester.ensureVisible(find.byKey(const Key('saveCardChangesButton')));
    await tester.tap(find.byKey(const Key('saveCardChangesButton')));
    await tester.pumpAndSettle();

    expect(find.byType(EditCardPage), findsNothing);
    expect(find.text('₹175,000'), findsOneWidget);
    expect(find.text('Bill: 15th'), findsOneWidget);
    expect(find.text('Due: 5th'), findsOneWidget);
    final faceDecoration =
        tester
                .widget<Container>(find.byKey(const Key('cardDetailFace')))
                .decoration!
            as BoxDecoration;
    expect(faceDecoration.gradient, CardGradientPalette.gradients[4]);
    expect(storedCards.single.id, card.id);
    expect(storedCards.single.totalLimit, 175000);
    expect(storedCards.single.billingDay, 15);
    expect(storedCards.single.dueDay, 5);
    expect(storedCards.single.colorGradientIdx, 4);
    expect(storedCards.single.bankName, card.bankName);
    expect(storedCards.single.nickname, card.nickname);
    expect(storedCards.single.lastFour, card.lastFour);
    expect(storedCards.single.createdAt, card.createdAt);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('COMBINED CREDIT LIMIT'), findsOneWidget);
    expect(find.text('₹175,000'), findsNWidgets(2));
  });

  testWidgets(
    'archive confirmation preserves stored card and refreshes wallet',
    (tester) async {
      final storedCards = [card];
      when(() => repository.getActiveCards()).thenAnswer(
        (_) async =>
            Right(storedCards.where((item) => !item.isArchived).toList()),
      );
      when(() => repository.archiveActiveCard(any()))
          .thenAnswer((invocation) async {
            final id = invocation.positionalArguments.single as String;
            final index = storedCards.indexWhere((item) => item.id == id);
            final activeCard = storedCards[index];
            storedCards[index] = CardEntity(
              id: activeCard.id,
              bankName: activeCard.bankName,
              nickname: activeCard.nickname,
              lastFour: activeCard.lastFour,
              network: activeCard.network,
              totalLimit: activeCard.totalLimit,
              billingDay: activeCard.billingDay,
              dueDay: activeCard.dueDay,
              colorGradientIdx: activeCard.colorGradientIdx,
              isArchived: true,
              createdAt: activeCard.createdAt,
            );
            return const Right(true);
          });
      final bloc = createBloc();
      addTearDown(bloc.close);

      await openCard(tester, bloc);
      await tester.tap(find.byKey(const Key('archiveCardAction')));
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot be restored'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancelArchiveCard')));
      await tester.pumpAndSettle();
      verifyNever(() => repository.archiveActiveCard(any()));

      await tester.tap(find.byKey(const Key('archiveCardAction')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmArchiveCard')));
      await tester.pumpAndSettle();

      expect(storedCards, hasLength(1));
      expect(storedCards.single.isArchived, isTrue);
      expect(find.text('Your Wallet is Empty'), findsOneWidget);
      verify(() => repository.archiveActiveCard(card.id)).called(1);
    },
  );

  testWidgets('archiving a card preserves other active wallet cards', (
    tester,
  ) async {
    final otherCard = CardEntity(
      id: 'other-card',
      bankName: 'Sample Bank',
      nickname: 'Backup',
      lastFour: '7912',
      network: 'Mastercard',
      totalLimit: 90000,
      billingDay: 8,
      dueDay: 18,
      createdAt: DateTime.utc(2026, 10, 15),
    );
    final storedCards = [card, otherCard];
    when(() => repository.getActiveCards()).thenAnswer(
      (_) async =>
          Right(storedCards.where((item) => !item.isArchived).toList()),
    );
    when(() => repository.archiveActiveCard(card.id)).thenAnswer((_) async {
      storedCards[0] = CardEntity(
        id: card.id,
        bankName: card.bankName,
        nickname: card.nickname,
        lastFour: card.lastFour,
        network: card.network,
        totalLimit: card.totalLimit,
        billingDay: card.billingDay,
        dueDay: card.dueDay,
        colorGradientIdx: card.colorGradientIdx,
        isArchived: true,
        createdAt: card.createdAt,
      );
      return const Right(true);
    });
    final bloc = createBloc();
    addTearDown(bloc.close);

    await openCard(tester, bloc);
    await tester.tap(find.byKey(const Key('archiveCardAction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmArchiveCard')));
    await tester.pumpAndSettle();

    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Your Wallet is Empty'), findsNothing);
    expect(storedCards.last.isArchived, isFalse);
  });

  testWidgets(
    'delete dialog names the target and confirmed delete removes it',
    (tester) async {
      final storedCards = [card];
      when(() => repository.getActiveCards()).thenAnswer(
        (_) async =>
            Right(storedCards.where((item) => !item.isArchived).toList()),
      );
      when(() => repository.deleteActiveCard(any()))
          .thenAnswer((invocation) async {
            storedCards.removeWhere(
              (item) => item.id == invocation.positionalArguments.single,
            );
            return const Right(true);
          });
      final bloc = createBloc();
      addTearDown(bloc.close);

      await openCard(tester, bloc);
      await tester.tap(find.byKey(const Key('deleteCardAction')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sample Bank "Everyday"'), findsOneWidget);
      expect(find.textContaining('4821'), findsNWidgets(2));
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancelDeleteCard')));
      await tester.pumpAndSettle();
      verifyNever(() => repository.deleteActiveCard(any()));
      expect(find.byType(CardDetailPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteCardAction')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteCard')));
      await tester.pumpAndSettle();

      expect(storedCards, isEmpty);
      expect(find.text('Your Wallet is Empty'), findsOneWidget);
      verify(() => repository.deleteActiveCard(card.id)).called(1);
    },
  );

  testWidgets('edit form rejects invalid input without repository mutation', (
    tester,
  ) async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    final bloc = createBloc();
    addTearDown(bloc.close);

    await openCard(tester, bloc);
    await tester.tap(find.byKey(const Key('editCardAction')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editTotalLimitField')), 'NaN');
    await tester.enterText(find.byKey(const Key('editDueDayField')), '32');
    await tester.ensureVisible(find.byKey(const Key('saveCardChangesButton')));
    await tester.tap(find.byKey(const Key('saveCardChangesButton')));
    await tester.pumpAndSettle();

    expect(find.text('Credit limit must be greater than zero'), findsOneWidget);
    expect(find.text('Day must be between 1 and 31'), findsOneWidget);
    verifyNever(() => repository.updateActiveCard(any()));
  });

  testWidgets('archive failure keeps card visible and surfaces an error', (
    tester,
  ) async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => repository.archiveActiveCard(card.id)).thenAnswer(
      (_) async => const Left(DatabaseFailure('storage unavailable')),
    );
    final bloc = createBloc();
    addTearDown(bloc.close);

    await openCard(tester, bloc);
    await tester.tap(find.byKey(const Key('archiveCardAction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmArchiveCard')));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailPage), findsOneWidget);
    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('storage unavailable'), findsOneWidget);
  });

  testWidgets('edit failure keeps the prior card and returns to wallet', (
    tester,
  ) async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => repository.updateActiveCard(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('storage unavailable')),
    );
    final bloc = createBloc();
    addTearDown(bloc.close);

    await openCard(tester, bloc);
    await tester.tap(find.byKey(const Key('editCardAction')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('editTotalLimitField')),
      '175000',
    );
    await tester.ensureVisible(find.byKey(const Key('saveCardChangesButton')));
    await tester.tap(find.byKey(const Key('saveCardChangesButton')));
    await tester.pumpAndSettle();

    expect(find.byType(EditCardPage), findsOneWidget);
    expect(find.text('storage unavailable'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CardDetailPage), findsOneWidget);
    expect(find.text('₹150,000'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('Card Wallet'), findsOneWidget);
  });

  testWidgets('delete failure leaves card available and surfaces an error', (
    tester,
  ) async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => Right([card]));
    when(() => repository.deleteActiveCard(card.id)).thenAnswer(
      (_) async => const Left(DatabaseFailure('storage unavailable')),
    );
    final bloc = createBloc();
    addTearDown(bloc.close);

    await openCard(tester, bloc);
    await tester.tap(find.byKey(const Key('deleteCardAction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteCard')));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailPage), findsOneWidget);
    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('storage unavailable'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('Card Wallet'), findsOneWidget);
  });

  testWidgets('unsupported saved theme requires a valid theme before saving', (
    tester,
  ) async {
    final unsupportedCard = CardEntity(
      id: card.id,
      bankName: card.bankName,
      nickname: card.nickname,
      lastFour: card.lastFour,
      network: card.network,
      totalLimit: card.totalLimit,
      billingDay: card.billingDay,
      dueDay: card.dueDay,
      colorGradientIdx: CardGradientPalette.gradients.length,
      createdAt: card.createdAt,
    );
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => Right([unsupportedCard]));
    when(() => repository.updateActiveCard(any()))
        .thenAnswer((invocation) async {
          return Right(invocation.positionalArguments.single as CardEntity);
        });
    final bloc = createBloc();
    addTearDown(bloc.close);

    await openCard(tester, bloc);
    await tester.tap(find.byKey(const Key('editCardAction')));
    await tester.pumpAndSettle();
    expect(
      (tester
                  .widget<Container>(find.byKey(const Key('editCardPreview')))
                  .decoration!
              as BoxDecoration)
          .gradient,
      CardGradientPalette.getGradient(unsupportedCard.colorGradientIdx),
    );
    await tester.ensureVisible(find.byKey(const Key('saveCardChangesButton')));
    await tester.tap(find.byKey(const Key('saveCardChangesButton')));
    await tester.pumpAndSettle();
    expect(find.text('Select a valid card theme.'), findsOneWidget);
    verifyNever(() => repository.updateActiveCard(any()));

    await tester.ensureVisible(find.byKey(const Key('editGradientOption_0')));
    await tester.tap(find.byKey(const Key('editGradientOption_0')));
    await tester.ensureVisible(find.byKey(const Key('saveCardChangesButton')));
    await tester.tap(find.byKey(const Key('saveCardChangesButton')));
    await tester.pumpAndSettle();
    expect(find.byType(EditCardPage), findsNothing);
    verify(() => repository.updateActiveCard(any())).called(1);
  });

  test('use cases pass repository errors through', () async {
    when(() => repository.archiveActiveCard(card.id)).thenAnswer(
      (_) async => const Left(DatabaseFailure('storage unavailable')),
    );
    expect(
      (await ArchiveCardUseCase(repository).execute(card.id)).leftOrNull,
      isA<DatabaseFailure>(),
    );
  });
}
