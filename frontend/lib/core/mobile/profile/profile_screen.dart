import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/cache/app_cache.dart';
import 'package:san_tayo/core/config/api_endpoints.dart';
import 'package:san_tayo/core/mobile/auth/auth_helpers.dart';
import 'package:san_tayo/core/mobile/auth/sign_in_screen.dart';
import 'package:san_tayo/core/mobile/global_widgets/change_landmark_sheet.dart';
import 'package:san_tayo/core/mobile/profile/about_screen.dart';
import 'package:san_tayo/core/mobile/profile/app_copy.dart';
import 'package:san_tayo/core/mobile/profile/change_password_screen.dart';
import 'package:san_tayo/core/mobile/profile/edit_profile_screen.dart';
import 'package:san_tayo/core/mobile/profile/faq_screen.dart';
import 'package:san_tayo/core/mobile/profile/profile_widgets.dart';
import 'package:san_tayo/core/mobile/profile/terms_privacy_screen.dart';
import 'package:san_tayo/core/network/api_client.dart';
import 'package:san_tayo/core/network/session.dart';

/// Profile hub: account settings, business upgrade, about links, and log out.
class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>> landmarks;
  final Map<String, dynamic> selectedLandmark;
  final ValueChanged<Map<String, dynamic>>? onLandmarkChanged;

  const ProfileScreen({
    super.key,
    required this.landmarks,
    required this.selectedLandmark,
    this.onLandmarkChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _selected_landmark;
  bool _upgrading = false;

  @override
  void initState() {
    super.initState();
    _selected_landmark = widget.selectedLandmark;
  }

  String get _username {
    return cached_account?['username']?.toString() ?? 'username';
  }

  String get _auth_level {
    return cached_account?['auth_level']?.toString() ?? 'user';
  }

  String get _landmark_name {
    return _selected_landmark['name']?.toString() ?? default_landmark_name;
  }

  String _badge_label() {
    if (_auth_level == 'business') {
      return 'Business';
    }
    return 'User';
  }

  Future<void> _open_landmark() async {
    final picked = await show_change_landmark_sheet(
      context: context,
      landmarks: widget.landmarks,
      selected: _selected_landmark,
    );

    if (picked == null) {
      return;
    }

    await save_selected_landmark(picked);
    if (!mounted) {
      return;
    }

    setState(() => _selected_landmark = picked);
    widget.onLandmarkChanged?.call(picked);
  }

  Future<void> _upgrade_business() async {
    showAuthMessage(context, "Business account available soon!");
    return;
    // setState(() => _upgrading = true);

    // final res = await api_request('POST', ApiEndpoints.account_upgrade_business);

    // if (!mounted) {
    //   return;
    // }

    // setState(() => _upgrading = false);

    // if (res.code == 1 && res.data != null) {
    //   await cache_account(res.data);
    //   if (!mounted) {
    //     return;
    //   }
    //   setState(() {});
    //   showAuthMessage(context, res.msg);
    //   return;
    // }

    // showAuthMessage(context, res.msg);
  }

  Future<void> _logout() async {
    await api_request('POST', ApiEndpoints.auth_logout);
    await clear_session();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final is_user     = _auth_level == 'user';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const ProfilePageHeader(title: 'Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _ProfileSummaryCard(
                  username: _username,
                  badgeLabel: _badge_label(),
                ),
                const SizedBox(height: 4),
                const ProfileSectionLabel(label: 'ACCOUNT'),
                ProfileMenuCard(
                  children: [
                    ProfileMenuRow(
                      icon: HeroIcons.user,
                      title: 'Edit Profile',
                      subtitle: 'Username and email',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                    ),
                    ProfileMenuRow(
                      icon: HeroIcons.lockClosed,
                      title: 'Change Password',
                      subtitle: 'Update your login password',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuRow(
                      icon: HeroIcons.mapPin,
                      title: 'Default Landmark',
                      subtitle: _landmark_name,
                      showDivider: false,
                      onTap: _open_landmark,
                    ),
                  ],
                ),
                if (is_user) ...[
                  const ProfileSectionLabel(label: 'BUSINESS'),
                  _BusinessPromoCard(
                    isSaving: _upgrading,
                    onUpgrade: _upgrade_business,
                  ),
                ],
                const ProfileSectionLabel(label: 'ABOUT APP'),
                ProfileMenuCard(
                  children: [
                    ProfileMenuRow(
                      icon: HeroIcons.questionMarkCircle,
                      title: 'Help & FAQ',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FaqScreen()),
                        );
                      },
                    ),
                    ProfileMenuRow(
                      icon: HeroIcons.documentText,
                      title: 'Terms & Privacy Policy',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TermsPrivacyScreen(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuRow(
                      icon: HeroIcons.informationCircle,
                      title: "About Sa'n Tayo?",
                      subtitle: 'Version $app_version',
                      showDivider: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ProfileMenuCard(
                  children: [
                    Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: _logout,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Log Out',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final String username;
  final String badgeLabel;

  const _ProfileSummaryCard({
    required this.username,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 2),
              color: colorScheme.primary.withValues(alpha: 0.06),
            ),
            child: Center(
              child: HeroIcon(
                HeroIcons.user,
                style: HeroIconStyle.solid,
                color: colorScheme.primary,
                size:  36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '@$username',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeLabel,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessPromoCard extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onUpgrade;

  const _BusinessPromoCard({
    required this.isSaving,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HeroIcon(
                    HeroIcons.buildingStorefront,
                    style: HeroIconStyle.solid,
                    color: colorScheme.onPrimary,
                    size:  22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Own a food business?',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Switch to a Business Account to list your menu, manage photos, and reach more students near campus.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSaving ? null : onUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width:  20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Switch to Business Account',
                          style: textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary),
                        ),
                        const SizedBox(width: 4),
                        HeroIcon(
                          HeroIcons.chevronRight,
                          style: HeroIconStyle.outline,
                          color: colorScheme.onPrimary,
                          size:  16,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
