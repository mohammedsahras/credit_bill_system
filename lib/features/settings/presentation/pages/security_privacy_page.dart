import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/settings_section_header.dart';

/// Security & Privacy: change the account password (verified against the
/// stored bcrypt/legacy hash) and sign out — plus a truthful note about
/// where the data lives.
///
/// Talks directly to [ChangePasswordUseCase] (auth domain), the same way
/// the settings shell talks to [GetProfileUseCase]; no session or
/// authenticated state changes, so `AuthBloc` needs no new surface.
class SecurityPrivacyPage extends StatefulWidget {
  final ChangePasswordUseCase changePasswordUseCase;

  const SecurityPrivacyPage({super.key, required this.changePasswordUseCase});

  @override
  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends State<SecurityPrivacyPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _formError;

  final ScrollController _scrollController = ScrollController();

  // Anchors used to scroll a field back into view after a failed submit:
  // the form list can be scrolled, so a field may be off-screen.
  final GlobalKey _currentAnchor = GlobalKey();
  final GlobalKey _newAnchor = GlobalKey();
  final GlobalKey _confirmAnchor = GlobalKey();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _signedInEmail {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticatedState ? state.email : null;
  }

  Future<void> _onChangePassword() async {
    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
      _formError = null;
    });

    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    var invalid = false;
    if (current.isEmpty) {
      setState(() => _currentError = 'Enter your current password.');
      invalid = true;
    }
    if (next.length < 6) {
      setState(() => _newError = 'Password must be at least 6 characters.');
      invalid = true;
    }
    if (confirm != next) {
      setState(() => _confirmError = 'Passwords do not match.');
      invalid = true;
    }
    if (invalid) {
      _revealFirstInvalidError();
      return;
    }

    final email = _signedInEmail;
    if (email == null) {
      setState(
        () => _formError = 'Please sign in again to change your password.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final result = await widget.changePasswordUseCase.execute(
      email: email,
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSaving = false;
          _formError = failure.message;
        });
        _showSnack(failure.message, CreditBillColors.errorRed);
      },
      (_) {
        setState(() {
          _isSaving = false;
          _currentController.clear();
          _newController.clear();
          _confirmController.clear();
          _formError = null;
        });
        _showSnack(
          'Password changed successfully.',
          CreditBillColors.successGreen,
        );
      },
    );
  }

  void _revealFirstInvalidError() {
    final anchor =
        _currentError != null
        ? _currentAnchor
        : _newError != null
        ? _newAnchor
        : _confirmAnchor;
    final fieldContext = anchor.currentContext;
    if (fieldContext != null) {
      Scrollable.ensureVisible(fieldContext);
      return;
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = anchor.currentContext;
      if (ctx != null && mounted) Scrollable.ensureVisible(ctx);
    });
  }

  void _showSnack(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your email and password to sign back in. '
          'Your data stays on this device.',
        ),
        actions: [
          CreditBillTextButton(
            key: const Key('signOutCancelButton'),
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CreditBillTextButton(
            key: const Key('signOutConfirmButton'),
            text: 'Sign out',
            color: CreditBillColors.errorRed,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    context.read<AuthBloc>().add(LogoutRequestedEvent());
    // Drop every pushed route so the AuthWrapper below shows the welcome
    // screen once the bloc reports the session as cleared.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Privacy'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            if (_formError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CreditBillColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CreditBillColors.errorRed,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: CreditBillColors.errorRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: CreditBillTextTheme.errorText.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SettingsSectionHeader(title: 'Change password'),
            KeyedSubtree(
              key: _currentAnchor,
              child: CreditBillTextField(
                key: const Key('changeCurrentPasswordField'),
                label: 'Current password',
                hint: 'Enter your current password',
                controller: _currentController,
                obscureText: _obscureCurrent,
                textInputAction: TextInputAction.next,
                errorText: _currentError,
                onChanged: (_) {
                  if (_currentError != null) {
                    setState(() => _currentError = null);
                  }
                },
                onToggleVisibility: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: _newAnchor,
              child: CreditBillTextField(
                key: const Key('changeNewPasswordField'),
                label: 'New password',
                hint: 'At least 6 characters',
                controller: _newController,
                obscureText: _obscureNew,
                errorText: _newError,
                onChanged: (_) {
                  if (_newError != null) setState(() => _newError = null);
                },
                onToggleVisibility: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: _confirmAnchor,
              child: CreditBillTextField(
                key: const Key('changeConfirmPasswordField'),
                label: 'Confirm new password',
                hint: 'Repeat the new password',
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                errorText: _confirmError,
                onChanged: (_) {
                  if (_confirmError != null) {
                    setState(() => _confirmError = null);
                  }
                },
                onToggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            const SizedBox(height: 20),
            CreditBillPrimaryButton(
              key: const Key('changePasswordButton'),
              text: 'Update password',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _onChangePassword,
            ),
            const SizedBox(height: 24),
            const SettingsSectionHeader(title: 'Session'),
            _signOutTile(),
            const SizedBox(height: 16),
            const SettingsSectionHeader(title: 'Privacy'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CreditBillColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'All records — customers, transactions, payments and your '
                'profile — are stored locally in the app database on this '
                'device. CreditBill makes no network requests and shares '
                'nothing with third parties. Signing out keeps the data; '
                'only your session ends.',
                style: CreditBillTextTheme.inputLabel.copyWith(height: 1.55),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _signOutTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: const Key('signOutTile'),
        onTap: _isSaving ? null : _confirmSignOut,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: CreditBillColors.white,
            borderRadius: BorderRadius.circular(12),
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
                  color: CreditBillColors.errorRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  size: 20,
                  color: CreditBillColors.errorRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign out',
                      style: CreditBillTextTheme.sectionLabel.copyWith(
                        color: CreditBillColors.errorRed,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'End this session on this device',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CreditBillTextTheme.inputLabel,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: CreditBillColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
