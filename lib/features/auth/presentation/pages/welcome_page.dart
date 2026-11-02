import 'package:flutter/material.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_logo.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/credit_bill_theme.dart';

/// Screen 1 — Welcome.
///
/// Credit Bill App title, financial logo, large Welcome heading, short
/// description, and an attractive Get Started button on a premium blue
/// gradient background with a white geometric panel.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CreditBillBackground(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  const CreditBillLogo(size: 48),
                  const SizedBox(height: 40),
                  Text(
                    'Welcome',
                    style: CreditBillTextTheme.screenHeading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Take control of your credit cards, track billing cycles, '
                    'and protect your credit score — all offline and private.',
                    style: CreditBillTextTheme.screenSubheading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  CreditBillPrimaryButton(
                    text: 'Get Started',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
