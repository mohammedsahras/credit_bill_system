import 'package:flutter/material.dart';

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/widgets/credit_bill_animated_entrance.dart';
import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../widgets/settings_option_tile.dart';
import '../widgets/settings_section_header.dart';

/// Theme & Appearance: pick System / Light / Dark.
///
/// The selection applies to the whole app on the same frame (the page and
/// `MaterialApp` both listen to [ThemeController]; Material eases the
/// switch with its built-in [AnimatedTheme]) and is persisted by the
/// controller so it survives an app restart.
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reading the controller here subscribes this page to mode changes.
    final controller = ThemeScope.of(context);
    final mode = controller.mode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme & Appearance'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Choose how CreditBill looks. The selection applies to every '
              'screen and is saved on this device.',
              style: CreditBillTextTheme.screenSubheading,
            ),
            const SizedBox(height: 16),
            const SettingsSectionHeader(title: 'Appearance'),
            CreditBillAnimatedEntrance(
              index: 0,
              child: SettingsOptionTile(
                key: const Key('themeSystemOption'),
                icon: Icons.brightness_auto_outlined,
                title: 'System default',
                subtitle: 'Match your device light/dark setting',
                selected: mode == ThemeMode.system,
                onTap: () => controller.setMode(ThemeMode.system),
              ),
            ),
            CreditBillAnimatedEntrance(
              index: 1,
              child: SettingsOptionTile(
                key: const Key('themeLightOption'),
                icon: Icons.light_mode_outlined,
                title: 'Light',
                subtitle: 'Always use the light theme',
                selected: mode == ThemeMode.light,
                onTap: () => controller.setMode(ThemeMode.light),
              ),
            ),
            CreditBillAnimatedEntrance(
              index: 2,
              child: SettingsOptionTile(
                key: const Key('themeDarkOption'),
                icon: Icons.dark_mode_outlined,
                title: 'Dark',
                subtitle: 'Always use the dark theme',
                selected: mode == ThemeMode.dark,
                onTap: () => controller.setMode(ThemeMode.dark),
              ),
            ),
            const SizedBox(height: 8),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.palette_outlined,
                    size: 18,
                    color: CreditBillColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Theme changes apply instantly across the app and are '
                      'kept for your next launch.',
                      style: CreditBillTextTheme.inputLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
