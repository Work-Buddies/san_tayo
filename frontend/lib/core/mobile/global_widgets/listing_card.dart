import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

/// Network URL or base64 (raw or data-URL). Null when there is no photo.
ImageProvider? image_provider_from(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty || raw == 'null') {
    return null;
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return NetworkImage(raw);
  }

  final payload = raw.contains(',') ? raw.split(',').last : raw;
  try {
    return MemoryImage(base64Decode(payload));
  } catch (_) {
    return null;
  }
}

/// Food-place card: photo, name, nearest landmark, starting price, and tags.
class ListingCard extends StatelessWidget {
  final ImageProvider? image;
  final String name;
  final String nearestLandmark;
  final num minPrice;
  final List<String> tags;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    this.image,
    required this.name,
    required this.nearestLandmark,
    required this.minPrice,
    required this.tags,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Card(
      color: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: image == null
                  ? const ColoredBox(color: Color(0xFF4A4A4A))
                  : Image(image: image!, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      HeroIcon(
                        HeroIcons.mapPin,
                        style: HeroIconStyle.solid,
                        size:  14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Near $nearestLandmark',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      HeroIcon(
                        HeroIcons.banknotes,
                        style: HeroIconStyle.solid,
                        size:  14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Price starts at ₱${minPrice.toStringAsFixed(2)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 6,
                        children: [
                          for (final tag in tags)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:        colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
