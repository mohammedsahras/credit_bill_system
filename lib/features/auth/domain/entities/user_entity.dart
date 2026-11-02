import 'package:equatable/equatable.dart';

/// Domain entity representing a registered app user.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String passwordHash;
  final DateTime createdAt;
  final bool isEmailVerified;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.passwordHash,
    required this.createdAt,
    this.isEmailVerified = false,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    passwordHash,
    createdAt,
    isEmailVerified,
  ];
}
