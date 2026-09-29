import 'package:flutter/material.dart';
import 'package:san_tayo/core/mobile/profile/app_copy.dart';
import 'package:san_tayo/core/mobile/profile/profile_widgets.dart';

enum _LegalTab { terms, privacy }

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  _LegalTab _tab = _LegalTab.terms;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final doc         = _tab == _LegalTab.terms ? terms_sections : privacy_sections;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const ProfilePageHeader(title: 'Terms & Privacy Policy'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _LegalSegmentedControl(
              tab: _tab,
              onChanged: (next) => setState(() => _tab = next),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  'Last Updated: ${doc.lastUpdated}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                for (final section in doc.sections) ...[
                  Text(
                    section.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSegmentedControl extends StatelessWidget {
  final _LegalTab tab;
  final ValueChanged<_LegalTab> onChanged;

  const _LegalSegmentedControl({
    required this.tab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'TERMS',
              selected: tab == _LegalTab.terms,
              onTap: () => onChanged(_LegalTab.terms),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'PRIVACY',
              selected: tab == _LegalTab.privacy,
              onTap: () => onChanged(_LegalTab.privacy),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
