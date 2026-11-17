import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/session_manager.dart';
import '../../data/datasources/recovery_code_local_data_source.dart';
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
  final UpdateProfileUseCase updateProfileUseCase;
  final RecoveryCodeLocalDataSource recoveryCodeDataSource;

  AuthBloc({
    required this.loginUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.seedDefaultUserUseCase,
    required this.seedDevAccountUseCase,
    required this.updateProfileUseCase,
    required this.recoveryCodeDataSource,
  }) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<ForgotPasswordRequestedEvent>(_onForgotPasswordRequested);
    on<ResetPasswordRequestedEvent>(_onResetPasswordRequested);
    on<UpdateProfileEvent>(_onUpdateProfile);
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
    } catch (e, stackTrace) {
      // Log seeding failures for diagnostics; never log credentials.
      debugPrint('Auth seeding failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    // Check for existing session
    try {
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
    } catch (_) {
      // Session check failure should not block the app.
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final result = await loginUseCase.execute(
        email: event.email,
        password: event.password,
      );
      if (result.isLeft) {
        emit(AuthErrorState(result.leftOrNull!.message));
        return;
      }
      final user = result.rightOrNull!;
      // Session save may fail on Web; it must never block authentication.
      try {
        await SessionManager.saveSession(
          email: user.email,
          fullName: user.fullName,
        );
      } catch (e) {
        debugPrint('Session save failed (non-blocking): $e');
      }
      emit(AuthAuthenticatedState(email: user.email, fullName: user.fullName));
    } catch (e) {
      emit(AuthErrorState('Login failed: $e'));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final result = await forgotPasswordUseCase.execute(email: event.email);
      if (result.isLeft) {
        emit(AuthErrorState(result.leftOrNull!.message));
        return;
      }
      final user = result.rightOrNull;
      try {
        final safeEmail = user?.email ?? 'unknown@example.com';
        await recoveryCodeDataSource.generateAndStoreCode(safeEmail);
        emit(
          AuthSuccessState(
            'A recovery code has been generated for $safeEmail. '
            'Check your recovery code screen to reset your password.',
          ),
        );
      } catch (e) {
        emit(AuthErrorState('Failed to generate recovery code: $e'));
      }
    } catch (e) {
      emit(AuthErrorState('Password recovery failed: $e'));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final result = await resetPasswordUseCase.execute(
        email: event.email,
        newPassword: event.newPassword,
      );
      if (result.isLeft) {
        emit(AuthErrorState(result.leftOrNull!.message));
        return;
      }
      emit(AuthSuccessState('Your password has been changed.'));
    } catch (e) {
      emit(AuthErrorState('Password reset failed: $e'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Note: no AuthLoadingState here. The edit screen manages its own
    // saving indicator, and a transient non-authenticated state would make
    // the app root (AuthWrapper) drop back to the welcome screen.
    try {
      final result = await updateProfileUseCase.execute(
        currentEmail: event.currentEmail,
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        photo: event.photo,
        currentPassword: event.currentPassword,
      );
      if (result.isLeft) {
        final identity = _identityAfterFailure(event);
        emit(
          AuthProfileUpdateFailedState(
            email: identity.email,
            fullName: identity.fullName,
            message: result.leftOrNull!.message,
            failedAt: DateTime.now(),
          ),
        );
        return;
      }

      final user = result.rightOrNull!;
      // Session save may fail on Web; it must never block the update.
      try {
        await SessionManager.saveSession(
          email: user.email,
          fullName: user.fullName,
        );
      } catch (e) {
        debugPrint('Session save failed (non-blocking): $e');
      }
      emit(
        AuthProfileUpdatedState(
          email: user.email,
          fullName: user.fullName,
          message: 'Your profile has been updated.',
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      final identity = _identityAfterFailure(event);
      emit(
        AuthProfileUpdateFailedState(
          email: identity.email,
          fullName: identity.fullName,
          message: 'Profile update failed: $e',
          failedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Identity to report on a failed update: the last confirmed session
  /// values (a failed save never changes them), falling back to the values
  /// the event was built from when nothing has been confirmed yet.
  ({String email, String fullName}) _identityAfterFailure(
    UpdateProfileEvent event,
  ) {
    final current = state;
    if (current is AuthAuthenticatedState) {
      return (email: current.email, fullName: current.fullName);
    }
    return (email: event.currentEmail, fullName: event.fullName);
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await SessionManager.clearSession();
    } catch (e) {
      debugPrint('Session clear failed (non-blocking): $e');
    }
    emit(AuthUnauthenticatedState());
  }
}
