import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthAuthenticatedState extends AuthState {
  final String email;
  final String fullName;

  const AuthAuthenticatedState({required this.email, required this.fullName});

  @override
  List<Object?> get props => [email, fullName];
}

class AuthUnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthSuccessState extends AuthState {
  final String message;

  const AuthSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}

/// A profile update succeeded: the session was re-saved and the identity
/// below reflects the persisted values.
///
/// Extends [AuthAuthenticatedState] so the app root (AuthWrapper) keeps the
/// dashboard mounted instead of falling back to the welcome screen, and
/// carries [updatedAt] so every save surfaces as a distinct emission even
/// when name/email happen to be unchanged (e.g. a phone-only edit).
class AuthProfileUpdatedState extends AuthAuthenticatedState {
  final String message;
  final DateTime updatedAt;

  const AuthProfileUpdatedState({
    required super.email,
    required super.fullName,
    required this.message,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [email, fullName, message, updatedAt];
}

/// A profile update was rejected (validation, wrong password, duplicate
/// email, storage error).
///
/// Typed error state that intentionally still extends
/// [AuthAuthenticatedState]: the signed-in session and database row are
/// untouched, so the user must stay signed in on the screen they are on.
class AuthProfileUpdateFailedState extends AuthAuthenticatedState {
  final String message;
  final DateTime failedAt;

  const AuthProfileUpdateFailedState({
    required super.email,
    required super.fullName,
    required this.message,
    required this.failedAt,
  });

  @override
  List<Object?> get props => [email, fullName, message, failedAt];
}
