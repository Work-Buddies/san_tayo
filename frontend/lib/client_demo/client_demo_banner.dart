import 'package:flutter/material.dart';

import 'package:san_tayo/client_demo/client_demo_config.dart';

/// Floating demo label. Overlays the UI so maroon headers keep the same height.
class ClientDemoBanner extends StatelessWidget {
  final Widget child;

  const ClientDemoBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!is_client_demo_enabled) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final top         = MediaQuery.viewPaddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top:  top + 4,
          left: 12,
          right: 12,
          child: IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:        colorScheme.secondary.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'Demo — no server · OTP $kClientDemoOtpCode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:      colorScheme.onSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
