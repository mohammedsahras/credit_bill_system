import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/database_helper.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/widgets/credit_bill_page_route.dart';
import 'app/presentation/wallet_composition_page.dart';
import 'features/auth/data/datasources/user_local_data_source.dart';
import 'features/auth/data/repositories/user_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/data/datasources/recovery_code_local_data_source.dart';
import 'features/customers/data/datasources/customer_local_data_source.dart';
import 'features/customers/data/datasources/credit_transaction_local_data_source.dart';
import 'features/customers/data/datasources/payment_local_data_source.dart';
import 'features/customers/data/repositories/customer_repository_impl.dart';
import 'features/customers/data/repositories/credit_transaction_repository_impl.dart';
import 'features/customers/data/repositories/payment_repository_impl.dart';
import 'features/customers/domain/usecases/customer_usecases.dart';
import 'features/customers/presentation/bloc/customer_bloc.dart';
import 'features/customers/presentation/bloc/customer_detail_bloc.dart';
import 'features/customers/presentation/pages/add_credit_bill_page.dart';
import 'features/customers/presentation/pages/add_customer_page.dart';
import 'features/customers/presentation/pages/customer_detail_page.dart';
import 'features/customers/presentation/pages/customer_list_page.dart';
import 'features/reports/presentation/pages/reports_page.dart';
import 'features/reports/presentation/bloc/reports_bloc.dart';
import 'features/settings/presentation/pages/about_page.dart';
import 'features/settings/presentation/pages/edit_profile_page.dart';
import 'features/settings/presentation/pages/help_support_page.dart';
import 'features/settings/presentation/pages/security_privacy_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/pages/storage_data_page.dart';
import 'features/settings/presentation/pages/theme_settings_page.dart';
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

  /// App-wide theme-mode control. `main()` loads the persisted value
  /// before the first frame; tests may inject one backed by a fake store.
  final ThemeController? themeController;

  const CreditBillApp({
    super.key,
    this.databaseHelper,
    this.home,
    this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    final dbHelper = databaseHelper ?? DatabaseHelper();
    final themeController = this.themeController ?? ThemeController();
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
    final creditTransactionLocalDataSource =
        CreditTransactionLocalDataSourceImpl(databaseHelper: dbHelper);
    final creditTransactionRepository = CreditTransactionRepositoryImpl(
      localDataSource: creditTransactionLocalDataSource,
    );
    final paymentLocalDataSource = PaymentLocalDataSourceImpl(
      databaseHelper: dbHelper,
    );
    final paymentRepository = PaymentRepositoryImpl(
      localDataSource: paymentLocalDataSource,
      databaseHelper: dbHelper,
    );
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
    final getProfileUseCase = GetProfileUseCase(repository: userRepository);
    final updateProfileUseCase = UpdateProfileUseCase(
      repository: userRepository,
    );
    final changePasswordUseCase = ChangePasswordUseCase(
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
            updateProfileUseCase: updateProfileUseCase,
            recoveryCodeDataSource: RecoveryCodeLocalDataSourceImpl(
              databaseHelper: DatabaseHelper(),
            ),
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
        BlocProvider<CustomerDetailBloc>(
          create: (_) => CustomerDetailBloc(
            getCustomerByIdUseCase: GetCustomerByIdUseCase(
              repository: customerRepository,
            ),
            creditTransactionRepository: creditTransactionRepository,
            paymentRepository: paymentRepository,
          ),
        ),
        BlocProvider<ReportsBloc>(
          create: (_) => ReportsBloc(databaseHelper: dbHelper),
        ),
      ],
      child: ThemeScope(
        controller: themeController,
        child: ListenableBuilder(
          listenable: themeController,
          builder: (context, _) => MaterialApp(
            title: 'Credit Bill System',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.mode,
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
                  return CreditBillPageRoute(
                    builder: (_) => const CustomerListPage(),
                  );
                case '/add-customer':
                  return CreditBillPageRoute(
                    builder: (_) => const AddCustomerPage(),
                  );
                case '/customer-detail':
                  final customer = settings.arguments as CustomerEntity?;
                  if (customer == null) return null;
                  return CreditBillPageRoute(
                    builder: (_) => CustomerDetailPage(customer: customer),
                  );
                case '/edit-customer':
                  final customer = settings.arguments as CustomerEntity?;
                  if (customer == null) return null;
                  return CreditBillPageRoute(
                    builder: (_) => EditCustomerPage(customer: customer),
                  );
                case '/add-credit-bill':
                  final customer = settings.arguments as CustomerEntity?;
                  return CreditBillPageRoute(
                    builder: (_) => AddCreditBillPage(customer: customer),
                  );
                case '/record-payment':
                  final customer = settings.arguments as CustomerEntity?;
                  return CreditBillPageRoute(
                    builder: (_) => RecordPaymentPage(
                      customer: customer,
                      paymentRepository: paymentRepository,
                      creditTransactionRepository: creditTransactionRepository,
                    ),
                  );
                case '/dashboard':
                  return CreditBillPageRoute(
                    builder: (_) => const DashboardPage(),
                  );
                case '/reports':
                  return CreditBillPageRoute(builder: (_) => const ReportsPage());
                case '/settings':
                  return CreditBillPageRoute(
                    builder: (_) =>
                        SettingsPage(getProfileUseCase: getProfileUseCase),
                  );
                case '/edit-profile':
                  return CreditBillPageRoute(
                    builder: (_) =>
                        EditProfilePage(getProfileUseCase: getProfileUseCase),
                  );
                case '/settings/theme':
                  return CreditBillPageRoute(
                    builder: (_) => const ThemeSettingsPage(),
                  );
                case '/settings/security':
                  return CreditBillPageRoute(
                    builder: (_) => SecurityPrivacyPage(
                      changePasswordUseCase: changePasswordUseCase,
                    ),
                  );
                case '/settings/storage':
                  return CreditBillPageRoute(
                    builder: (_) => StorageDataPage(databaseHelper: dbHelper),
                  );
                case '/settings/help':
                  return CreditBillPageRoute(
                    builder: (_) => const HelpSupportPage(),
                  );
                case '/settings/about':
                  return CreditBillPageRoute(builder: (_) => const AboutPage());
                default:
                  return null;
              }
            },
          ),
        ),
      ),
    );
  }
}
