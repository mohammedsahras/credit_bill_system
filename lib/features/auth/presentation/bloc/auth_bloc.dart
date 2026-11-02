import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/session_manager.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SeedDefaultUserUseCase seedDefaultUserUseCase;
  final SeedDevAccountUseCase seedDevAccountUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.seedDefaultUserUseCase,
    required this.seedDevAccountUseCase,
  }) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<ForgotPasswordRequestedEvent>(_onForgotPasswordRequested);
    on<ResetPasswordRequestedEvent>(_onResetPasswordRequested);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await seedDefaultUserUseCase.execute();
      await seedDevAccountUseCase.execute();
    } catch (_) {
      // Ignore seeding errors (e.g., in test environments without users table)
    }

    // Check for existing session
    final session = await SessionManager.getSession();
    if (session != null) {
      emit(
        AuthAuthenticatedState(
          email: session['email']!,
          fullName: session['fullName'] ?? '',
        ),
      );
    } else {
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    final result = await loginUseCase.execute(
      email: event.email,
      password: event.password,
    );
    result.fold((failure) => emit(AuthErrorState(failure.message)), (
      user,
    ) async {
      await SessionManager.saveSession(
        email: user.email,
        fullName: user.fullName,
      );
      emit(AuthAuthenticatedState(email: user.email, fullName: user.fullName));
    });
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    final result = await forgotPasswordUseCase.execute(email: event.email);
    result.fold((failure) => emit(AuthErrorState(failure.message)), (user) {
      if (user == null) {
        emit(AuthErrorState('No account found with this email.'));
      } else {
        emit(
          AuthSuccessState(
            'A password reset link has been sent to ${user.email}.',
          ),
        );
      }
    });
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    final result = await resetPasswordUseCase.execute(
      email: event.email,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (_) => emit(AuthSuccessState('Your password has been changed.')),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    await SessionManager.clearSession();
    emit(AuthUnauthenticatedState());
  }
}
