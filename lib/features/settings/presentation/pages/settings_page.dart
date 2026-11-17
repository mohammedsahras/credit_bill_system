import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../../../core/theme/widgets/credit_bill_animated_entrance.dart';
import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tile.dart';

/// Main Settings screen: profile header, Edit Profile entry, live search
/// and the full settings category list.
///
/// Every category leads to a fully functional screen (theme, security,
/// storage, help, about) — there are no placeholders and no inert
/// controls. Categories whose feature does not exist yet (language,
/// notifications) are omitted entirely rather than shown as stubs.
class SettingsPage extends StatefulWidget {
  final GetProfileUseCase getProfileUseCase;

  const SettingsPage({super.key, required this.getProfileUseCase});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsSection {
  final String title;
  final List<_SettingsCategory> items;

  const _SettingsSection(this.title, this.items);
}

class _SettingsCategory {
  final String title;
  final String subtitle;
  final IconData icon;

  /// Named route of the destination screen. "Edit profile" is dispatched
  /// inline first so it can reload the header on return.
  final String route;

  const _SettingsCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}

class _SettingsPageState extends State<SettingsPage> {
  static const _categories = <_SettingsSection>[
    _SettingsSection('Account', [
      _SettingsCategory(
        title: 'Edit profile',
        subtitle: 'Name, email, phone and photo',
        icon: Icons.person_outline,
        route: '/edit-profile',
      ),
    ]),
    _SettingsSection('Preferences', [
      _SettingsCategory(
        title: 'Theme & Appearance',
        subtitle: 'Light, dark and system theme',
        icon: Icons.palette_outlined,
        route: '/settings/theme',
      ),
    ]),
    _SettingsSection('Privacy', [
      _SettingsCategory(
        title: 'Security & Privacy',
        subtitle: 'Change password and sign out',
        icon: Icons.lock_outline,
        route: '/settings/security',
      ),
    ]),
    _SettingsSection('Data', [
      _SettingsCategory(
        title: 'Storage & Data',
        subtitle: 'Storage usage and cache',
        icon: Icons.storage_outlined,
        route: '/settings/storage',
      ),
    ]),
    _SettingsSection('Support', [
      _SettingsCategory(
        title: 'Help & Support',
        subtitle: 'FAQs and app guide',
        icon: Icons.help_outline,
        route: '/settings/help',
      ),
      _SettingsCategory(
        title: 'About',
        subtitle: 'Version and legal information',
        icon: Icons.info_outline,
        route: '/settings/about',
      ),
    ]),
  ];

  final _searchController = TextEditingController();

  UserEntity? _profile;
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _accountEmail {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticatedState ? state.email : null;
  }

  Future<void> _loadProfile() async {
    final email = _accountEmail;
    if (email == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to view your profile.';
        _profile = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.getProfileUseCase.execute(email: email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.isLeft) {
          _profile = null;
          _error = result.leftOrNull!.message;
        } else {
          _profile = result.rightOrNull;
          _error = _profile == null ? 'No profile found for this account.' : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _profile = null;
        _error = 'Failed to load profile: $e';
      });
    }
  }

  Future<void> _openEditProfile() async {
    // Deliberately not `pushNamed<bool>`: named routes are registered as
    // `MaterialPageRoute<dynamic>`, and `pushNamed<bool>` casts the created
    // route to `Route<bool?>`, which throws a TypeError at runtime. The
    // popped result is still compared against `true` below.
    final updated = await Navigator.of(context).pushNamed('/edit-profile');
    if (updated == true && mounted) {
      await _loadProfile();
    }
  }

  void _openCategory(_SettingsCategory category) {
    if (category.title == 'Edit profile') {
      _openEditProfile();
      return;
    }
    Navigator.of(context).pushNamed(category.route);
  }

  List<_SettingsSection> get _visibleSections {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories
        .map(
          (section) => _SettingsSection(
            section.title,
            section.items
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(query) ||
                      item.subtitle.toLowerCase().contains(query),
                )
                .toList(),
          ),
        )
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
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
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_query.trim().isEmpty) ...[
                    ProfileHeader(
                      name: _profile?.fullName ?? '',
                      email: _profile?.email,
                      phone: _profile?.phone,
                      photo: _profile?.photo,
                      onTap: _openEditProfile,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  if (sections.isEmpty) ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'No settings match "${_query.trim()}".',
                        textAlign: TextAlign.center,
                        style: CreditBillTextTheme.screenSubheading,
                      ),
                    ),
                  ],
                  for (final section in sections) ...[
                    SettingsSectionHeader(title: section.title),
                    for (var i = 0; i < section.items.length; i++)
                      CreditBillAnimatedEntrance(
                        index: i,
                        child: SettingsTile(
                          icon: section.items[i].icon,
                          title: section.items[i].title,
                          subtitle: section.items[i].subtitle,
                          onTap: () => _openCategory(section.items[i]),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: SizedBox(
        height: 48,
        child: TextField(
          key: const Key('settingsSearchField'),
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: CreditBillColors.textDark,
          ),
          cursorColor: CreditBillColors.primaryBlue,
          decoration: InputDecoration(
            hintText: 'Search settings',
            hintStyle: const TextStyle(
              fontSize: 15,
              color: CreditBillColors.secondaryText,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: CreditBillColors.secondaryText,
            ),
            filled: true,
            fillColor: CreditBillColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: CreditBillColors.inputBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: CreditBillColors.primaryBlue,
                width: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
