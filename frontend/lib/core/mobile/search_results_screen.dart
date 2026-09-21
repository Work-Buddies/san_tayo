import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/mobile/global_widgets/listing_card.dart';
import 'package:san_tayo/core/mobile/listing_view.dart';
import 'package:san_tayo/core/mobile/search_query.dart';

/// Listing list for a submitted search. Back returns to the filter overlay.
class SearchResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  final SearchQuery query;

  const SearchResultsScreen({
    super.key,
    required this.listings,
    required this.query,
  });

  List<String> get _summary {
    final chips = <String>[];
    if (query.landmark_name != null && query.landmark_name!.trim().isNotEmpty) {
      chips.add(query.landmark_name!.trim());
    }
    if (query.food_types.isNotEmpty) {
      chips.add(query.food_types.join(', '));
    }
    if (query.min_price != null && query.max_price != null) {
      chips.add('₱${query.min_price}–₱${query.max_price}');
    } else if (query.min_price != null) {
      chips.add('₱${query.min_price}+');
    } else if (query.max_price != null) {
      chips.add('Under ₱${query.max_price}');
    }
    if (query.party_size != null) {
      chips.add('${query.party_size} pax');
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final matches     = filter_listings(listings, query);
    final summary     = _summary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorScheme.primary,
            padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: HeroIcon(
                        HeroIcons.arrowLeft,
                        style: HeroIconStyle.outline,
                        color: colorScheme.onPrimary,
                        size:  22,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        query.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
                if (summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      summary.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text(
                      'No places match those filters.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final listing = matches[index];
                      return ListingCard(
                        image: NetworkImage(listing['image'].toString()),
                        name: listing['name'].toString(),
                        nearestLandmark: listing['nearestLandmark'].toString(),
                        minPrice: listing['minPrice'] as num,
                        tags: listing_food_type_names(listing),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ListingView(listingId: listing['id'].toString()),
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
