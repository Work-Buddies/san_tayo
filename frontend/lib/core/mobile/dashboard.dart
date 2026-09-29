import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/cache/app_cache.dart';
import 'package:san_tayo/core/mobile/global_widgets/change_landmark_sheet.dart';
import 'package:san_tayo/core/mobile/global_widgets/listing_card.dart';
import 'package:san_tayo/core/mobile/listing_view.dart';
import 'package:san_tayo/core/mobile/profile/profile_screen.dart';
import 'package:san_tayo/core/mobile/search_filters_screen.dart';

/// Mock listings that stand in for the Laravel listings endpoint.
Future<List<Map<String, dynamic>>> get_listings() async {
  final raw  = await rootBundle.loadString('assets/data/mock-listing-data.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .whereType<Map>()
      .map((row) => normalize_listing(Map<String, dynamic>.from(row)))
      .toList();
}

/// One shape for cards and the listing page. Banner is never the account logo.
Map<String, dynamic> normalize_listing(Map<String, dynamic> raw) {
  final next = Map<String, dynamic>.from(raw);

  next['name'] = raw['name'] ?? raw['title'] ?? '';
  next['banner'] = raw['banner'] ?? raw['banner_base64'] ?? raw['image'];
  next['logo'] = raw['logo'] ?? raw['logo_base64'];

  final landmark = raw['landmark'];
  next['nearestLandmark'] = raw['nearestLandmark']
      ?? (landmark is Map ? landmark['name'] : null)
      ?? '';

  if (next['menu_groups'] is! List) {
    final flat = raw['menu'] ?? raw['menu_items'];
    next['menu_groups'] = flat is List
        ? [
            {'group_name': 'Menu', 'items': flat},
          ]
        : <Map<String, dynamic>>[];
  }

  next['gallery'] = raw['gallery'] ?? raw['listing_img'] ?? raw['images'] ?? <dynamic>[];
  next['minPrice'] = raw['minPrice'] ?? _min_menu_price(next['menu_groups']);
  _tag_food_types(next);
  return next;
}

/// Existing food-type rows are type foodtype.
/// ponytail: mock JSON has no pax tags, so a small set is attached here until listings come from the API.
void _tag_food_types(Map<String, dynamic> listing) {
  final types = listing['food_types'];
  if (types is! List) {
    listing['food_types'] = <Map<String, dynamic>>[];
    return;
  }

  var has_pax = false;
  for (final type in types) {
    if (type is! Map) {
      continue;
    }
    type['type'] ??= 'foodtype';
    if (type['type'] == 'pax') {
      has_pax = true;
    }
  }

  if (has_pax) {
    return;
  }

  const sets = [
    ['1 pax', '2 pax'],
    ['2 pax', '4 pax'],
    ['3 pax', '4 pax'],
    ['4 pax', '5+ pax'],
    ['1 pax', '5+ pax'],
  ];
  final bucket = (listing['id']?.toString() ?? '').hashCode.abs() % sets.length;
  for (final name in sets[bucket]) {
    types.add({
      'name': name,
      'type': 'pax',
      'description': 'Party size this place can seat.',
    });
  }
}

num _min_menu_price(dynamic groups) {
  num? lowest;
  if (groups is! List) {
    return 0;
  }

  for (final group in groups) {
    if (group is! Map) {
      continue;
    }
    final items = group['items'];
    if (items is! List) {
      continue;
    }
    for (final item in items) {
      if (item is! Map) {
        continue;
      }
      final price = item['price'];
      final value = price is num ? price : num.tryParse(price?.toString() ?? '');
      if (value == null) {
        continue;
      }
      if (lowest == null || value < lowest) {
        lowest = value;
      }
    }
  }

  return lowest ?? 0;
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _tabIndex = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _listings  = [];
  List<Map<String, dynamic>> _landmarks = [];
  Map<String, dynamic> _selected_landmark = {'name': default_landmark_name};

  @override
  void initState() {
    super.initState();
    _load_listings();
    _load_landmark_cache();
  }

  Future<void> _load_landmark_cache() async {
    final cached_list     = await get_cached_table('landmark');
    final cached_selected = await get_selected_landmark();
    final resolved        = resolve_selected_landmark(cached_selected, cached_list);

    if (!mounted) {
      return;
    }

    setState(() {
      _landmarks         = cached_list;
      _selected_landmark = resolved;
    });
  }

  Future<void> _open_landmark_sheet() async {
    if (_landmarks.isEmpty) {
      final list = await get_cached_table('landmark');
      if (!mounted) {
        return;
      }
      if (list.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Landmarks are not available yet.'),
          ));
        return;
      }
      setState(() => _landmarks = list);
    }

    if (!mounted) {
      return;
    }

    final picked = await show_change_landmark_sheet(
      context: context,
      landmarks: _landmarks,
      selected: _selected_landmark,
    );

    if (picked == null || !mounted) {
      return;
    }

    await save_selected_landmark(picked);
    if (!mounted) {
      return;
    }

    setState(() {
      _selected_landmark = picked;
    });
  }

  String get _selected_landmark_name {
    return _selected_landmark['name']?.toString() ?? default_landmark_name;
  }

  Future<void> _load_listings() async {
    final listings = await get_listings();
    if (!mounted) {
      return;
    }
    setState(() {
      _listings = listings;
      _loading  = false;
    });
  }

  void _open_search() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchFiltersScreen(
          landmarks: _landmarks,
          listings: _listings,
          selectedLandmark: _selected_landmark,
        ),
      ),
    );
  }

  void _open_listing(Map<String, dynamic> listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingView(listing: listing),
      ),
    );
  }

  void _open_profile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          landmarks: _landmarks,
          selectedLandmark: _selected_landmark,
          onLandmarkChanged: (picked) {
            setState(() => _selected_landmark = picked);
          },
        ),
      ),
    );
  }

  ListingCard _listing_card(Map<String, dynamic> listing, {bool fillHeight = false}) {
    return ListingCard(
      image: image_provider_from(listing['banner']),
      name: listing['name'].toString(),
      nearestLandmark: listing['nearestLandmark'].toString(),
      minPrice: listing['minPrice'] as num,
      fillHeight: fillHeight,
      onTap: () => _open_listing(listing),
    );
  }

  num _price_of(Map<String, dynamic> listing) {
    final price = listing['minPrice'];
    if (price is num) {
      return price;
    }
    return num.tryParse(price?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final landmark_q  = _selected_landmark_name.toLowerCase();
    final nearby = _listings
                    .where((p) => (p['nearestLandmark'] as String)
                        .toLowerCase()
                        .contains(landmark_q))
                    .toList()
                  ..sort((a, b) => _price_of(a).compareTo(_price_of(b)));
    final discover = _listings
                    .where((p) => !(p['nearestLandmark'] as String)
                        .toLowerCase()
                        .contains(landmark_q))
                    .toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          DashboardHeader(
            landmarkName: _selected_landmark_name,
            onLandmarkTap: _open_landmark_sheet,
            onSearchTap: _open_search,
            onProfileTap: _open_profile,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
              builder: (context, constraints) {
                // Titles plus a peek of Discover More stay on screen; Near you takes the rest.
                const reserved = 28.0 + 20.0 + 12.0 + 28.0 + 12.0 + 72.0;
                final near_height = (constraints.maxHeight - 20 - reserved).clamp(240.0, constraints.maxHeight);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Text('Near you', style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                      'Walking distance from your landmark',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: near_height,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: nearby.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 280,
                            child: _listing_card(nearby[index], fillHeight: true),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Discover More', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    for (final listing in discover) ...[
                      _listing_card(listing),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardNavBar(
        currentIndex: _tabIndex,
        onTap: (index) {
          if (index == 2) {
            _open_profile();
            return;
          }
          if (index == 1) {
            _open_search();
            return;
          }
          setState(() => _tabIndex = index);
        },
      ),
    );
  }
}

/// Maroon search header: wordmark, campus picker, search field, suggestion chips.
class DashboardHeader extends StatelessWidget {
  final String landmarkName;
  final VoidCallback onLandmarkTap;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;

  const DashboardHeader({
    super.key,
    required this.landmarkName,
    required this.onLandmarkTap,
    required this.onSearchTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/logo/logo.png'
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sa'n Tayo?",
                      style: textTheme.titleLarge?.copyWith(
                        fontFamily: 'MoreSugar',
                        color: colorScheme.onPrimary,
                        fontSize: 22,
                      ),
                    ),
                    GestureDetector(
                      onTap: onLandmarkTap,
                      child: Row(
                        children: [
                          HeroIcon(
                            HeroIcons.mapPin,
                            style: HeroIconStyle.solid,
                            size:  12,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              landmarkName,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          HeroIcon(
                            HeroIcons.chevronDown,
                            style: HeroIconStyle.solid,
                            size:  14,
                            color: colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: colorScheme.secondary.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onProfileTap,
                  child: Container(
                    width:  44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.secondary, width: 2),
                    ),
                    child: HeroIcon(
                      HeroIcons.user,
                      style: HeroIconStyle.solid,
                      color: colorScheme.onPrimary,
                      size:  22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            onTap: onSearchTap,
            decoration: InputDecoration(
              hintText: 'Search dishes, stalls, eateries',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              isDense: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: HeroIcon(
                  HeroIcons.magnifyingGlass,
                  style: HeroIconStyle.outline,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  size:  20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // const Wrap(     disable because of lack of logic flow for this.
          //   spacing: 8,
          //   runSpacing: 8,
          //   children: [
          //     SuggestionChip(icon: HeroIcons.mapPin, label: 'Nearby'),
          //     SuggestionChip(icon: HeroIcons.banknotes, label: 'Under ₱150'),
          //     SuggestionChip(icon: HeroIcons.clock, label: 'Lunch'),
          //   ],
          // ),
        ],
      ),
    );
  }
}

/// Sage suggestion pill used under the dashboard search field.
class SuggestionChip extends StatelessWidget {
  final HeroIcons icon;
  final String label;

  const SuggestionChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(
            icon,
            style: HeroIconStyle.solid,
            size:  14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Home / search / profile bar matching the dashboard mock.
class DashboardNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DashboardNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: HeroIcons.home,
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: HeroIcons.magnifyingGlass,
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: HeroIcons.user,
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final HeroIcons icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onTap,
      icon: HeroIcon(
        icon,
        style: selected ? HeroIconStyle.solid : HeroIconStyle.outline,
        color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.45),
        size:  26,
      ),
    );
  }
}
