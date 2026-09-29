import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

/// Password [TextField] with a trailing eye control to show or hide the value.
class PasswordRevealField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Color? visibilityIconColor;

  const PasswordRevealField({
    super.key,
    required this.controller,
    required this.decoration,
    this.style,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.visibilityIconColor,
  });

  @override
  State<PasswordRevealField> createState() => _PasswordRevealFieldState();
}

class _PasswordRevealFieldState extends State<PasswordRevealField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final icon_color = widget.visibilityIconColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.45);

    return TextField(
      controller:      widget.controller,
      enabled:         widget.enabled,
      obscureText:     _obscure,
      textInputAction: widget.textInputAction,
      onSubmitted:     widget.onSubmitted,
      style:           widget.style,
      decoration: widget.decoration.copyWith(
        suffixIcon: IconButton(
          onPressed: widget.enabled
              ? () => setState(() => _obscure = !_obscure)
              : null,
          icon: HeroIcon(
            _obscure ? HeroIcons.eye : HeroIcons.eyeSlash,
            style: HeroIconStyle.outline,
            size:  20,
            color: icon_color,
          ),
        ),
      ),
    );
  }
}
