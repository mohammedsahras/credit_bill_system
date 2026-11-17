import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LoginRequestedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginRequestedEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class ForgotPasswordRequestedEvent extends AuthEvent {
  final String email;

  const ForgotPasswordRequestedEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequestedEvent extends AuthEvent {
  final String email;
  final String newPassword;

  const ResetPasswordRequestedEvent({
    required this.email,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, newPassword];
}

class LogoutRequestedEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  /// Email the profile row is currently stored under.
  final String currentEmail;

  final String fullName;
  final String email;
  final String? phone;
  final String? photo;

  /// Required only when [email] differs from [currentEmail]; verified
  /// against the stored password hash before anything is written.
  final String? currentPassword;

  const UpdateProfileEvent({
    required this.currentEmail,
    required this.fullName,
    required this.email,
    this.phone,
    this.photo,
    this.currentPassword,
  });

  @override
  List<Object?> get props => [
    currentEmail,
    fullName,
    email,
    phone,
    photo,
    currentPassword,
  ];
}
