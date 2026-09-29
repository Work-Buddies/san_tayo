import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

/// Maroon top bar with circular back control and white title.
class ProfilePageHeader extends StatelessWidget {
  final String title;

  const ProfilePageHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 20, 20),
      child: Row(
        children: [
          _ProfileBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.onPrimary.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width:  40,
          height: 40,
          child: Center(
            child: HeroIcon(
              HeroIcons.arrowLeft,
              style: HeroIconStyle.outline,
              color: colorScheme.onPrimary,
              size:  20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Uppercase grey section label above grouped rows.
class ProfileSectionLabel extends StatelessWidget {
  final String label;

  const ProfileSectionLabel({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// White rounded card wrapping a vertical list of [ProfileMenuRow] children.
class ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileMenuCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Single tappable row with icon, title, optional subtitle, and chevron.
class ProfileMenuRow extends StatelessWidget {
  final HeroIcons icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showDivider;

  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width:  40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HeroIcon(
                        icon,
                        style: HeroIconStyle.outline,
                        color: colorScheme.primary,
                        size:  20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  HeroIcon(
                    HeroIcons.chevronRight,
                    style: HeroIconStyle.outline,
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                    size:  18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}

/// Full-width maroon primary button used on edit/password screens.
class ProfilePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSaving;

  const ProfilePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isSaving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width:  22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
      ),
    );
  }
}

/// Label + field stack for profile forms.
class ProfileFieldLabel extends StatelessWidget {
  final String text;

  const ProfileFieldLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

InputDecoration profileFieldDecoration(
  BuildContext context, {
  String? hint,
  bool enabled = true,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    filled: true,
    fillColor: enabled
        ? Colors.white
        : colorScheme.onSurface.withValues(alpha: 0.08),
    hintText: hint,
    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.15)),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    ),
  );
}
