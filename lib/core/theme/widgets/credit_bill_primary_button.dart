import 'package:flutter/material.dart';

import '../credit_bill_colors.dart';
import '../credit_bill_theme.dart';

/// Premium pill-shaped primary button used across all authentication screens.
class CreditBillPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;

  const CreditBillPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      decoration: BoxDecoration(
        gradient: color != null
            ? LinearGradient(colors: [color!, color!])
            : const LinearGradient(
                colors: [
                  CreditBillColors.primaryBlue,
                  CreditBillColors.buttonColor,
                  CreditBillColors.deepBlue,
                ],
              ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CreditBillColors.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(CreditBillColors.white),
              ),
            )
          : Text(
              text,
              style: CreditBillTextTheme.buttonText.copyWith(
                color: color != null ? CreditBillColors.white : null,
              ),
              textAlign: TextAlign.center,
            ),
    );

    if (onPressed == null || isLoading) {
      return button;
    }
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28),
      child: button,
    );
  }
}

/// Secondary text button (link style) used for "Forgot password", "Back", etc.
class CreditBillTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;

  const CreditBillTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: CreditBillTextTheme.linkText.copyWith(
            color: color ?? CreditBillColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}
