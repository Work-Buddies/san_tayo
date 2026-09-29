import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/config/api_endpoints.dart';
import 'package:san_tayo/core/mobile/auth/auth_helpers.dart';
import 'package:san_tayo/core/mobile/profile/profile_widgets.dart';
import 'package:san_tayo/core/network/api_client.dart';
import 'package:san_tayo/core/network/session.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _username_ctrl = TextEditingController();
  late final TextEditingController _email_ctrl;
  bool _is_saving = false;

  @override
  void initState() {
    super.initState();
    _username_ctrl.text = cached_account?['username']?.toString() ?? '';
    _email_ctrl = TextEditingController(
      text: cached_account?['email']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _username_ctrl.dispose();
    _email_ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _username_ctrl.text.trim();

    if (username.isEmpty) {
      showAuthMessage(context, 'Username is required.');
      return;
    }

    setState(() => _is_saving = true);

    final res = await api_request(
      'PUT',
      ApiEndpoints.account_username,
      body: {'username': username},
    );

    if (!mounted) {
      return;
    }

    setState(() => _is_saving = false);

    if (res.code == 1 && res.data != null) {
      await cache_account(res.data);
      if (!mounted) {
        return;
      }
      showAuthMessage(context, res.msg);
      Navigator.of(context).pop();
      return;
    }

    showAuthMessage(context, res.msg);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const ProfilePageHeader(title: 'Edit Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Center(
                  child: Container(
                    width:  100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                      color: colorScheme.primary.withValues(alpha: 0.06),
                    ),
                    child: Center(
                      child: HeroIcon(
                        HeroIcons.user,
                        style: HeroIconStyle.solid,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        size:  48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const ProfileFieldLabel(text: 'Username'),
                TextField(
                  controller: _username_ctrl,
                  decoration: profileFieldDecoration(
                    context,
                    hint: '@username',
                  ),
                ),
                const SizedBox(height: 20),
                const ProfileFieldLabel(text: 'Email Address'),
                TextField(
                  readOnly: true,
                  enabled: false,
                  controller: _email_ctrl,
                  decoration: profileFieldDecoration(
                    context,
                    hint: 'email@address.com',
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 32),
                ProfilePrimaryButton(
                  label: 'Save Changes',
                  isSaving: _is_saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
