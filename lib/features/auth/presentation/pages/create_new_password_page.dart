import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_logo.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../bloc/auth_bloc.dart';

/// Screen 4 — Create New Password.
///
/// Create New Password heading, New Password and Confirm Password inputs
/// with visibility controls, password validation, and Update Password button.
class CreateNewPasswordPage extends StatefulWidget {
  final String email;
  final String? code;

  const CreateNewPasswordPage({super.key, required this.email, this.code});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  void _onUpdate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      ResetPasswordRequestedEvent(
        email: widget.email,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: CreditBillColors.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state is AuthSuccessState) {
          Navigator.of(context).pushReplacementNamed('/password-changed');
        }
      },
      child: Scaffold(
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
                    const CreditBillLogo(size: 40),
                    const SizedBox(height: 24),
                    Text(
                      'Create New Password',
                      style: CreditBillTextTheme.screenHeading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose a strong new password for your account.',
                      style: CreditBillTextTheme.screenSubheading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CreditBillTextField(
                            label: 'New Password',
                            hint: '••••••••',
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            autofocus: true,
                            onToggleVisibility: () {
                              setState(() => _obscureNew = !_obscureNew);
                            },
                            validator: _validateNewPassword,
                          ),
                          const SizedBox(height: 18),
                          CreditBillTextField(
                            label: 'Confirm Password',
                            hint: '••••••••',
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onToggleVisibility: () {
                              setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              );
                            },
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: 26),
                          CreditBillPrimaryButton(
                            text: 'Update Password',
                            onPressed: _onUpdate,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
