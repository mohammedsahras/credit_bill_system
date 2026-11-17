import 'package:flutter/material.dart';

import '../credit_bill_colors.dart';
import '../credit_bill_theme.dart';

/// Premium pill-shaped primary button used across all authentication screens.
class CreditBillPrimaryButton extends StatefulWidget {
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
  State<CreditBillPrimaryButton> createState() =>
      _CreditBillPrimaryButtonState();
}

class _CreditBillPrimaryButtonState extends State<CreditBillPrimaryButton> {
  bool _pressed = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: widget.isFullWidth ? double.infinity : null,
      height: 56,
      decoration: BoxDecoration(
        gradient: widget.color != null
            ? LinearGradient(colors: [widget.color!, widget.color!])
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
            color: CreditBillColors.primaryBlue.withValues(
              alpha: _hovering ? 0.45 : 0.35,
            ),
            blurRadius: _hovering ? 22 : 16,
            offset: Offset(0, _hovering ? 10 : 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: widget.isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(CreditBillColors.white),
              ),
            )
          : Text(
              widget.text,
              style: CreditBillTextTheme.buttonText.copyWith(
                color: widget.color != null ? CreditBillColors.white : null,
              ),
              textAlign: TextAlign.center,
            ),
    );

    if (widget.onPressed == null || widget.isLoading) {
      return button;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(28),
          child: button,
        ),
      ),
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
