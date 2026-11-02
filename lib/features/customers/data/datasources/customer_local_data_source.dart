import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/customer_model.dart';

abstract class CustomerLocalDataSource {
  Future<List<CustomerModel>> getActiveCustomers();
  Future<CustomerModel?> getCustomerById(String id);
  Future<List<CustomerModel>> searchCustomers(String query);
  Future<CustomerModel> insertCustomer(CustomerModel customer);
  Future<int> updateCustomer(CustomerModel customer);
  Future<int> deactivateCustomer(String id);
  Future<bool> hasDuplicatePhone(String phone, {String? excludeId});
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final DatabaseHelper databaseHelper;

  CustomerLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<CustomerModel>> getActiveCustomers() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCustomers,
      where: '${DatabaseHelper.columnCustomerIsActive} = ?',
      whereArgs: [1],
      orderBy: '${DatabaseHelper.columnCustomerName} ASC',
    );
    return maps.map((m) => CustomerModel.fromMap(m)).toList();
  }

  @override
  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCustomers,
      where: '${DatabaseHelper.columnCustomerId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return CustomerModel.fromMap(maps.first);
    return null;
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    final db = await databaseHelper.database;
    final lower = '%${query.toLowerCase()}%';
    final maps = await db.query(
      DatabaseHelper.tableCustomers,
      where:
          '${DatabaseHelper.columnCustomerIsActive} = 1 AND (LOWER(${DatabaseHelper.columnCustomerName}) LIKE ? OR ${DatabaseHelper.columnCustomerPhone} LIKE ?)',
      whereArgs: [lower, lower],
      orderBy: '${DatabaseHelper.columnCustomerName} ASC',
    );
    return maps.map((m) => CustomerModel.fromMap(m)).toList();
  }

  @override
  Future<CustomerModel> insertCustomer(CustomerModel customer) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableCustomers,
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return customer;
  }

  @override
  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableCustomers,
      customer.toMap(),
      where: '${DatabaseHelper.columnCustomerId} = ?',
      whereArgs: [customer.id],
    );
  }

  @override
  Future<int> deactivateCustomer(String id) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableCustomers,
      {DatabaseHelper.columnCustomerIsActive: 0},
      where: '${DatabaseHelper.columnCustomerId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> hasDuplicatePhone(String phone, {String? excludeId}) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCustomers,
      where: excludeId != null
          ? '${DatabaseHelper.columnCustomerPhone} = ? AND ${DatabaseHelper.columnCustomerId} != ?'
          : '${DatabaseHelper.columnCustomerPhone} = ?',
      whereArgs: excludeId != null ? [phone, excludeId] : [phone],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
