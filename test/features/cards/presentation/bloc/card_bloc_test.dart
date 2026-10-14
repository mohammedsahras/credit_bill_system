import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/add_card_usecase.dart';
import 'package:credit_bill_system/features/cards/domain/usecases/get_cards_usecase.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_bloc.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_event.dart';
import 'package:credit_bill_system/features/cards/presentation/bloc/card_state.dart';

class MockGetCardsUseCase extends Mock implements GetCardsUseCase {}
class MockAddCardUseCase extends Mock implements AddCardUseCase {}

void main() {
  late CardBloc cardBloc;
  late MockGetCardsUseCase mockGetCardsUseCase;
  late MockAddCardUseCase mockAddCardUseCase;

  final testDate = DateTime.parse('2026-10-13T10:00:00Z');
  final testCard = CardEntity(
    id: 'test-1',
    bankName: 'ICICI',
    nickname: 'Amazon Pay',
    lastFour: '1234',
    network: 'Visa',
    totalLimit: 50000.0,
    billingDay: 20,
    dueDay: 10,
    createdAt: testDate,
  );

  setUp(() {
    mockGetCardsUseCase = MockGetCardsUseCase();
    mockAddCardUseCase = MockAddCardUseCase();
    cardBloc = CardBloc(
      getCardsUseCase: mockGetCardsUseCase,
      addCardUseCase: mockAddCardUseCase,
    );
  });

  tearDown(() {
    cardBloc.close();
  });

  group('CardBloc', () {
    test('initial state is CardInitialState', () {
      expect(cardBloc.state, equals(const CardInitialState()));
    });

    blocTest<CardBloc, CardState>(
      'emits [CardLoadingState, CardLoadedState] when LoadCardsEvent succeeds',
      build: () {
        when(() => mockGetCardsUseCase.execute())
            .thenAnswer((_) async => Right([testCard]));
        return cardBloc;
      },
      act: (bloc) => bloc.add(const LoadCardsEvent()),
      expect: () => [
        const CardLoadingState(),
        CardLoadedState([testCard]),
      ],
      verify: (_) {
        verify(() => mockGetCardsUseCase.execute()).called(1);
      },
    );

    blocTest<CardBloc, CardState>(
      'emits [CardLoadingState, CardErrorState] when LoadCardsEvent fails',
      build: () {
        when(() => mockGetCardsUseCase.execute())
            .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));
        return cardBloc;
      },
      act: (bloc) => bloc.add(const LoadCardsEvent()),
      expect: () => [
        const CardLoadingState(),
        const CardErrorState('DB error'),
      ],
    );

    blocTest<CardBloc, CardState>(
      'emits [CardLoadingState, CardAddedSuccessState, CardLoadingState, CardLoadedState] on AddCardEvent success',
      build: () {
        when(() => mockAddCardUseCase.execute(testCard))
            .thenAnswer((_) async => Right(testCard));
        when(() => mockGetCardsUseCase.execute())
            .thenAnswer((_) async => Right([testCard]));
        return cardBloc;
      },
      act: (bloc) => bloc.add(AddCardEvent(testCard)),
      expect: () => [
        const CardLoadingState(),
        CardAddedSuccessState(testCard),
        const CardLoadingState(),
        CardLoadedState([testCard]),
      ],
    );
  });
}
