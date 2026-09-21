import 'package:flutter/material.dart';

/// Rounded accent button. Goes flat and unresponsive while its request is in flight.
class SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSaving;

  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: isSaving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          padding:         const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
          shape:           const StadiumBorder(),
        ),
        child: isSaving
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
}

/// Underlined link that swaps between the Sign In and Sign Up screens.
/// A null [onPressed] renders it disabled.
class PanelLink extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const PanelLink({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
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
}

/// Shown in place of the Sign In button while the server is unreachable.
class RetryBanner extends StatelessWidget {
  final bool isRetrying;
  final VoidCallback onRetry;

  const RetryBanner({
    super.key,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
        SubmitButton(
          label:     'Retry',
          isSaving:  isRetrying,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
