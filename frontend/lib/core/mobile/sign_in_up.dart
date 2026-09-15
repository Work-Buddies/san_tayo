import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_endpoints.dart';
import '../network/api_client.dart';
import '../network/session.dart';
import 'dashboard.dart';

/* SHARED HELPERS */

/// Cream pill-shaped input used by every field on the auth screens. The placeholder is a
/// washed-out maroon so it reads clearly as a hint rather than as entered text.
InputDecoration _field_decoration(BuildContext context, {String? hint}) {
  return InputDecoration(
    filled:         true,
    fillColor:      Theme.of(context).colorScheme.surface,
    hintText:       hint,
    hintStyle:      Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    // Disabling a field must not wash out the cream fill, so repeat it for that state.
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   BorderSide.none,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   BorderSide.none,
    ),
  );
}

/// Typed input text, in full-strength maroon.
TextStyle? _field_text_style(BuildContext context) {
  return Theme.of(context).textTheme.labelMedium?.copyWith(
    color: Theme.of(context).colorScheme.primary,
  );
}

/// Logo, wordmark and motto block shown above the form panel.
Widget _brand_header(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        Image.asset(
          'assets/images/logo/logo.png',
          height: 100,
        ),
        Column(
          children: [
            Text("Sa'n Tayo?",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text("\"Application Motto Insert Here!\"",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Field label rendered on the maroon panel.
Widget _panel_label(BuildContext context, String text) {
  return Text(text,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onPrimary,
    ),
  );
}

/// Rounded accent button. Goes flat and unresponsive while its request is in flight.
Widget _submit_button(BuildContext context, {
  required String label,
  required bool is_saving,
  required VoidCallback on_pressed,
}) {
  return Center(
    child: FilledButton(
      onPressed: is_saving ? null : on_pressed,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        padding:         const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
        shape:           const StadiumBorder(),
      ),
      child: is_saving
          ? const SizedBox(
              width:  18,
              height: 18,
              child:  CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
    ),
  );
}

/// Underlined link that swaps between the Sign In and Sign Up screens.
/// A null [on_pressed] renders it disabled.
Widget _panel_link(BuildContext context, String text, VoidCallback? on_pressed) {
  return TextButton(
    onPressed: on_pressed,
    style: TextButton.styleFrom(padding: EdgeInsets.zero),
    child: Text(text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color:           Theme.of(context).colorScheme.onPrimary,
        decoration:      TextDecoration.underline,
        decorationColor: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
  );
}

/// Shown in place of the Sign In button while the server is unreachable.
Widget _retry_banner(BuildContext context, {
  required bool is_retrying,
  required VoidCallback on_retry,
}) {
  return Column(
    children: [
      Text(
        'No connection to the server.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      const SizedBox(height: 12),
      _submit_button(
        context,
        label:      'Retry',
        is_saving:  is_retrying,
        on_pressed: on_retry,
      ),
    ],
  );
}

/// Brand header on top, maroon form panel pinned below it. The whole page scrolls
/// once the keyboard opens so the taller Sign Up form never overflows.
Widget _auth_scaffold(BuildContext context, List<Widget> panel_children) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(child: _brand_header(context)),
                  Container(
                    width:   double.infinity,
                    padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft:  Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: panel_children,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Surface an API message to the user.
void _show_message(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Hide most of the local part of an email: juan.dela.cruz@gmail.com -> j**********ruz@gmail.com
String _mask_email(String email) {
  final at = email.indexOf('@');

  if (at < 2) {
    return email;
  }

  final local  = email.substring(0, at);
  final domain = email.substring(at);

  // Too short to keep a readable tail, so only the first character survives.
  if (local.length <= 4) {
    return '${local[0]}${'*' * (local.length - 1)}$domain';
  }

  return '${local[0]}${'*' * (local.length - 4)}${local.substring(local.length - 3)}$domain';
}

/// Persist the issued token so the session survives an app close, then drop the user on
/// the dashboard with no way back into auth.
Future<void> _finish_sign_in(BuildContext context, dynamic data) async {
  await save_session(data['token']?.toString(), data['account']);

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const Dashboard()),
    (route) => false,
  );
}

/* SIGN IN */

class SignInUp extends StatefulWidget {
  /// Set by the splash screen when it could not reach the server. The form starts locked
  /// and the user has to tap Retry once they are back on a network.
  final bool is_offline;

  const SignInUp({super.key, this.is_offline = false});

  @override
  State<SignInUp> createState() => _SignInUpState();
}

class _SignInUpState extends State<SignInUp> {
  final _email_ctrl    = TextEditingController();
  final _password_ctrl = TextEditingController();

  bool _is_saving   = false;
  bool _is_offline  = false;
  bool _is_retrying = false;

  @override
  void initState() {
    super.initState();
    _is_offline = widget.is_offline;

    if (_is_offline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _show_message(context, 'You are offline or on an unstable network. Signing in is unavailable.');
        }
      });
    }
  }

  @override
  void dispose() {
    _email_ctrl.dispose();
    _password_ctrl.dispose();
    super.dispose();
  }

  /// Re-probe the server and unlock the form if it answers.
  Future<void> _retry_connection() async {
    setState(() => _is_retrying = true);

    final probe = await api_request('GET', ApiEndpoints.health);

    if (!mounted) {
      return;
    }

    setState(() {
      _is_retrying = false;
      _is_offline  = probe.is_network_error;
    });

    _show_message(
      context,
      _is_offline
          ? 'Still offline. Check your connection and try again.'
          : 'Back online. You can sign in now.',
    );
  }

  Future<void> _sign_in() async {
    final email    = _email_ctrl.text.trim();
    final password = _password_ctrl.text;

    if (email.isEmpty || password.isEmpty) {
      _show_message(context, 'Email and password are required.');
      return;
    }

    setState(() => _is_saving = true);

    final params = {
      'email':    email,
      'password': password,
    };
    final res = await api_request('POST', ApiEndpoints.auth_login, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _is_saving = false);

    if (res.code == 1 && res.data != null) {
      await _finish_sign_in(context, res.data);
      return;
    }

    // The connection dropped between the splash probe and this attempt — relock the form.
    if (res.is_network_error) {
      setState(() => _is_offline = true);
    }

    _show_message(context, res.msg);

    // Credentials were fine but the account never cleared OTP — hand off to verification.
    // No code was just sent, so the resend button is available immediately.
    if (res.data is Map && res.data['needs_verification'] == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerification(email: email, cooldown_seconds: 0),
        ),
      );
    }
  }

  void _go_to_sign_up() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _auth_scaffold(context, [
      Text('Sign In',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      const SizedBox(height: 28),
      _panel_label(context, 'Email'),
      const SizedBox(height: 8),
      TextField(
        controller:       _email_ctrl,
        enabled:          !_is_offline,
        keyboardType:     TextInputType.emailAddress,
        textInputAction:  TextInputAction.next,
        style:            _field_text_style(context),
        decoration:       _field_decoration(context, hint: 'your_email@gmail.com'),
      ),
      const SizedBox(height: 20),
      _panel_label(context, 'Password'),
      const SizedBox(height: 8),
      TextField(
        controller:      _password_ctrl,
        enabled:         !_is_offline,
        obscureText:     true,
        textInputAction: TextInputAction.done,
        onSubmitted:     (_) => _sign_in(),
        style:           _field_text_style(context),
        decoration:      _field_decoration(context, hint: '••••••••'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _is_offline
              ? null
              : () => _show_message(context, 'Password recovery is not available yet.'),
          child: Text('forgot password?',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      if (_is_offline)
        _retry_banner(context, is_retrying: _is_retrying, on_retry: _retry_connection)
      else
        _submit_button(context, label: 'Sign In', is_saving: _is_saving, on_pressed: _sign_in),
      const SizedBox(height: 24),
      _panel_link(context, "I don't have an account.", _is_offline ? null : _go_to_sign_up),
    ]);
  }
}

/* SIGN UP */

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _email_ctrl    = TextEditingController();
  final _username_ctrl = TextEditingController();
  final _password_ctrl = TextEditingController();
  final _confirm_ctrl  = TextEditingController();

  bool _is_saving = false;

  @override
  void dispose() {
    _email_ctrl.dispose();
    _username_ctrl.dispose();
    _password_ctrl.dispose();
    _confirm_ctrl.dispose();
    super.dispose();
  }

  Future<void> _sign_up() async {
    final email    = _email_ctrl.text.trim();
    final username = _username_ctrl.text.trim();
    final password = _password_ctrl.text;
    final confirm  = _confirm_ctrl.text;

    // Catch the obvious problems here so an incomplete form never costs a round trip.
    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      _show_message(context, 'Email, username and password are required.');
      return;
    }

    if (password.length < 8) {
      _show_message(context, 'Password must be at least 8 characters.');
      return;
    }

    if (password != confirm) {
      _show_message(context, 'Passwords do not match.');
      return;
    }

    setState(() => _is_saving = true);

    final params = {
      'email':    email,
      'username': username,
      'password': password,
    };
    final res = await api_request('POST', ApiEndpoints.auth_register, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _is_saving = false);
    _show_message(context, res.msg);

    if (res.code != 1) {
      return;
    }

    // The account now exists but sits at the unverified auth level, so replace this
    // screen with the OTP step — coming back to a filled-in Sign Up form is useless.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OtpVerification(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _auth_scaffold(context, [
      Text('Sign Up',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      const SizedBox(height: 20),
      _panel_label(context, 'Email'),
      const SizedBox(height: 8),
      TextField(
        controller:      _email_ctrl,
        keyboardType:    TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style:           _field_text_style(context),
        decoration:      _field_decoration(context, hint: 'juan.dela.cruz@gmail.com'),
      ),
      const SizedBox(height: 16),
      _panel_label(context, 'Username'),
      const SizedBox(height: 8),
      TextField(
        controller:      _username_ctrl,
        textInputAction: TextInputAction.next,
        style:           _field_text_style(context),
        decoration:      _field_decoration(context, hint: 'juandelacruz_'),
      ),
      const SizedBox(height: 16),
      _panel_label(context, 'Password'),
      const SizedBox(height: 8),
      TextField(
        controller:      _password_ctrl,
        obscureText:     true,
        textInputAction: TextInputAction.next,
        style:           _field_text_style(context),
        decoration:      _field_decoration(context),
      ),
      const SizedBox(height: 16),
      _panel_label(context, 'Confirm Password'),
      const SizedBox(height: 8),
      TextField(
        controller:      _confirm_ctrl,
        obscureText:     true,
        textInputAction: TextInputAction.done,
        onSubmitted:     (_) => _sign_up(),
        style:           _field_text_style(context),
        decoration:      _field_decoration(context),
      ),
      const SizedBox(height: 20),
      _submit_button(context, label: 'Sign Up', is_saving: _is_saving, on_pressed: _sign_up),
      const SizedBox(height: 24),
      _panel_link(context, 'I have an account.', () => Navigator.of(context).pop()),
    ]);
  }
}

/* OTP VERIFICATION */

class OtpVerification extends StatefulWidget {
  final String email;

  /// Seconds to block the resend link for on arrival. Sign Up passes the full window
  /// because a code was just mailed; Sign In passes 0 because it did not send one.
  final int cooldown_seconds;

  const OtpVerification({
    super.key,
    required this.email,
    this.cooldown_seconds = 120,
  });

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  static const int _code_length = 4;

  final _code_ctrls = List.generate(_code_length, (_) => TextEditingController());
  final _code_nodes = List.generate(_code_length, (_) => FocusNode());

  Timer? _countdown;
  int  _seconds_left = 0;
  bool _is_saving    = false;
  bool _is_resending = false;

  @override
  void initState() {
    super.initState();
    _start_countdown(widget.cooldown_seconds);
  }

  @override
  void dispose() {
    _countdown?.cancel();

    for (final ctrl in _code_ctrls) {
      ctrl.dispose();
    }
    for (final node in _code_nodes) {
      node.dispose();
    }

    super.dispose();
  }

  /// Tick the resend cooldown down to zero, replacing any timer already running.
  void _start_countdown(int seconds) {
    _countdown?.cancel();

    setState(() => _seconds_left = seconds);

    if (seconds <= 0) {
      return;
    }

    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _seconds_left--);

      if (_seconds_left <= 0) {
        timer.cancel();
      }
    });
  }

  /// Hop to the next box once a digit lands, and back a box when one is deleted.
  void _on_code_changed(int index, String value) {
    if (value.isNotEmpty && index < _code_length - 1) {
      _code_nodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _code_nodes[index - 1].requestFocus();
    }
  }

  void _clear_code() {
    for (final ctrl in _code_ctrls) {
      ctrl.clear();
    }

    _code_nodes.first.requestFocus();
  }

  Future<void> _verify_otp() async {
    final code = _code_ctrls.map((ctrl) => ctrl.text).join();

    if (code.length != _code_length) {
      _show_message(context, 'Enter all $_code_length digits.');
      return;
    }

    setState(() => _is_saving = true);

    final params = {
      'email': widget.email,
      'code':  code,
    };
    final res = await api_request('POST', ApiEndpoints.auth_verify_otp, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _is_saving = false);

    if (res.code == 1 && res.data != null) {
      await _finish_sign_in(context, res.data);
      return;
    }

    _show_message(context, res.msg);
    _clear_code();
  }

  Future<void> _resend_otp() async {
    if (_seconds_left > 0 || _is_resending) {
      return;
    }

    setState(() => _is_resending = true);

    final params = {'email': widget.email};
    final res    = await api_request('POST', ApiEndpoints.auth_resend_otp, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _is_resending = false);
    _show_message(context, res.msg);

    // The server owns the real cooldown, so mirror whatever window it reports back.
    final retry_after = res.data is Map ? res.data['retry_after'] : null;
    _start_countdown(retry_after is int ? retry_after : 60);
  }

  /// One digit box. maxLength with an empty counter keeps the box from growing a "0/1" label.
  Widget _code_box(int index) {
    return SizedBox(
      width:  64,
      height: 64,
      child: TextField(
        controller:       _code_ctrls[index],
        focusNode:        _code_nodes[index],
        textAlign:        TextAlign.center,
        keyboardType:     TextInputType.number,
        maxLength:        1,
        inputFormatters:  [FilteringTextInputFormatter.digitsOnly],
        onChanged:        (value) => _on_code_changed(index, value),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled:      true,
          fillColor:   Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final on_primary = Theme.of(context).colorScheme.onPrimary;
    int minutes = _seconds_left ~/ 60;
    int seconds = _seconds_left % 60;
    String timer = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    String resend_test = _seconds_left > 0 ? 'Resend in ${timer}' : 'Resend now';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  Image.asset(
                    'assets/images/logo/logo_light.png',
                    height: 32,
                  ),
                  Text("Sa'n Tayo?",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color:    on_primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/images/icons/otp_email_icon.png',
                  height: 180,
                ),
              ),
              const SizedBox(height: 24),
              Text('Account Verification',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: on_primary,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Please enter the $_code_length-digit code we sent to your email ('),
                    TextSpan(
                      text:  _mask_email(widget.email),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ').'),
                  ],
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: on_primary,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_code_length, _code_box),
              ),
              const SizedBox(height: 28),
              _submit_button(context, label: 'Submit', is_saving: _is_saving, on_pressed: _verify_otp),
              const SizedBox(height: 28),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Did not receive the email? ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: on_primary,
                      ),
                    ),
                    // Stays inert until the cooldown reaches zero.
                    GestureDetector(
                      onTap: _seconds_left > 0 ? null : _resend_otp,
                      child: Text(
                        resend_test,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:           on_primary,
                          fontWeight:      FontWeight.w700,
                          decoration:      TextDecoration.underline,
                          decorationColor: on_primary,
                        ),
                      ),
                    ),
                    Text('.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: on_primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
