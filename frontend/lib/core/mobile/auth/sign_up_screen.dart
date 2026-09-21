import 'package:flutter/material.dart';

import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';
import '../global_widgets/auth_buttons.dart';
import '../global_widgets/auth_form_fields.dart';
import '../global_widgets/auth_scaffold.dart';
import 'auth_helpers.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email    = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    // Catch the obvious problems here so an incomplete form never costs a round trip.
    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      showAuthMessage(context, 'Email, username and password are required.');
      return;
    }

    if (password.length < 8) {
      showAuthMessage(context, 'Password must be at least 8 characters.');
      return;
    }

    if (password != confirm) {
      showAuthMessage(context, 'Passwords do not match.');
      return;
    }

    setState(() => _isSaving = true);

    final params = {
      'email':    email,
      'username': username,
      'password': password,
    };
    final res = await api_request('POST', ApiEndpoints.auth_register, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    showAuthMessage(context, res.msg);

    if (res.code != 1) {
      return;
    }

    // The account now exists but sits at the unverified auth level, so replace this
    // screen with the OTP step — coming back to a filled-in Sign Up form is useless.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      panelChildren: [
        Text('Sign Up',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 20),
        const PanelLabel(text: 'Email'),
        const SizedBox(height: 8),
        AuthTextField(
          controller:   _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          hint:         'juan.dela.cruz@gmail.com',
        ),
        const SizedBox(height: 16),
        const PanelLabel(text: 'Username'),
        const SizedBox(height: 8),
        AuthTextField(
          controller: _usernameCtrl,
          hint:       'juandelacruz_',
        ),
        const SizedBox(height: 16),
        const PanelLabel(text: 'Password'),
        const SizedBox(height: 8),
        AuthTextField(
          controller:  _passwordCtrl,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        const PanelLabel(text: 'Confirm Password'),
        const SizedBox(height: 8),
        AuthTextField(
          controller:      _confirmCtrl,
          obscureText:     true,
          textInputAction: TextInputAction.done,
          onSubmitted:     (_) => _signUp(),
        ),
        const SizedBox(height: 20),
        SubmitButton(label: 'Sign Up', isSaving: _isSaving, onPressed: _signUp),
        const SizedBox(height: 24),
        PanelLink(
          text:      'I have an account.',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
