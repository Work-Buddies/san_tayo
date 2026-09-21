import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';
import '../global_widgets/auth_buttons.dart';
import 'auth_helpers.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  /// Seconds to block the resend link for on arrival. Sign Up passes the full window
  /// because a code was just mailed; Sign In passes 0 because it did not send one.
  final int cooldownSeconds;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.cooldownSeconds = 120,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _codeLength = 4;

  final _codeCtrls = List.generate(_codeLength, (_) => TextEditingController());
  final _codeNodes = List.generate(_codeLength, (_) => FocusNode());

  Timer? _countdown;
  int  _secondsLeft = 0;
  bool _isSaving    = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.cooldownSeconds);
  }

  @override
  void dispose() {
    _countdown?.cancel();

    for (final ctrl in _codeCtrls) {
      ctrl.dispose();
    }
    for (final node in _codeNodes) {
      node.dispose();
    }

    super.dispose();
  }

  /// Tick the resend cooldown down to zero, replacing any timer already running.
  void _startCountdown(int seconds) {
    _countdown?.cancel();

    setState(() => _secondsLeft = seconds);

    if (seconds <= 0) {
      return;
    }

    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        timer.cancel();
      }
    });
  }

  /// Hop to the next box once a digit lands, and back a box when one is deleted.
  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeLength - 1) {
      _codeNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _codeNodes[index - 1].requestFocus();
    }
  }

  void _clearCode() {
    for (final ctrl in _codeCtrls) {
      ctrl.clear();
    }

    _codeNodes.first.requestFocus();
  }

  Future<void> _verifyOtp() async {
    final code = _codeCtrls.map((ctrl) => ctrl.text).join();

    if (code.length != _codeLength) {
      showAuthMessage(context, 'Enter all $_codeLength digits.');
      return;
    }

    setState(() => _isSaving = true);

    final params = {
      'email': widget.email,
      'code':  code,
    };
    final res = await api_request('POST', ApiEndpoints.auth_verify_otp, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (res.code == 1 && res.data != null) {
      await finishSignIn(context, res.data);
      return;
    }

    showAuthMessage(context, res.msg);
    _clearCode();
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0 || _isResending) {
      return;
    }

    setState(() => _isResending = true);

    final params = {'email': widget.email};
    final res    = await api_request('POST', ApiEndpoints.auth_resend_otp, body: params);

    if (!mounted) {
      return;
    }

    setState(() => _isResending = false);
    showAuthMessage(context, res.msg);

    // The server owns the real cooldown, so mirror whatever window it reports back.
    final retryAfter = res.data is Map ? res.data['retry_after'] : null;
    _startCountdown(retryAfter is int ? retryAfter : 60);
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final minutes   = _secondsLeft ~/ 60;
    final seconds   = _secondsLeft % 60;
    final timer     = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    final resendText = _secondsLeft > 0 ? 'Resend in $timer' : 'Resend now';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _OtpBrandRow(),
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
                  color: onPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Please enter the $_codeLength-digit code we sent to your email ('),
                    TextSpan(
                      text:  maskEmail(widget.email),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ').'),
                  ],
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onPrimary,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (index) {
                  return _OtpCodeBox(
                    controller: _codeCtrls[index],
                    focusNode:  _codeNodes[index],
                    onChanged:  (value) => _onCodeChanged(index, value),
                  );
                }),
              ),
              const SizedBox(height: 28),
              SubmitButton(label: 'Submit', isSaving: _isSaving, onPressed: _verifyOtp),
              const SizedBox(height: 28),
              _ResendRow(
                onPrimary:  onPrimary,
                resendText: resendText,
                onResend:   _secondsLeft > 0 ? null : _resendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact wordmark used at the top of the OTP screen.
class _OtpBrandRow extends StatelessWidget {
  const _OtpBrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Image.asset(
          'assets/images/logo/logo_light.png',
          height: 32,
        ),
        Text("Sa'n Tayo?",
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color:    Theme.of(context).colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

/// One digit box. maxLength with an empty counter keeps the box from growing a "0/1" label.
class _OtpCodeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpCodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  64,
      height: 64,
      child: TextField(
        controller:      controller,
        focusNode:       focusNode,
        textAlign:       TextAlign.center,
        keyboardType:    TextInputType.number,
        maxLength:       1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged:       onChanged,
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
}

class _ResendRow extends StatelessWidget {
  final Color onPrimary;
  final String resendText;
  final VoidCallback? onResend;

  const _ResendRow({
    required this.onPrimary,
    required this.resendText,
    this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: onPrimary,
    );

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Did not receive the email? ', style: style),
          // Stays inert until the cooldown reaches zero.
          GestureDetector(
            onTap: onResend,
            child: Text(
              resendText,
              style: style?.copyWith(
                fontWeight:      FontWeight.w700,
                decoration:      TextDecoration.underline,
                decorationColor: onPrimary,
              ),
            ),
          ),
          Text('.', style: style),
        ],
      ),
    );
  }
}
