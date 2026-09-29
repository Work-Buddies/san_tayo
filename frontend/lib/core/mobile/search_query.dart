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

/// Reverse of [parse_budget_range] for the known chips. Anything else is a custom from–to.
({String? preset, String from, String to}) budget_fields_from_range(num? min, num? max) {
  if (min == null && max == 50) {
    return (preset: 'Under ₱50', from: '', to: '');
  }
  if (min == 50 && max == 100) {
    return (preset: '₱50 – ₱100', from: '', to: '');
  }
  if (min == 100 && max == 200) {
    return (preset: '₱100–₱200', from: '', to: '');
  }
  if (min == 200 && max == 500) {
    return (preset: '₱200–₱500', from: '', to: '');
  }
  if (min == 500 && max == null) {
    return (preset: '₱500+', from: '', to: '');
  }
  if (min == null && max == null) {
    return (preset: null, from: '', to: '');
  }

  return (
    preset: null,
    from: min == null ? '' : _plain_number(min),
    to: max == null ? '' : _plain_number(max),
  );
}

String _plain_number(num value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}

/// Listings that match the typed query plus Saan / Ano / Magkano / Ilan.
///
/// Magkano keeps a place when any menu price falls in range.
/// Ilan keeps a place that has a pax tag covering the party size.
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

  if (query.min_price != null || query.max_price != null) {
    final prices = listing_menu_prices(listing);
    final in_range = prices.any((price) => _price_in_budget(price, query));
    if (!in_range) {
      return false;
    }
  }

  if (query.party_size != null) {
    final covered = listing_tags(listing).any((tag) {
      if (tag['type']?.toString() != 'pax') {
        return false;
      }
      return pax_tag_covers(tag['name']?.toString() ?? '', query.party_size!);
    });
    if (!covered) {
      return false;
    }
  }

  return true;
}

bool _price_in_budget(num price, SearchQuery query) {
  if (query.min_price != null && price < query.min_price!) {
    return false;
  }
  if (query.max_price != null && price > query.max_price!) {
    return false;
  }
  return true;
}

/// Every menu price. Falls back to minPrice when the menu has no numbers.
List<num> listing_menu_prices(Map<String, dynamic> listing) {
  final prices = <num>[];

  void add(dynamic price) {
    final value = price is num ? price : num.tryParse(price?.toString() ?? '');
    if (value != null) {
      prices.add(value);
    }
  }

  final menu = listing['menu'];
  if (menu is List) {
    for (final item in menu) {
      if (item is Map) {
        add(item['price']);
      }
    }
  }

  final groups = listing['menu_groups'];
  if (groups is List) {
    for (final group in groups) {
      if (group is! Map) {
        continue;
      }
      final items = group['items'];
      if (items is! List) {
        continue;
      }
      for (final item in items) {
        if (item is Map) {
          add(item['price']);
        }
      }
    }
  }

  if (prices.isEmpty) {
    add(listing['minPrice']);
  }

  return prices;
}

/// Food-type and pax rows. A missing type is treated as foodtype.
List<Map<String, dynamic>> listing_tags(Map<String, dynamic> listing) {
  final raw = listing['food_types'] ?? listing['tags'];
  if (raw is! List) {
    return [];
  }

  final tags = <Map<String, dynamic>>[];
  for (final row in raw) {
    if (row is! Map) {
      continue;
    }
    final name = row['name']?.toString() ?? '';
    if (name.isEmpty) {
      continue;
    }
    tags.add({
      'name': name,
      'type': row['type']?.toString() ?? 'foodtype',
    });
  }
  return tags;
}

/// True when a pax tag name covers [size]. "5+" covers 5 and up. "4 pax" covers 4.
bool pax_tag_covers(String name, int size) {
  final plus = RegExp(r'(\d+)\s*\+').firstMatch(name);
  if (plus != null) {
    final min = int.tryParse(plus.group(1) ?? '');
    return min != null && size >= min;
  }

  final exact = RegExp(r'(\d+)').firstMatch(name);
  if (exact == null) {
    return false;
  }
  return int.tryParse(exact.group(1) ?? '') == size;
}

List<String> listing_food_type_names(Map<String, dynamic> listing) {
  return listing_tags(listing)
      .where((tag) => tag['type'] == 'foodtype')
      .map((tag) => tag['name'].toString())
      .toList();
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
