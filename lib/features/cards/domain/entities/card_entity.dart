import 'package:equatable/equatable.dart';

class CardEntity extends Equatable {
  static const int gradientThemeCount = 5;

  final String id;
  final String bankName;
  final String nickname;
  final String lastFour;
  final String network;
  final double totalLimit;
  final int billingDay;
  final int dueDay;
  final int colorGradientIdx;
  final bool isArchived;
  final DateTime createdAt;

  const CardEntity({
    required this.id,
    required this.bankName,
    required this.nickname,
    required this.lastFour,
    required this.network,
    required this.totalLimit,
    required this.billingDay,
    required this.dueDay,
    this.colorGradientIdx = 0,
    this.isArchived = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    bankName,
    nickname,
    lastFour,
    network,
    totalLimit,
    billingDay,
    dueDay,
    colorGradientIdx,
    isArchived,
    createdAt,
  ];
}
