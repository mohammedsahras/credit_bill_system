import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/database_helper.dart';
import 'app/presentation/wallet_composition_page.dart';
import 'features/cards/data/datasources/card_local_data_source.dart';
import 'features/cards/data/repositories/card_repository_impl.dart';
import 'features/cards/domain/usecases/add_card_usecase.dart';
import 'features/cards/domain/usecases/archive_card_usecase.dart';
import 'features/cards/domain/usecases/delete_card_usecase.dart';
import 'features/cards/domain/usecases/get_cards_usecase.dart';
import 'features/cards/domain/usecases/update_card_usecase.dart';
import 'features/cards/presentation/bloc/card_bloc.dart';
import 'features/bills/data/datasources/bill_local_data_source.dart';
import 'features/bills/data/repositories/bill_repository_impl.dart';
import 'features/bills/domain/usecases/get_active_bills_usecase.dart';
import 'features/bills/domain/usecases/save_bill_usecase.dart';
import 'features/bills/presentation/bloc/bill_bloc.dart';

class CreditBillApp extends StatelessWidget {
  final DatabaseHelper? databaseHelper;

  const CreditBillApp({super.key, this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    final dbHelper = databaseHelper ?? DatabaseHelper();
    final cardLocalDataSource = CardLocalDataSourceImpl(
      databaseHelper: dbHelper,
    );
    final cardRepository = CardRepositoryImpl(
      localDataSource: cardLocalDataSource,
    );
    final getCardsUseCase = GetCardsUseCase(cardRepository);
    final addCardUseCase = AddCardUseCase(cardRepository);
    final updateCardUseCase = UpdateCardUseCase(cardRepository);
    final archiveCardUseCase = ArchiveCardUseCase(cardRepository);
    final deleteCardUseCase = DeleteCardUseCase(cardRepository);
    final billLocalDataSource = BillLocalDataSourceImpl(
      databaseHelper: dbHelper,
    );
    final billRepository = BillRepositoryImpl(
      localDataSource: billLocalDataSource,
    );
    final getActiveBillsUseCase = GetActiveBillsUseCase(billRepository);
    final saveBillUseCase = SaveBillUseCase(
      billRepository: billRepository,
      cardRepository: cardRepository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<CardBloc>(
          create: (_) => CardBloc(
            getCardsUseCase: getCardsUseCase,
            addCardUseCase: addCardUseCase,
            updateCardUseCase: updateCardUseCase,
            archiveCardUseCase: archiveCardUseCase,
            deleteCardUseCase: deleteCardUseCase,
          ),
        ),
        BlocProvider<BillBloc>(
          create: (_) => BillBloc(
            getActiveBillsUseCase: getActiveBillsUseCase,
            saveBillUseCase: saveBillUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Credit Bill System',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.dark,
          ),
        ),
        home: const WalletCompositionPage(),
      ),
    );
  }
}
