import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section_header.dart';

/// Profile / Account editor.
///
/// Loads the stored profile through [GetProfileUseCase] (auth domain), lets
/// the user edit name, email, phone and photo, and persists through
/// [AuthBloc] — which validates, re-saves the session and refreshes the
/// authenticated state. Changing the email address always requires the
/// current password first.
class EditProfilePage extends StatefulWidget {
  final GetProfileUseCase getProfileUseCase;

  const EditProfilePage({super.key, required this.getProfileUseCase});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  /// Binary cap for a picked photo (~300 KB before base64 encoding).
  static const int _maxPhotoBytes = 300 * 1024;

  static final RegExp _emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9()\-\s]{6,20}$');

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  UserEntity? _profile;
  bool _loading = true;
  bool _initialized = false;
  bool _isSaving = false;
  String? _loadError;
  String? _photo;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _formError;

  final ScrollController _scrollController = ScrollController();

  /// Anchors used to scroll a field back into view after a failed save: the
  /// form list is lazy, so a field above the fold may not even be mounted.
  final GlobalKey _nameAnchor = GlobalKey();
  final GlobalKey _emailAnchor = GlobalKey();
  final GlobalKey _phoneAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _signedInEmail {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticatedState ? state.email : null;
  }

  Future<void> _loadProfile() async {
    final email = _signedInEmail;
    if (email == null) {
      setState(() {
        _loading = false;
        _loadError = 'Please sign in again to edit your profile.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final result = await widget.getProfileUseCase.execute(email: email);
      if (!mounted) return;
      if (result.isLeft) {
        setState(() {
          _loading = false;
          _loadError = result.leftOrNull!.message;
        });
        return;
      }
      final profile = result.rightOrNull;
      if (profile == null) {
        setState(() {
          _loading = false;
          _loadError = 'No profile found for this account.';
        });
        return;
      }
      // Only seed the form on the first successful load so a retry never
      // discards in-progress edits.
      if (!_initialized) {
        _nameController.text = profile.fullName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phone ?? '';
        _photo = profile.photo;
        _initialized = true;
      }
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Failed to load profile: $e';
      });
    }
  }

  Future<void> _onSave() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _formError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    var invalid = false;
    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty.');
      invalid = true;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address.');
      invalid = true;
    }
    if (phone.isNotEmpty && !_phoneRegex.hasMatch(phone)) {
      setState(() => _phoneError = 'Enter a valid phone number.');
      invalid = true;
    }
    if (invalid) {
      _revealFirstInvalidError();
      return;
    }

    final originalEmail =
        _profile?.email ?? _signedInEmail ?? '';
    final emailChanged = email.toLowerCase() != originalEmail.toLowerCase();

    String? currentPassword;
    if (emailChanged) {
      currentPassword = await _askCurrentPassword();
      if (currentPassword == null) return; // User cancelled the confirmation.
    }
    if (!mounted) return;

    setState(() => _isSaving = true);
    context.read<AuthBloc>().add(
      UpdateProfileEvent(
        currentEmail: originalEmail,
        fullName: name,
        email: email,
        phone: phone.isEmpty ? null : phone,
        photo: _photo,
        currentPassword: currentPassword,
      ),
    );
  }

  /// Brings the first invalid field into view after a failed save so the
  /// validation error is actually visible. The form list is lazy: a field
  /// above the current scroll position may not even be mounted yet, so in
  /// that case snap to the top first and reveal it on the next frame.
  void _revealFirstInvalidError() {
    final anchor =
        _nameError != null
        ? _nameAnchor
        : _emailError != null
        ? _emailAnchor
        : _phoneAnchor;
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

  /// Password confirmation dialog shown only for an email change.
  /// Returns the entered password, or null when the user cancels.
  Future<String?> _askCurrentPassword() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _PasswordConfirmDialog(),
    );
  }

  Future<void> _pickPhoto() async {
    if (_isSaving) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return; // Selection cancelled — keep current photo.

      final bytes = await picked.readAsBytes();
      String? error;
      if (bytes.isEmpty) {
        error = 'The selected image could not be read.';
      } else if (bytes.lengthInBytes > _maxPhotoBytes) {
        error = 'Please choose a smaller photo (max 300 KB).';
      } else {
        // Reject corrupt files outright so a broken image never reaches
        // the database; `Image.memory` still guards the rendering side.
        try {
          final image = await decodeImageFromList(bytes);
          image.dispose();
        } catch (_) {
          error = 'This file is not a valid image. Please choose another one.';
        }
      }
      if (!mounted) return;
      if (error != null) {
        setState(() => _formError = error);
        return;
      }
      setState(() {
        _photo = base64Encode(bytes);
        _formError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = 'Could not open the photo picker: $e');
    }
  }

  void _removePhoto() {
    setState(() {
      _photo = null;
      _formError = null;
    });
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthProfileUpdatedState) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: CreditBillColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (state is AuthProfileUpdateFailedState) {
      setState(() {
        _isSaving = false;
        _formError = state.message;
      });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, next) =>
          next is AuthProfileUpdatedState ||
          next is AuthProfileUpdateFailedState,
      listener: _onAuthState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: CreditBillColors.primaryBlue,
          foregroundColor: CreditBillColors.white,
        ),
        body: CreditBillBackground(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: CreditBillTextTheme.screenSubheading,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (_formError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CreditBillColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CreditBillColors.errorRed, width: 1),
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
                    style: CreditBillTextTheme.errorText.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildPhotoSection(),
        const SizedBox(height: 20),
        const SettingsSectionHeader(title: 'Personal details'),
        KeyedSubtree(
          key: _nameAnchor,
          child: CreditBillTextField(
            key: const Key('profileNameField'),
            label: 'Full name',
            hint: 'Your name',
            controller: _nameController,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _emailAnchor,
          child: CreditBillTextField(
            key: const Key('profileEmailField'),
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _phoneAnchor,
          child: CreditBillTextField(
            key: const Key('profilePhoneField'),
            label: 'Phone',
            hint: 'Optional mobile number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            errorText: _phoneError,
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
          ),
        ),
        const SizedBox(height: 20),
        const SettingsSectionHeader(title: 'Account info'),
        _buildAccountInfo(),
        const SizedBox(height: 24),
        CreditBillPrimaryButton(
          key: const Key('saveProfileButton'),
          text: 'Save changes',
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _onSave,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        const SizedBox(height: 4),
        ProfileAvatar(
          key: const Key('profilePhotoAvatar'),
          name: _nameController.text,
          photo: _photo,
          size: 72,
        ),
        const SizedBox(height: 10),
        // Wrap (not Row): the panel's content column is only ~252px wide,
        // so the two buttons must stack instead of overflowing sideways
        // (which pushed "Remove photo" outside the viewport's hit area).
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            CreditBillTextButton(
              key: const Key('changePhotoButton'),
              text: 'Change photo',
              onPressed: _isSaving ? null : _pickPhoto,
            ),
            if (_photo != null)
              CreditBillTextButton(
                key: const Key('removePhotoButton'),
                text: 'Remove photo',
                color: CreditBillColors.errorRed,
                onPressed: _isSaving ? null : _removePhoto,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountInfo() {
    final profile = _profile;
    final created = profile?.createdAt;
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          _infoRow('User ID', profile?.id ?? '—'),
          _infoRow('Email', profile?.email ?? _signedInEmail ?? '—'),
          _infoRow(
            'Member since',
            created == null ? '—' : DateFormat('d MMM yyyy').format(created),
          ),
          _infoRow(
            'Email verified',
            profile == null
                ? '—'
                : (profile.isEmailVerified ? 'Verified' : 'Not verified'),
            isStatus: true,
            verified: profile?.isEmailVerified ?? false,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isStatus = false,
    bool verified = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: CreditBillTextTheme.inputLabel),
          ),
          Expanded(
            child: isStatus
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (verified
                                ? CreditBillColors.successGreen
                                : CreditBillColors.secondaryText)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        value,
                        style: CreditBillTextTheme.inputLabel.copyWith(
                          color: verified
                              ? CreditBillColors.successGreen
                              : CreditBillColors.secondaryText,
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: CreditBillTextTheme.inputLabel.copyWith(
                      color: CreditBillColors.textDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Asks for the current password before allowing an email change.
///
/// The dialog owns its [TextEditingController] and disposes it in
/// [State.dispose], i.e. only after the dialog route's exit animation has
/// finished and the route's widgets are unmounted. Disposing from a
/// `showDialog(...).whenComplete` callback instead would release the
/// controller while the closing dialog is still rebuilding against it
/// ("A TextEditingController was used after being disposed").
class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog();

  @override
  State<_PasswordConfirmDialog> createState() =>
      _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm your current password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Changing your email address needs your current '
            'password to confirm it is you.',
            style: CreditBillTextTheme.inputLabel,
          ),
          const SizedBox(height: 14),
          CreditBillTextField(
            key: const Key('currentPasswordField'),
            label: 'Current password',
            hint: 'Enter your password',
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onToggleVisibility: () => setState(() => _obscure = !_obscure),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: CreditBillTextTheme.errorText),
          ],
        ],
      ),
      actions: [
        CreditBillTextButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        CreditBillTextButton(
          text: 'Confirm',
          onPressed: () {
            if (_controller.text.isEmpty) {
              setState(() => _error = 'Password is required.');
              return;
            }
            Navigator.of(context).pop(_controller.text);
          },
        ),
      ],
    );
  }
}

