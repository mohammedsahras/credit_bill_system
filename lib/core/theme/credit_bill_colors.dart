import 'package:flutter/material.dart';

/// Credit Bill App premium design system colour palette.
///
/// Matches the reference UI: blue gradient background, white geometric
/// panel, diagonal edges, rounded inputs, premium blue buttons.
class CreditBillColors {
  CreditBillColors._();

  // ---------- Primary blue & teal combination ----------
  static const Color primaryBlue = Color(0xFF087DB5);
  static const Color deepBlue = Color(0xFF075B87);
  static const Color lightBlue = Color(0xFF36A9DC);
  static const Color backgroundBlue = Color(0xFF168FC4);
  static const Color buttonColor = Color(0xFF0877A8);

  // ---------- Neutrals ----------
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF17243A);
  static const Color secondaryText = Color(0xFF65758B);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFD6E0EA);

  // ---------- Semantic ----------
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  // ---------- Gradients ----------
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF087DB5), Color(0xFF168FC4), Color(0xFF075B87)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF087DB5), Color(0xFF0877A8), Color(0xFF075B87)],
  );

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FB)],
  );
}

/// Premium typography for the Credit Bill App.
class CreditBillTextTheme {
  CreditBillTextTheme._();

  static const TextStyle brandName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: CreditBillColors.textDark,
    letterSpacing: -0.4,
  );

  static const TextStyle brandSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: CreditBillColors.secondaryText,
    letterSpacing: 0.4,
  );

  static const TextStyle screenHeading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: CreditBillColors.textDark,
    letterSpacing: -0.6,
    height: 1.15,
  );

  static const TextStyle screenSubheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: CreditBillColors.secondaryText,
    height: 1.5,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CreditBillColors.textDark,
    letterSpacing: 0.2,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: CreditBillColors.secondaryText,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: CreditBillColors.white,
    letterSpacing: 0.4,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CreditBillColors.primaryBlue,
  );

  static const TextStyle successHeading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: CreditBillColors.textDark,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle successBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: CreditBillColors.secondaryText,
    height: 1.6,
  );

  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: CreditBillColors.errorRed,
    height: 1.4,
  );
}
