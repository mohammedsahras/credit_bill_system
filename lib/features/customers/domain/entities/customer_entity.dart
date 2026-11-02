import 'package:equatable/equatable.dart';

/// Domain entity representing a shop customer who purchases on credit.
class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final DateTime createdAt;
  final bool isActive;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.createdAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, phone, address, createdAt, isActive];
}
