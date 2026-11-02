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
