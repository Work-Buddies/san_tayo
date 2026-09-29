import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/cache/app_cache.dart';
import 'package:san_tayo/core/mobile/global_widgets/listing_card.dart';
import 'package:san_tayo/core/mobile/global_widgets/search_filter_widgets.dart';
import 'package:san_tayo/core/mobile/listing_view.dart';
import 'package:san_tayo/core/mobile/search_query.dart';

/// Sent back to the filter screen when results closes.
///
/// [show_filters] stays false for phone back. Filter chips edit in place.
class ResultsPop {
  final SearchQuery query;
  final bool show_filters;
  final SearchFilterSection? section;

  const ResultsPop({
    required this.query,
    this.show_filters = false,
    this.section,
  });
}

/// Listing list for a submitted search. The phone back button returns to filters.
class SearchResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> listings;
  final List<Map<String, dynamic>> landmarks;
  final SearchQuery query;

  const SearchResultsScreen({
    super.key,
    required this.listings,
    required this.landmarks,
    required this.query,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _search_controller;
  late SearchQuery _query;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _search_controller = TextEditingController(text: widget.query.text);
  }

  @override
  void dispose() {
    _search_controller.dispose();
    super.dispose();
  }

  void _leave() {
    Navigator.of(context).pop(
      ResultsPop(
        query: SearchQuery(
          text: _search_controller.text,
          landmark_name: _query.landmark_name,
          food_types: _query.food_types,
          min_price: _query.min_price,
          max_price: _query.max_price,
          party_size: _query.party_size,
        ),
      ),
    );
  }

  Future<void> _open_filter(SearchFilterSection? section) async {
    final next = await show_search_filter_sheet(
      context: context,
      query: _query,
      landmarks: widget.landmarks,
      section: section,
    );
    if (!mounted) {
      return;
    }
    setState(() => _query = next);
  }

  Future<void> _submit(String value) async {
    setState(() {
      _query = SearchQuery(
        text: value,
        landmark_name: _query.landmark_name,
        food_types: _query.food_types,
        min_price: _query.min_price,
        max_price: _query.max_price,
        party_size: _query.party_size,
      );
    });
    await save_recent_search(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final matches     = filter_listings(widget.listings, _query);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did_pop, result) {
        if (did_pop) {
          return;
        }
        _leave();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultsHeader(
              searchController: _search_controller,
              query: _query,
              onSubmitted: _submit,
              onShortcutTap: _open_filter,
            ),
            Expanded(
              child: matches.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      children: [
                        Text('Results', style: textTheme.headlineSmall),
                        const SizedBox(height: 48),
                        Text(
                          'No places match those filters.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      itemCount: matches.length + 1,
                      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 12 : 16),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Text('Results', style: textTheme.headlineSmall);
                        }
                        final listing = matches[index - 1];
                        return ListingCard(
                          image: image_provider_from(listing['banner']),
                          name: listing['name'].toString(),
                          nearestLandmark: listing['nearestLandmark'].toString(),
                          minPrice: listing['minPrice'] as num,
                          tags: listing_food_type_names(listing),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ListingView(listing: listing),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maroon results chrome: wordmark, query field, and outlined filter chips.
class _ResultsHeader extends StatelessWidget {
  final TextEditingController searchController;
  final SearchQuery query;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<SearchFilterSection?> onShortcutTap;

  const _ResultsHeader({
    required this.searchController,
    required this.query,
    required this.onSubmitted,
    required this.onShortcutTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 16),
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
                child: Image.asset('assets/images/logo/logo.png'),
              ),
              const SizedBox(width: 10),
              Text(
                "Sa'n Tayo?",
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: 'MoreSugar',
                  color: colorScheme.onPrimary,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            style: textTheme.bodyMedium,
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
          const SizedBox(height: 16),
          ResultsShortcutRow(
            saanCount: query.saan_count,
            anoCount: query.ano_count,
            magkanoCount: query.magkano_count,
            ilanCount: query.ilan_count,
            settingsCount: query.settings_count,
            onShortcutTap: onShortcutTap,
          ),
        ],
      ),
    );
  }
}

/// Outlined chips on the maroon bar. Hamburger stays put; the names scroll.
class ResultsShortcutRow extends StatelessWidget {
  final int saanCount;
  final int anoCount;
  final int magkanoCount;
  final int ilanCount;
  final int settingsCount;
  final ValueChanged<SearchFilterSection?> onShortcutTap;

  const ResultsShortcutRow({
    super.key,
    required this.saanCount,
    required this.anoCount,
    required this.magkanoCount,
    required this.ilanCount,
    required this.settingsCount,
    required this.onShortcutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ResultsFilterChip(
          icon: HeroIcons.bars3,
          badgeCount: settingsCount,
          onTap: () => onShortcutTap(null),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                ResultsFilterChip(
                  icon: HeroIcons.mapPin,
                  label: 'Saan',
                  badgeCount: saanCount,
                  onTap: () => onShortcutTap(SearchFilterSection.saan),
                ),
                const SizedBox(width: 8),
                ResultsFilterChip(
                  icon: HeroIcons.star,
                  label: 'Ano',
                  badgeCount: anoCount,
                  onTap: () => onShortcutTap(SearchFilterSection.ano),
                ),
                const SizedBox(width: 8),
                ResultsFilterChip(
                  icon: HeroIcons.banknotes,
                  label: 'Magkano',
                  badgeCount: magkanoCount,
                  onTap: () => onShortcutTap(SearchFilterSection.magkano),
                ),
                const SizedBox(width: 8),
                ResultsFilterChip(
                  icon: HeroIcons.userGroup,
                  label: 'Ilan',
                  badgeCount: ilanCount,
                  onTap: () => onShortcutTap(SearchFilterSection.ilan),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// White outline pill on maroon, with a sage count badge when [badgeCount] is above 0.
class ResultsFilterChip extends StatelessWidget {
  final HeroIcons icon;
  final String? label;
  final int badgeCount;
  final VoidCallback onTap;

  const ResultsFilterChip({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final icon_only   = label == null;

    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 10),
      child: Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: icon_only ? const CircleBorder() : const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: icon_only ? const CircleBorder() : const StadiumBorder(),
            child: Container(
              padding: icon_only
                  ? const EdgeInsets.all(10)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                shape: icon_only ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: icon_only ? null : BorderRadius.circular(24),
                border: Border.all(color: colorScheme.onPrimary, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeroIcon(
                    icon,
                    style: HeroIconStyle.outline,
                    size:  14,
                    color: colorScheme.onPrimary,
                  ),
                  if (!icon_only) ...[
                    const SizedBox(width: 6),
                    Text(
                      label!,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.primary, width: 1),
              ),
              child: Text(
                '$badgeCount',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }
}