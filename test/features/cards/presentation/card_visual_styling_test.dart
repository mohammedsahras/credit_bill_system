import 'dart:ui' show Tristate;

import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/repositories/card_repository.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/get_cards_usecase.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_bloc.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_event.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/add_card_page.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/card_detail_page.dart';
import 'package:credit_bill_system/features/cards/presentation/pages/wallet_home_page.dart';
import 'package:credit_bill_system/features/cards/presentation/widgets/card_gradient_palette.dart';
import 'package:credit_bill_system/features/cards/presentation/widgets/card_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCardRepository extends Mock implements CardRepository {}

void main() {
  late _MockCardRepository repository;

  setUpAll(() {
    registerFallbackValue(
      CardEntity(
        id: 'fallback-card',
        bankName: 'Fallback',
        nickname: 'Fallback',
        lastFour: '0000',
        network: 'Visa',
        totalLimit: 1,
        billingDay: 1,
        dueDay: 1,
        createdAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    repository = _MockCardRepository();
  });

  CardEntity card({
    String id = 'card-1',
    String nickname = 'Travel Card',
    String network = 'Visa',
    int gradientIndex = 2,
  }) {
    return CardEntity(
      id: id,
      bankName: 'Sample Bank',
      nickname: nickname,
      lastFour: '4821',
      network: network,
      totalLimit: 150000,
      billingDay: 12,
      dueDay: 2,
      colorGradientIdx: gradientIndex,
      createdAt: DateTime.utc(2026, 10, 14),
    );
  }

  CardBloc createBloc() => CardBloc(
    getCardsUseCase: GetCardsUseCase(repository),
    addCardUseCase: AddCardUseCase(repository),
  );

  testWidgets('theme selection updates the creation preview immediately', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final bloc = createBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const AddCardPage()),
      ),
    );

    expect(CardGradientPalette.themeNames, hasLength(5));
    expect(
      tester
              .getSemantics(find.byKey(const Key('gradientOption_0')))
              .getSemanticsData()
              .flagsCollection
              .isSelected ==
          Tristate.isTrue,
      isTrue,
    );
    expect(find.byKey(const Key('cardPreview')), findsOneWidget);
    expect(
      tester.widget<Container>(find.byKey(const Key('cardPreview'))).decoration,
      isA<BoxDecoration>().having(
        (decoration) => decoration.gradient,
        'gradient',
        CardGradientPalette.gradients[0],
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('gradientOption_3')));
    await tester.tap(find.byKey(const Key('gradientOption_3')));
    await tester.pump();

    expect(find.text('Emerald Jade'), findsOneWidget);
    expect(
      tester
              .getSemantics(find.byKey(const Key('gradientOption_3')))
              .getSemanticsData()
              .flagsCollection
              .isSelected ==
          Tristate.isTrue,
      isTrue,
    );
    expect(
      tester.widget<Container>(find.byKey(const Key('cardPreview'))).decoration,
      isA<BoxDecoration>().having(
        (decoration) => decoration.gradient,
        'gradient',
        CardGradientPalette.gradients[3],
      ),
    );
    semantics.dispose();
  });

  testWidgets('selected predefined theme is submitted with the new card', (
    tester,
  ) async {
    when(() => repository.addCard(any())).thenAnswer((invocation) async {
      final card = invocation.positionalArguments.single as CardEntity;
      return Right(card);
    });
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => const Right([]));

    final bloc = createBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const AddCardPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('bankNameField')),
      'Sample Bank',
    );
    await tester.enterText(find.byKey(const Key('nicknameField')), 'Everyday');
    await tester.enterText(find.byKey(const Key('lastFourField')), '4821');
    await tester.enterText(find.byKey(const Key('totalLimitField')), '150000');
    await tester.enterText(find.byKey(const Key('billingDayField')), '12');
    await tester.enterText(find.byKey(const Key('dueDayField')), '2');
    await tester.ensureVisible(find.byKey(const Key('gradientOption_3')));
    await tester.tap(find.byKey(const Key('gradientOption_3')));
    await tester.ensureVisible(find.byKey(const Key('saveCardButton')));
    await tester.tap(find.byKey(const Key('saveCardButton')));
    await tester.pumpAndSettle();

    final submittedCard =
        verify(() => repository.addCard(captureAny())).captured.single
            as CardEntity;
    expect(submittedCard.colorGradientIdx, 3);
  });

  testWidgets('wallet carousel opens a styled card detail view', (
    tester,
  ) async {
    when(() => repository.getActiveCards()).thenAnswer(
      (_) async => Right(
        List.generate(
          80,
          (index) => card(
            id: 'card-$index',
            nickname: index == 1 ? 'Everyday Card' : 'Travel Card $index',
            network: index == 1 ? 'Mastercard' : 'Visa',
            gradientIndex: index == 1 ? 4 : 2,
          ),
        ),
      ),
    );
    final bloc = createBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const WalletHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const PageStorageKey<String>('walletCardCarousel')),
      findsOneWidget,
    );
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Travel Card 0'), findsOneWidget);
    expect(
      tester.widget<Container>(find.byKey(const Key('cardFace'))).decoration,
      isA<BoxDecoration>().having(
        (decoration) => decoration.gradient,
        'gradient',
        CardGradientPalette.gradients[2],
      ),
    );

    await tester.drag(
      find.byKey(const PageStorageKey<String>('walletCardCarousel')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Everyday Card'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('walletPageIndicator_1'))).width,
      28,
    );
    expect(tester.takeException(), isNull);

    bloc.add(const LoadCardsEvent());
    await tester.pumpAndSettle();
    expect(find.text('Everyday Card'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('walletPageIndicator_1'))).width,
      28,
    );
    expect(
      tester.getSize(find.byKey(const Key('walletPageIndicator_0'))).width,
      16,
    );

    await tester.ensureVisible(find.byKey(const Key('walletCard_1')));
    await tester.tap(find.byKey(const Key('walletCard_1')));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailPage), findsOneWidget);
    expect(find.byIcon(Icons.account_balance), findsOneWidget);
    expect(find.text('MASTERCARD'), findsOneWidget);
    expect(find.text('Everyday Card'), findsOneWidget);
    expect(
      tester
          .widget<Container>(find.byKey(const Key('cardDetailFace')))
          .decoration,
      isA<BoxDecoration>().having(
        (decoration) => decoration.gradient,
        'gradient',
        CardGradientPalette.gradients[4],
      ),
    );
    expect(
      tester
          .widget<CardDetailPage>(find.byType(CardDetailPage))
          .card
          .colorGradientIdx,
      4,
    );
  });

  testWidgets('unsupported theme uses the safe palette fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CardItemWidget(card: card(gradientIndex: 999))),
      ),
    );

    expect(
      tester.widget<Container>(find.byKey(const Key('cardFace'))).decoration,
      isA<BoxDecoration>().having(
        (decoration) => decoration.gradient,
        'gradient',
        CardGradientPalette.gradients[0],
      ),
    );
    expect(find.byIcon(Icons.account_balance), findsOneWidget);
    expect(find.text('VISA'), findsOneWidget);
  });

  testWidgets('long network badge is constrained to card width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 560,
              child: CardItemWidget(
                card: card(
                  network: 'International Premium Corporate Card Network Name',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
