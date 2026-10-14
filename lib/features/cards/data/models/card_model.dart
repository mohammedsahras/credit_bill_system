import '../../domain/entities/card_entity.dart';

class CardModel extends CardEntity {
  const CardModel({
    required super.id,
    required super.bankName,
    required super.nickname,
    required super.lastFour,
    required super.network,
    required super.totalLimit,
    required super.billingDay,
    required super.dueDay,
    super.colorGradientIdx = 0,
    super.isArchived = false,
    required super.createdAt,
  });

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as String,
      bankName: map['bank_name'] as String,
      nickname: map['nickname'] as String,
      lastFour: map['last_four'] as String,
      network: map['network'] as String,
      totalLimit: (map['total_limit'] as num).toDouble(),
      billingDay: map['billing_day'] as int,
      dueDay: map['due_day'] as int,
      colorGradientIdx: (map['color_gradient_idx'] as int?) ?? 0,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank_name': bankName,
      'nickname': nickname,
      'last_four': lastFour,
      'network': network,
      'total_limit': totalLimit,
      'billing_day': billingDay,
      'due_day': dueDay,
      'color_gradient_idx': colorGradientIdx,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CardModel.fromEntity(CardEntity entity) {
    return CardModel(
      id: entity.id,
      bankName: entity.bankName,
      nickname: entity.nickname,
      lastFour: entity.lastFour,
      network: entity.network,
      totalLimit: entity.totalLimit,
      billingDay: entity.billingDay,
      dueDay: entity.dueDay,
      colorGradientIdx: entity.colorGradientIdx,
      isArchived: entity.isArchived,
      createdAt: entity.createdAt,
    );
  }
}
