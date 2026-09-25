/// Which filter shortcut is open. A null section on the results pop means every accordion.
enum SearchFilterSection { saan, ano, magkano, ilan }

/// Filters collected on the search overlay and applied on the results screen.
class SearchQuery {
  final String text;
  final String? landmark_name;
  final List<String> food_types;
  final num? min_price;
  final num? max_price;
  final int? party_size;

  const SearchQuery({
    this.text           = '',
    this.landmark_name,
    this.food_types     = const [],
    this.min_price,
    this.max_price,
    this.party_size,
  });

  String get title {
    if (text.trim().isNotEmpty) {
      return text.trim();
    }
    return 'Results';
  }

  int get saan_count {
    final name = landmark_name?.trim() ?? '';
    return name.isEmpty ? 0 : 1;
  }

  int get ano_count => food_types.length;

  int get magkano_count {
    if (min_price != null || max_price != null) {
      return 1;
    }
    return 0;
  }

  int get ilan_count => party_size == null ? 0 : 1;

  int get settings_count => saan_count + ano_count + magkano_count + ilan_count;
}

/// Map the Magkano chip / custom fields to an inclusive min–max.
({num? min, num? max}) parse_budget_range(String? preset, String from_text, String to_text) {
  final from = num.tryParse(from_text.trim());
  final to   = num.tryParse(to_text.trim());
  if (from != null || to != null) {
    return (min: from, max: to);
  }

  switch (preset) {
    case 'Under ₱50':
      return (min: null, max: 50);
    case '₱50 – ₱100':
      return (min: 50, max: 100);
    case '₱100–₱200':
      return (min: 100, max: 200);
    case '₱200–₱500':
      return (min: 200, max: 500);
    case '₱500+':
      return (min: 500, max: null);
    default:
      return (min: null, max: null);
  }
}

/// Listings that match the typed query plus Saan / Ano / Magkano.
///
/// Ilan is kept on [SearchQuery] for the results header. Listings have no
/// party-size field yet, so it does not drop rows.
List<Map<String, dynamic>> filter_listings(
  List<Map<String, dynamic>> listings,
  SearchQuery query,
) {
  return listings.where((listing) => listing_matches(listing, query)).toList();
}

bool listing_matches(Map<String, dynamic> listing, SearchQuery query) {
  final q = query.text.trim().toLowerCase();
  if (q.isNotEmpty && !_listing_haystack(listing).contains(q)) {
    return false;
  }

  final landmark = query.landmark_name?.trim().toLowerCase() ?? '';
  if (landmark.isNotEmpty) {
    final nearest = listing['nearestLandmark']?.toString().toLowerCase() ?? '';
    if (!nearest.contains(landmark)) {
      return false;
    }
  }

  if (query.food_types.isNotEmpty) {
    final wanted = query.food_types.map((name) => name.trim().toLowerCase()).toSet();
    final types  = listing_food_type_names(listing).map((name) => name.toLowerCase()).toSet();
    if (wanted.intersection(types).isEmpty) {
      return false;
    }
  }

  final price = listing['minPrice'];
  if (price is num) {
    if (query.min_price != null && price < query.min_price!) {
      return false;
    }
    if (query.max_price != null && price > query.max_price!) {
      return false;
    }
  }

  return true;
}

List<String> listing_food_type_names(Map<String, dynamic> listing) {
  final types = listing['food_types'];
  if (types is! List) {
    return [];
  }
  return types.map((type) => type['name'].toString()).toList();
}

String _listing_haystack(Map<String, dynamic> listing) {
  final parts = <String>[
    listing['name']?.toString() ?? '',
    listing['description']?.toString() ?? '',
    listing['nearestLandmark']?.toString() ?? '',
    ...listing_food_type_names(listing),
  ];

  final menu = listing['menu'];
  if (menu is List) {
    for (final item in menu) {
      if (item is Map) {
        parts.add(item['item']?.toString() ?? '');
      }
    }
  }

  final groups = listing['menu_groups'];
  if (groups is List) {
    for (final group in groups) {
      if (group is! Map) {
        continue;
      }
      parts.add(group['group_name']?.toString() ?? '');
      final items = group['items'];
      if (items is! List) {
        continue;
      }
      for (final item in items) {
        if (item is Map) {
          parts.add(item['item']?.toString() ?? '');
        }
      }
    }
  }

  return parts.join(' ').toLowerCase();
}
