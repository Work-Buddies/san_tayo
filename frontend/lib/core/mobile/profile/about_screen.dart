import 'package:flutter/material.dart';
import 'package:san_tayo/core/mobile/profile/app_copy.dart';
import 'package:san_tayo/core/mobile/profile/profile_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const ProfilePageHeader(title: "About Sa'n Tayo?"),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                Center(
                  child: Container(
                    width:  120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Image.asset(
                      'assets/images/logo/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  about_body,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Version $app_version',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Text(
              about_credit,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
