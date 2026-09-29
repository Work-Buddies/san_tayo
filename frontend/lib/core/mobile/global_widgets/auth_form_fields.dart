import 'package:flutter/material.dart';

import 'password_reveal_field.dart';

/// Cream pill-shaped input used by every field on the auth screens. The placeholder is a
/// washed-out maroon so it reads clearly as a hint rather than as entered text.
InputDecoration authFieldDecoration(BuildContext context, {String? hint}) {
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
TextStyle? authFieldTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelMedium?.copyWith(
    color: Theme.of(context).colorScheme.primary,
  );
}

/// Cream pill text field used on Sign In and Sign Up.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    this.hint,
    this.enabled          = true,
    this.obscureText      = false,
    this.keyboardType,
    this.textInputAction  = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:      controller,
      enabled:         enabled,
      obscureText:     obscureText,
      keyboardType:    keyboardType,
      textInputAction: textInputAction,
      onSubmitted:     onSubmitted,
      style:           authFieldTextStyle(context),
      decoration:      authFieldDecoration(context, hint: hint),
    );
  }
}

/// Obscured auth field with a trailing eye toggle.
class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.hint,
    this.enabled         = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return PasswordRevealField(
      controller:      controller,
      enabled:         enabled,
      textInputAction: textInputAction,
      onSubmitted:     onSubmitted,
      style:           authFieldTextStyle(context),
      decoration:      authFieldDecoration(context, hint: hint),
    );
  }
}

/// Field label rendered on the maroon panel.
class PanelLabel extends StatelessWidget {
  final String text;

  const PanelLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
