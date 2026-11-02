import 'package:flutter/material.dart';

import '../credit_bill_colors.dart';
import '../credit_bill_theme.dart';

/// Credit Bill App logo: icon + brand name, shown on authentication screens.
class CreditBillLogo extends StatelessWidget {
  final double size;
  final TextStyle? nameStyle;

  const CreditBillLogo({super.key, this.size = 44, this.nameStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                CreditBillColors.primaryBlue,
                CreditBillColors.buttonColor,
                CreditBillColors.deepBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CreditBillColors.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.account_balance_wallet,
            size: 26,
            color: CreditBillColors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text('Credit Bill', style: nameStyle ?? CreditBillTextTheme.brandName),
        const SizedBox(height: 4),
        Text(
          'Personal Credit Command Center',
          style: CreditBillTextTheme.brandSubtitle,
        ),
      ],
    );
  }
}
