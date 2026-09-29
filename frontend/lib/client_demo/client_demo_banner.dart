import 'package:flutter/material.dart';

import 'package:san_tayo/client_demo/client_demo_config.dart';

/// Thin strip so testers know they are on a local demo build.
class ClientDemoBanner extends StatelessWidget {
  final Widget child;

  const ClientDemoBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!is_client_demo_enabled) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: colorScheme.secondary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: colorScheme.onSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo build — no server. OTP: $kClientDemoOtpCode',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
