import 'package:flutter/material.dart';

import '../credit_bill_colors.dart';
import '../credit_bill_theme.dart';

/// Rounded premium input field with label, optional suffix icon and
/// error message. Consistent across all authentication screens.
class CreditBillTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback? onToggleVisibility;
  final IconData? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final bool autofocus;

  const CreditBillTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onToggleVisibility,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.autofillHints,
    this.autofocus = false,
  });

  @override
  State<CreditBillTextField> createState() => _CreditBillTextFieldState();
}

class _CreditBillTextFieldState extends State<CreditBillTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = hasError
        ? CreditBillColors.errorRed
        : (widget.enabled
              ? CreditBillColors.inputBorder
              : CreditBillColors.secondaryText.withValues(alpha: 0.5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: CreditBillTextTheme.inputLabel),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscure,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            autofocus: widget.autofocus,
            style: const TextStyle(
              fontSize: 15,
              color: CreditBillColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: CreditBillColors.primaryBlue,
            onChanged: widget.onChanged,
            validator: widget.validator,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                fontSize: 15,
                color: CreditBillColors.secondaryText,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: widget.enabled
                  ? CreditBillColors.inputBackground
                  : CreditBillColors.secondaryText.withValues(alpha: 0.08),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: CreditBillColors.primaryBlue,
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: CreditBillColors.errorRed,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: CreditBillColors.errorRed,
                  width: 1.8,
                ),
              ),
              errorText: widget.errorText,
              errorStyle: CreditBillTextTheme.errorText,
              suffixIcon:
                  widget.obscureText && widget.onToggleVisibility != null
                  ? GestureDetector(
                      onTap: widget.onToggleVisibility,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: CreditBillColors.secondaryText,
                        ),
                      ),
                    )
                  : (widget.suffixIcon != null
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              widget.suffixIcon,
                              size: 20,
                              color: CreditBillColors.secondaryText,
                            ),
                          )
                        : null),
            ),
          ),
        ),
      ],
    );
  }
}
