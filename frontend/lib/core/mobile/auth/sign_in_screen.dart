import 'package:flutter/material.dart';

import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';
import '../global_widgets/auth_buttons.dart';
import '../global_widgets/auth_form_fields.dart';
import '../global_widgets/auth_scaffold.dart';
import 'auth_helpers.dart';
import 'otp_verification_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  /// Set by the splash screen when it could not reach the server. The form starts locked
  /// and the user has to tap Retry once they are back on a network.
  final bool isOffline;

  const SignInScreen({
    super.key,
    this.isOffline = false,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSaving   = false;
  bool _isOffline  = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.isOffline;

    if (_isOffline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showAuthMessage(context, 'You are offline or on an unstable network. Signing in is unavailable.');
        }
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Re-probe the server and unlock the form if it answers.
  Future<void> _retryConnection() async {
    setState(() => _isRetrying = true);

    final probe = await api_request('GET', ApiEndpoints.health);

    if (!mounted) {
      return;
    }

    setState(() {
      _isRetrying = false;
      _isOffline  = probe.is_network_error;
    });

    showAuthMessage(
      context,
      _isOffline
          ? 'Still offline. Check your connection and try again.'
          : 'Back online. You can sign in now.',
    );
  }

  Future<void> _signIn() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      showAuthMessage(context, 'Email and password are required.');
      return;
    }

    setState(() => _isSaving = true);

    final params = {
      'email':    email,
      'password': password,
    };
    final res = await api_request('POST', ApiEndpoints.auth_login, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (res.code == 1 && res.data != null) {
      await finishSignIn(context, res.data);
      return;
    }

    // The connection dropped between the splash probe and this attempt — relock the form.
    if (res.is_network_error) {
      setState(() => _isOffline = true);
    }

    showAuthMessage(context, res.msg);

    // Credentials were fine but the account never cleared OTP — hand off to verification.
    // No code was just sent, so the resend button is available immediately.
    if (res.data is Map && res.data['needs_verification'] == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email, cooldownSeconds: 0),
        ),
      );
    }
  }

  void _goToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      panelChildren: [
        Text('Sign In',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 28),
        const PanelLabel(text: 'Email'),
        const SizedBox(height: 8),
        AuthTextField(
          controller:      _emailCtrl,
          enabled:         !_isOffline,
          keyboardType:    TextInputType.emailAddress,
          hint:            'your_email@gmail.com',
        ),
        const SizedBox(height: 20),
        const PanelLabel(text: 'Password'),
        const SizedBox(height: 8),
        AuthPasswordField(
          controller:      _passwordCtrl,
          enabled:         !_isOffline,
          textInputAction: TextInputAction.done,
          onSubmitted:     (_) => _signIn(),
          hint:            '••••••••',
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isOffline
                ? null
                : () => showAuthMessage(context, 'Password recovery is not available yet.'),
            child: Text('forgot password?',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_isOffline)
          RetryBanner(isRetrying: _isRetrying, onRetry: _retryConnection)
        else
          SubmitButton(label: 'Sign In', isSaving: _isSaving, onPressed: _signIn),
        const SizedBox(height: 24),
        PanelLink(
          text:      "I don't have an account.",
          onPressed: _isOffline ? null : _goToSignUp,
        ),
      ],
    );
  }
}
