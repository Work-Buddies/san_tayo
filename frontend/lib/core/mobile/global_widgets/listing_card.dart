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

/// Food-place card: photo, name, nearest landmark, and starting price.
/// [fillHeight] grows the photo when the parent gives the card a fixed height.
class ListingCard extends StatelessWidget {
  final ImageProvider? image;
  final String name;
  final String nearestLandmark;
  final num minPrice;
  final bool fillHeight;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    this.image,
    required this.name,
    required this.nearestLandmark,
    required this.minPrice,
    this.fillHeight = false,
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
          mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (fillHeight)
              Expanded(child: _CardPhoto(image: image))
            else
              AspectRatio(
                aspectRatio: 16 / 10,
                child: _CardPhoto(image: image),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPhoto extends StatelessWidget {
  final ImageProvider? image;

  const _CardPhoto({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const ColoredBox(color: Color(0xFF4A4A4A));
    }
    return Image(image: image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }
}
