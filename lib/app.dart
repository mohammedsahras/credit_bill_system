import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/database_helper.dart';
import 'app/presentation/wallet_composition_page.dart';
import 'features/auth/data/datasources/user_local_data_source.dart';
import 'features/auth/data/repositories/user_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/customers/data/datasources/customer_local_data_source.dart';
// credit_transaction and payment data sources imported when needed
import 'features/customers/data/repositories/customer_repository_impl.dart';
// credit_transaction_repository_impl and payment_repository_impl imported when needed
import 'features/customers/domain/usecases/customer_usecases.dart';
import 'features/customers/presentation/bloc/customer_bloc.dart';
import 'features/customers/presentation/pages/add_credit_bill_page.dart';
import 'features/customers/presentation/pages/add_customer_page.dart';
import 'features/customers/presentation/pages/customer_detail_page.dart';
import 'features/customers/presentation/pages/customer_list_page.dart';
import 'features/customers/presentation/pages/dashboard_page.dart';
import 'features/customers/presentation/pages/edit_customer_page.dart';
import 'features/customers/presentation/pages/record_payment_page.dart';
import 'features/customers/domain/entities/customer_entity.dart';
import 'features/auth/presentation/pages/create_new_password_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/password_changed_page.dart';
import 'features/auth/presentation/pages/verify_recovery_code_page.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/bills/data/datasources/bill_local_data_source.dart';
import 'features/bills/data/repositories/bill_repository_impl.dart';
import 'features/bills/domain/usecases/get_active_bills_usecase.dart';
import 'features/bills/domain/usecases/save_bill_usecase.dart';
import 'features/bills/presentation/bloc/bill_bloc.dart';
import 'features/cards/data/datasources/card_local_data_source.dart';
import 'features/cards/data/repositories/card_repository_impl.dart';
import 'features/cards/domain/usecases/add_card_usecase.dart';
import 'features/cards/domain/usecases/archive_card_usecase.dart';
import 'features/cards/domain/usecases/delete_card_usecase.dart';
import 'features/cards/domain/usecases/get_cards_usecase.dart';
import 'features/cards/domain/usecases/update_card_usecase.dart';
import 'features/cards/presentation/bloc/card_bloc.dart';

class CreditBillApp extends StatelessWidget {
  final DatabaseHelper? databaseHelper;
  final Widget? home;

  const CreditBillApp({super.key, this.databaseHelper, this.home});

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

    // Authentication wiring (Clean Architecture: Presentation <- Domain <- Data)
    final userLocalDataSource = UserLocalDataSourceImpl(
      databaseHelper: dbHelper,
    );

    // Customer credit management wiring
    final customerLocalDataSource = CustomerLocalDataSourceImpl(
      databaseHelper: dbHelper,
    );
    final customerRepository = CustomerRepositoryImpl(
      localDataSource: customerLocalDataSource,
    );
    // creditTransactionLocalDataSource wired later
    // creditTransactionRepository wired later
    // paymentLocalDataSource wired later
    // paymentRepository wired later
    final getCustomersUseCase = GetCustomersUseCase(
      repository: customerRepository,
    );
    final searchCustomersUseCase = SearchCustomersUseCase(
      repository: customerRepository,
    );
    final addCustomerUseCase = AddCustomerUseCase(
      repository: customerRepository,
    );
    final updateCustomerUseCase = UpdateCustomerUseCase(
      repository: customerRepository,
    );
    final deactivateCustomerUseCase = DeactivateCustomerUseCase(
      repository: customerRepository,
    );
    final userRepository = UserRepositoryImpl(
      localDataSource: userLocalDataSource,
    );
    final loginUseCase = LoginUseCase(repository: userRepository);
    final forgotPasswordUseCase = ForgotPasswordUseCase(
      repository: userRepository,
    );
    final resetPasswordUseCase = ResetPasswordUseCase(
      repository: userRepository,
    );
    final seedDefaultUserUseCase = SeedDefaultUserUseCase(
      repository: userRepository,
    );
    final seedDevAccountUseCase = SeedDevAccountUseCase(
      repository: userRepository,
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
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            loginUseCase: loginUseCase,
            forgotPasswordUseCase: forgotPasswordUseCase,
            resetPasswordUseCase: resetPasswordUseCase,
            seedDefaultUserUseCase: seedDefaultUserUseCase,
            seedDevAccountUseCase: seedDevAccountUseCase,
          )..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<CustomerBloc>(
          create: (_) => CustomerBloc(
            getCustomersUseCase: getCustomersUseCase,
            searchCustomersUseCase: searchCustomersUseCase,
            addCustomerUseCase: addCustomerUseCase,
            updateCustomerUseCase: updateCustomerUseCase,
            deactivateCustomerUseCase: deactivateCustomerUseCase,
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
            seedColor: const Color(0xFF087DB5),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF087DB5),
            brightness: Brightness.dark,
          ),
        ),
        home: home ?? const WalletCompositionPage(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/welcome':
              return MaterialPageRoute(builder: (_) => const WelcomePage());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/forgot-password':
              return MaterialPageRoute(
                builder: (_) => const ForgotPasswordPage(),
              );
            case '/verify-recovery-code':
              final email = settings.arguments as String? ?? '';
              return MaterialPageRoute(
                builder: (_) => VerifyRecoveryCodePage(email: email),
              );
            case '/create-new-password':
              final args = settings.arguments;
              String email = 'demo@creditbill.com';
              if (args is Map) {
                email = args['email'] as String? ?? email;
              } else if (args is String) {
                email = args;
              }
              return MaterialPageRoute(
                builder: (_) => CreateNewPasswordPage(email: email),
              );
            case '/password-changed':
              return MaterialPageRoute(
                builder: (_) => const PasswordChangedPage(),
              );
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const WalletCompositionPage(),
              );
            case '/customers':
              return MaterialPageRoute(
                builder: (_) => const CustomerListPage(),
              );
            case '/add-customer':
              return MaterialPageRoute(builder: (_) => const AddCustomerPage());
            case '/customer-detail':
              final customer = settings.arguments as CustomerEntity?;
              if (customer == null) return null;
              return MaterialPageRoute(
                builder: (_) => CustomerDetailPage(customer: customer),
              );
            case '/edit-customer':
              final customer = settings.arguments as CustomerEntity?;
              if (customer == null) return null;
              return MaterialPageRoute(
                builder: (_) => EditCustomerPage(customer: customer),
              );
            case '/add-credit-bill':
              final customer = settings.arguments as CustomerEntity?;
              return MaterialPageRoute(
                builder: (_) => AddCreditBillPage(customer: customer),
              );
            case '/record-payment':
              final customer = settings.arguments as CustomerEntity?;
              return MaterialPageRoute(
                builder: (_) => RecordPaymentPage(customer: customer),
              );
            case '/dashboard':
              return MaterialPageRoute(builder: (_) => const DashboardPage());
            default:
              return null;
          }
        },
      ),
    );
  }
}
