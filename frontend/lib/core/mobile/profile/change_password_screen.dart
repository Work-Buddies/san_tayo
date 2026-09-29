import 'package:flutter/material.dart';
import 'package:san_tayo/core/config/api_endpoints.dart';
import 'package:san_tayo/core/mobile/auth/auth_helpers.dart';
import 'package:san_tayo/core/mobile/profile/app_copy.dart';
import 'package:san_tayo/core/mobile/global_widgets/password_reveal_field.dart';
import 'package:san_tayo/core/mobile/profile/profile_widgets.dart';
import 'package:san_tayo/core/network/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current_ctrl = TextEditingController();
  final _new_ctrl     = TextEditingController();
  final _confirm_ctrl = TextEditingController();
  bool _is_saving = false;

  @override
  void dispose() {
    _current_ctrl.dispose();
    _new_ctrl.dispose();
    _confirm_ctrl.dispose();
    super.dispose();
  }

  String? _validate_client() {
    final current = _current_ctrl.text;
    final new_pw  = _new_ctrl.text;
    final confirm = _confirm_ctrl.text;

    if (current.isEmpty || new_pw.isEmpty || confirm.isEmpty) {
      return 'All password fields are required.';
    }

    if (new_pw.length < 8) {
      return 'New password must be at least 8 characters.';
    }

    if (!RegExp(r'[0-9]').hasMatch(new_pw)) {
      return 'New password must include a number.';
    }

    if (new_pw == current) {
      return 'New password must not match your current password.';
    }

    if (new_pw != confirm) {
      return 'New password and confirmation do not match.';
    }

    return null;
  }

  Future<void> _update() async {
    final client_msg = _validate_client();
    if (client_msg != null) {
      showAuthMessage(context, client_msg);
      return;
    }

    setState(() => _is_saving = true);

    final res = await api_request(
      'PUT',
      ApiEndpoints.account_password,
      body: {
        'current_password': _current_ctrl.text,
        'new_password':     _new_ctrl.text,
      },
    );

    if (!mounted) {
      return;
    }

    setState(() => _is_saving = false);

    if (res.code == 1) {
      showAuthMessage(context, res.msg);
      Navigator.of(context).pop();
      return;
    }

    showAuthMessage(context, res.msg);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const ProfilePageHeader(title: 'Change Password'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                const ProfileFieldLabel(text: 'Current Password'),
                PasswordRevealField(
                  controller: _current_ctrl,
                  decoration: profileFieldDecoration(context),
                  visibilityIconColor: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 20),
                const ProfileFieldLabel(text: 'New Password'),
                PasswordRevealField(
                  controller: _new_ctrl,
                  decoration: profileFieldDecoration(
                    context,
                    hint: 'Enter new password',
                  ),
                  visibilityIconColor: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 20),
                const ProfileFieldLabel(text: 'Confirm New Password'),
                PasswordRevealField(
                  controller: _confirm_ctrl,
                  decoration: profileFieldDecoration(
                    context,
                    hint: 'Re-enter new password',
                  ),
                  visibilityIconColor: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                        height: 1.45,
                      ),
                      children: [
                        TextSpan(
                          text: 'Password must: ',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: password_requirements_hint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ProfilePrimaryButton(
                  label: 'Update Password',
                  isSaving: _is_saving,
                  onPressed: _update,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
