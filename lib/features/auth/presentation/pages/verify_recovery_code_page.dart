import 'package:flutter/material.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../../core/theme/credit_bill_theme.dart';

class VerifyRecoveryCodePage extends StatefulWidget {
  final String email;

  const VerifyRecoveryCodePage({super.key, required this.email});

  @override
  State<VerifyRecoveryCodePage> createState() => _VerifyRecoveryCodePageState();
}

class _VerifyRecoveryCodePageState extends State<VerifyRecoveryCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onVerify() {
    if (!_formKey.currentState!.validate()) return;
    // Navigate to create new password with email and code
    Navigator.of(context).pushNamed(
      '/create-new-password',
      arguments: {'email': widget.email, 'code': _codeController.text.trim()},
    );
  }

  void _onResend() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new recovery code has been sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Recovery Code'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
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
                  const SizedBox(height: 20),
                  Text(
                    'Verify Recovery Code',
                    style: CreditBillTextTheme.screenHeading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the 6-digit code sent to ${widget.email}',
                    style: CreditBillTextTheme.screenSubheading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CreditBillTextField(
                          label: 'Recovery Code',
                          hint: 'Enter 6-digit code',
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          suffixIcon: Icons.lock_outline,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Recovery code is required.';
                            }
                            if (v.trim().length != 6) {
                              return 'Code must be 6 digits.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 26),
                        CreditBillPrimaryButton(
                          text: 'Verify Code',
                          onPressed: _onVerify,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _onResend,
                          child: Text(
                            'Resend Code',
                            style: CreditBillTextTheme.linkText,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
