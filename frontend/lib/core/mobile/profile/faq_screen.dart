import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/mobile/profile/app_copy.dart';
import 'package:san_tayo/core/mobile/profile/profile_widgets.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _expanded_index;

  @override
  void initState() {
    super.initState();
    _expanded_index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const ProfilePageHeader(title: 'Help & FAQ'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: faq_items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item     = faq_items[index];
                final expanded = _expanded_index == index;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expanded_index = expanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.question,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              HeroIcon(
                                expanded ? HeroIcons.chevronUp : HeroIcons.chevronDown,
                                style: HeroIconStyle.outline,
                                size:  18,
                                color: colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                            ],
                          ),
                          if (expanded) ...[
                            const SizedBox(height: 10),
                            Text(
                              item.answer,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.65),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
