import 'package:credit_bill_system/features/auth/domain/entities/user_entity.dart';

/// Data model for a registered user, mapped to/from SQLite.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.passwordHash,
    required super.createdAt,
    super.isEmailVerified = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isEmailVerified: (map['is_email_verified'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'is_email_verified': isEmailVerified ? 1 : 0,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      passwordHash: entity.passwordHash,
      createdAt: entity.createdAt,
      isEmailVerified: entity.isEmailVerified,
    );
  }
}
