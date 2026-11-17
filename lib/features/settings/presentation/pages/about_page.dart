import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_logo.dart';
import '../widgets/settings_section_header.dart';

/// About: real app identity — the version is parsed from the bundled
/// `pubspec.yaml` asset (single source of truth, no hard-coded copy), and
/// the license listing is Flutter's built-in [showLicensePage], which
/// reads the actual licenses of every package in the build.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  /// Raw version from pubspec (`1.0.0+1`), null until loaded.
  String? _rawVersion;
  bool _versionFailed = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final yaml = await rootBundle.loadString('pubspec.yaml');
      final match = RegExp(
        r'^version:[ \t]*(\S+)',
        multiLine: true,
      ).firstMatch(yaml);
      if (!mounted) return;
      setState(() {
        _rawVersion = match?.group(1);
        _versionFailed = _rawVersion == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionFailed = true);
    }
  }

  String get _versionDisplay {
    final raw = _rawVersion;
    if (raw == null) return _versionFailed ? 'Unavailable' : 'Loading…';
    final parts = raw.split('+');
    return parts.length > 1 ? '${parts[0]} (build ${parts[1]})' : raw;
  }

  void _openLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Credit Bill System',
      applicationVersion: _rawVersion ?? '',
      applicationLegalese:
          'CreditBill is an offline-first customer credit app. All records '
          'stay on this device.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Center(child: CreditBillLogo(size: 64)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Credit Bill System',
                style: CreditBillTextTheme.brandName,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Version $_versionDisplay',
                key: const Key('aboutVersion'),
                style: CreditBillTextTheme.inputLabel,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CreditBillColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Offline-first customer credit and bill management. Cards, '
                'customers, transactions, payments and reports are stored '
                'locally on this device — the app works without an internet '
                'connection and never sends your data anywhere.',
                style: CreditBillTextTheme.inputLabel.copyWith(height: 1.55),
              ),
            ),
            const SizedBox(height: 16),
            const SettingsSectionHeader(title: 'Legal'),
            // Material (not a bare DecoratedBox) so ListTile paints its
            // own background and ink splash — the framework asserts on
            // an opaque DecoratedBox in between.
            Material(
              color: CreditBillColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  key: const Key('openLicensesButton'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    'Open-source licenses',
                    style: CreditBillTextTheme.sectionLabel,
                  ),
                  subtitle: Text(
                    'Licenses of Flutter and every bundled package',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CreditBillTextTheme.inputLabel,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: CreditBillColors.secondaryText,
                  ),
                  onTap: _openLicenses,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 CreditBill. All rights reserved.',
                style: CreditBillTextTheme.inputLabel,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
