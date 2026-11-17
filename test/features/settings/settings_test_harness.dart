import 'dart:io';

import 'package:credit_bill_system/core/errors/either.dart';
import 'package:credit_bill_system/core/errors/failures.dart';
import 'package:credit_bill_system/core/services/preferences_store.dart';
import 'package:credit_bill_system/core/utils/password_hasher.dart';
import 'package:credit_bill_system/features/auth/data/datasources/recovery_code_local_data_source.dart';
import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';
import 'package:credit_bill_system/features/auth/domain/usecases/auth_usecases.dart';
import 'package:credit_bill_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

class MockSeedDefaultUserUseCase extends Mock
    implements SeedDefaultUserUseCase {}

class MockSeedDevAccountUseCase extends Mock implements SeedDevAccountUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockChangePasswordUseCase extends Mock implements ChangePasswordUseCase {}

/// In-memory [PreferencesStore] for widget tests: the pages only need the
/// read/write round trip, while real file persistence is covered by the
/// theme-controller unit tests.
class FakePreferencesStore extends Fake implements PreferencesStore {
  ThemeMode? savedMode;

  @override
  Future<ThemeMode> loadThemeMode() async => savedMode ?? ThemeMode.system;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async => savedMode = mode;
}

class MockRecoveryCodeLocalDataSource extends Mock
    implements RecoveryCodeLocalDataSource {}

/// The settings pages' vertical list [Scrollable].
///
/// Pass this as `scrollable:` to `scrollUntilVisible`. The default
/// `find.byType(Scrollable)` matches every single-line [TextField] as well
/// (each hosts its own horizontal scrollable), which makes
/// `scrollUntilVisible` throw `Bad state: Too many elements`.
final Finder pageScrollable = find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axis == Axis.vertical,
);

/// path_provider's method channel is unanswered inside widget tests, so an
/// unmocked [SessionManager.saveSession] (the auth bloc awaits it before
/// emitting any post-login/profile state) would hang forever and stall every
/// `pumpAndSettle`. Answer it with the system temp directory instead.
const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void mockPathProvider() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, (call) async {
    return Directory.systemTemp.path;
  });
}

/// A stored profile used across the settings widget tests.
UserEntity sampleUser({
  String id = 'user-0001',
  String email = 'ada@example.com',
  String fullName = 'Ada Lovelace',
  String? phone = '+94 77 123 4567',
  String? photo,
  bool isEmailVerified = true,
  DateTime? createdAt,
}) {
  return UserEntity(
    id: id,
    email: email,
    fullName: fullName,
    passwordHash: PasswordHasher.hash('Secret123!'),
    createdAt: createdAt ?? DateTime(2026, 1, 15),
    isEmailVerified: isEmailVerified,
    phone: phone,
    photo: photo,
  );
}

/// Builds an [AuthBloc] that has already completed a sign-in as [user], so
/// the settings screens can resolve the signed-in email from its state.
///
/// Returns the bloc together with its (mocked) update use case so tests can
/// stub profile saves.
Future<
  ({AuthBloc bloc, MockUpdateProfileUseCase updateProfileUseCase})
>
signedInAuthBloc(UserEntity user) async {
  mockPathProvider();
  final login = MockLoginUseCase();
  when(
    () => login.execute(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => Right<Failure, UserEntity>(user));

  final updateProfile = MockUpdateProfileUseCase();
  final bloc = AuthBloc(
    loginUseCase: login,
    forgotPasswordUseCase: MockForgotPasswordUseCase(),
    resetPasswordUseCase: MockResetPasswordUseCase(),
    seedDefaultUserUseCase: MockSeedDefaultUserUseCase(),
    seedDevAccountUseCase: MockSeedDevAccountUseCase(),
    updateProfileUseCase: updateProfile,
    recoveryCodeDataSource: MockRecoveryCodeLocalDataSource(),
  );

  final signedIn = bloc.stream.firstWhere(
    (state) => state is AuthAuthenticatedState,
  );
  bloc.add(LoginRequestedEvent(email: user.email, password: 'not-checked'));
  await signedIn;
  return (bloc: bloc, updateProfileUseCase: updateProfile);
}
