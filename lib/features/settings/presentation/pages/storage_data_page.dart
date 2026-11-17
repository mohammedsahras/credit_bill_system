import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../widgets/settings_section_header.dart';

/// Storage & Data: real record counts from the app database, the real
/// on-disk database size, the live image-cache size and a working
/// "clear cache" action. Every figure is read from this device — nothing
/// is estimated or faked.
class StorageDataPage extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const StorageDataPage({super.key, required this.databaseHelper});

  @override
  State<StorageDataPage> createState() => _StorageDataPageState();
}

class _StorageDataPageState extends State<StorageDataPage> {
  static const List<({String label, String table})> _rowTables = [
    (label: 'Customers', table: DatabaseHelper.tableCustomers),
    (
      label: 'Credit transactions',
      table: DatabaseHelper.tableCreditTransactions,
    ),
    (label: 'Payments', table: DatabaseHelper.tablePayments),
    (label: 'Cards', table: DatabaseHelper.tableCards),
    (label: 'Statement bills', table: DatabaseHelper.tableBills),
  ];

  Map<String, int> _counts = {};
  int? _dbBytes;
  int _cacheBytes = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = await widget.databaseHelper.database;
      final counts = <String, int>{};
      for (final row in _rowTables) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) AS c FROM ${row.table}',
        );
        counts[row.label] =
            (result.first['c'] as int?) ??
            int.tryParse('${result.first['c']}') ??
            0;
      }

      int? dbBytes;
      if (!kIsWeb) {
        try {
          final file = File(await DatabaseHelper.databaseFilePath);
          if (await file.exists()) dbBytes = await file.length();
        } catch (_) {
          dbBytes = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _counts = counts;
        _dbBytes = dbBytes;
        _cacheBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not read storage information: $e';
      });
    }
  }

  Future<void> _clearCache() async {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    if (!mounted) return;
    setState(() => _cacheBytes = imageCache.currentSizeBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Image cache cleared.'),
        backgroundColor: CreditBillColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage & Data'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: CreditBillTextTheme.screenSubheading,
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Everything below is read directly from this device.',
                    style: CreditBillTextTheme.screenSubheading,
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionHeader(title: 'Record counts'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CreditBillColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CreditBillColors.deepBlue.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (final entry in _counts.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: CreditBillTextTheme.inputLabel,
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: CreditBillTextTheme.sectionLabel
                                      .copyWith(
                                        color: CreditBillColors.textDark,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionHeader(title: 'Usage'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CreditBillColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CreditBillColors.deepBlue.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _usageRow(
                          'Database file',
                          kIsWeb
                              ? 'Not available on the web'
                              : _dbBytes == null
                              ? 'Not created yet'
                              : _formatBytes(_dbBytes!),
                        ),
                        _usageRow('Image cache', _formatBytes(_cacheBytes)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CreditBillPrimaryButton(
                    key: const Key('clearCacheButton'),
                    text: 'Clear image cache',
                    onPressed: _clearCache,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clearing the cache frees temporary images (photos re-load '
                    'on demand). Your records are never touched.',
                    style: CreditBillTextTheme.inputLabel.copyWith(height: 1.5),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _usageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: CreditBillTextTheme.inputLabel)),
          Text(
            value,
            style: CreditBillTextTheme.sectionLabel.copyWith(
              color: CreditBillColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
