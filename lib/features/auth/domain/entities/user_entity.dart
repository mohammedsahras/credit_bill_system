import 'package:equatable/equatable.dart';

/// Domain entity representing a registered app user.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String passwordHash;
  final DateTime createdAt;
  final bool isEmailVerified;

  /// Optional mobile number. Nullable — added by the v6 profile migration,
  /// so pre-existing accounts simply have no phone yet.
  final String? phone;

  /// Optional profile photo stored as a resized base64 string.
  /// Nullable for the same reason as [phone].
  final String? photo;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.passwordHash,
    required this.createdAt,
    this.isEmailVerified = false,
    this.phone,
    this.photo,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    passwordHash,
    createdAt,
    isEmailVerified,
    phone,
    photo,
  ];
}
