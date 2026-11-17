import 'package:flutter/material.dart';

import '../../../../core/theme/credit_bill_colors.dart';

/// Small uppercase-ish heading used to group settings categories
/// (WhatsApp-style section labels).
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: CreditBillColors.primaryBlue,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
