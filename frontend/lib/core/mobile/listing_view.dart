import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/mobile/global_widgets/listing_card.dart';

/// Place page: banner, logo, description, then Menu or Gallery.
class ListingView extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ListingView({
    super.key,
    required this.listing,
  });

  @override
  State<ListingView> createState() => _ListingViewState();
}

class _ListingViewState extends State<ListingView> {
  int _tab = 0;

  String get _name {
    return widget.listing['name']?.toString()
        ?? widget.listing['title']?.toString()
        ?? '';
  }

  String get _landmark {
    return widget.listing['nearestLandmark']?.toString() ?? '';
  }

  List<Map<String, dynamic>> get _groups {
    final groups = widget.listing['menu_groups'];
    if (groups is! List) {
      return [];
    }
    return groups.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  List<Map<String, dynamic>> get _gallery {
    final images = widget.listing['gallery'];
    if (images is! List) {
      return [];
    }
    return images.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  List<String> get _food_types {
    final types = widget.listing['food_types'];
    if (types is! List) {
      return [];
    }
    return types.map((type) {
      if (type is Map) {
        return type['name']?.toString() ?? '';
      }
      return type.toString();
    }).where((name) => name.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final top         = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: _Photo(
                  provider: image_provider_from(widget.listing['banner']),
                ),
              ),
              Positioned(
                top: top + 8,
                left: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: HeroIcon(
                      HeroIcons.arrowLeft,
                      style: HeroIconStyle.solid,
                      color: colorScheme.onSurface,
                      size:  20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: -28,
                child: Container(
                  width:  72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _Photo(
                    provider: image_provider_from(widget.listing['logo']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  widget.listing['description']?.toString() ?? '',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                if (_landmark.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeroIcon(
                          HeroIcons.mapPin,
                          style: HeroIconStyle.solid,
                          size:  14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _landmark,
                            style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_food_types.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in _food_types)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.12)),
                          ),
                          child: Text(name, style: textTheme.labelSmall),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListingTabButton(
                          label: 'MENU',
                          selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListingTabButton(
                          label: 'GALLERY',
                          selected: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_tab == 0) _MenuBody(groups: _groups) else _GalleryBody(images: _gallery),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner, logo, menu thumb, or gallery tile. Gray when there is no photo.
class _Photo extends StatelessWidget {
  final ImageProvider? provider;

  const _Photo({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider == null) {
      return const ColoredBox(color: Color(0xFF4A4A4A));
    }
    return Image(image: provider!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }
}

/// Maroon fill when selected, white with a maroon border when not.
class ListingTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ListingTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? colorScheme.onPrimary : colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuBody extends StatelessWidget {
  final List<Map<String, dynamic>> groups;

  const _MenuBody({required this.groups});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (groups.isEmpty) {
      return Text(
        'No menu yet.',
        style: textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Text(
            (group['group_name']?.toString() ?? '').toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in (group['items'] as List? ?? const []))
            if (item is Map)
              MenuItemRow(item: Map<String, dynamic>.from(item)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// One dish: thumb, name, description, price on the right.
class MenuItemRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const MenuItemRow({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final price       = item['price'];
    final value       = price is num ? price : num.tryParse(price?.toString() ?? '') ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width:  44,
              height: 44,
              child: _Photo(provider: image_provider_from(item['image'] ?? item['image_base64'])),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['item']?.toString() ?? '', style: textTheme.titleSmall),
                if ((item['description']?.toString() ?? '').isNotEmpty)
                  Text(
                    item['description'].toString(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  final List<Map<String, dynamic>> images;

  const _GalleryBody({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Text(
        'No photos yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tile = (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < images.length; i++)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: i % 7 == 5 ? tile * 2 + 12 : tile,
                  height: tile * 0.85,
                  child: _Photo(
                    provider: image_provider_from(
                      images[i]['image'] ?? images[i]['img_base64'],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
