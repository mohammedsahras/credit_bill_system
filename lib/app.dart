import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/database_helper.dart';
import 'features/cards/data/datasources/card_local_data_source.dart';
import 'features/cards/data/repositories/card_repository_impl.dart';
import 'features/cards/domain/usecases/add_card_usecase.dart';
import 'features/cards/domain/usecases/get_cards_usecase.dart';
import 'features/cards/presentation/bloc/card_bloc.dart';
import 'features/cards/presentation/pages/wallet_home_page.dart';

class CreditBillApp extends StatelessWidget {
  final DatabaseHelper? databaseHelper;

  const CreditBillApp({super.key, this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    final dbHelper = databaseHelper ?? DatabaseHelper();
    final cardLocalDataSource = CardLocalDataSourceImpl(databaseHelper: dbHelper);
    final cardRepository = CardRepositoryImpl(localDataSource: cardLocalDataSource);
    final getCardsUseCase = GetCardsUseCase(cardRepository);
    final addCardUseCase = AddCardUseCase(cardRepository);

    return MultiBlocProvider(
      providers: [
        BlocProvider<CardBloc>(
          create: (_) => CardBloc(
            getCardsUseCase: getCardsUseCase,
            addCardUseCase: addCardUseCase,
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
        home: const WalletHomePage(),
      ),
    );
  }
}
