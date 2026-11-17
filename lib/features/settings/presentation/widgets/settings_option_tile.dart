import 'package:flutter/material.dart';

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';

/// A selectable settings row (white card + leading icon + trailing check)
/// used by the theme picker.
///
/// [selected] draws the accent border/check mark and is announced to
/// accessibility services through the semantics `selected` flag.
class SettingsOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const SettingsOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: CreditBillColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? CreditBillColors.primaryBlue
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CreditBillColors.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: CreditBillColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: CreditBillTextTheme.sectionLabel),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CreditBillTextTheme.inputLabel,
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.check_circle,
                    size: 22,
                    color: CreditBillColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
