import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/cache/app_cache.dart';
import 'package:san_tayo/core/mobile/global_widgets/change_landmark_sheet.dart';
import 'package:san_tayo/core/mobile/search_query.dart';
import 'package:san_tayo/core/mobile/search_results_screen.dart';

const List<String> _food_type_options = [
  'Fried food',
  'Rice Meals',
  'Street Food',
  'Soup',
  'Dessert',
  'Beverages',
  'Snacks',
  'Noodles',
  'Inihaw',
  'Silog',
  'Veggie',
  'Fast Food',
];

const List<String> _budget_options = [
  'Under ₱50',
  '₱50 – ₱100',
  '₱100–₱200',
  '₱200–₱500',
  '₱500+',
];

const List<({String label, int size})> _party_presets = [
  (label: 'Solo (1 pax)',     size: 1),
  (label: 'Duo (2 pax)',      size: 2),
  (label: 'Trio (3 pax)',     size: 3),
  (label: 'Squad (4 pax)',    size: 4),
  (label: 'Barkada (5 pax)',  size: 5),
];

const int _party_size_max = 20;

enum SearchFilterSection { saan, ano, magkano, ilan }

/// Full-screen search + filter overlay opened from the dashboard search bar.
class SearchFiltersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> landmarks;
  final List<Map<String, dynamic>> listings;
  final Map<String, dynamic> selectedLandmark;

  const SearchFiltersScreen({
    super.key,
    required this.landmarks,
    required this.listings,
    required this.selectedLandmark,
  });

  @override
  State<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends State<SearchFiltersScreen> {
  final TextEditingController _search_controller = TextEditingController();
  final TextEditingController _landmark_controller = TextEditingController();
  final TextEditingController _budget_from_controller = TextEditingController();
  final TextEditingController _budget_to_controller = TextEditingController();

  List<String> _recents = [];
  String _landmark_query = '';
  /// null = settings chip (show every accordion). Otherwise only that section.
  SearchFilterSection? _visible_section;
  SearchFilterSection? _open_section = SearchFilterSection.saan;
  late Map<String, dynamic> _filter_landmark;
  final Set<String> _food_types = {};
  String? _budget;
  int? _party_size;

  @override
  void initState() {
    super.initState();
    _filter_landmark = widget.selectedLandmark;
    _load_recents();
  }

  @override
  void dispose() {
    _search_controller.dispose();
    _landmark_controller.dispose();
    _budget_from_controller.dispose();
    _budget_to_controller.dispose();
    super.dispose();
  }

  Future<void> _load_recents() async {
    final recents = await get_recent_searches();
    if (!mounted) {
      return;
    }
    setState(() => _recents = recents);
  }

  Future<void> _commit_search(String value) async {
    await save_recent_search(value);
    await _load_recents();
    if (!mounted) {
      return;
    }
    _open_results(value);
  }

  void _open_results(String value) {
    final budget = parse_budget_range(
      _budget,
      _budget_from_controller.text,
      _budget_to_controller.text,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          listings: widget.listings,
          query: SearchQuery(
            text: value,
            landmark_name: _landmark_name,
            food_types: _food_types.toList(),
            min_price: budget.min,
            max_price: budget.max,
            party_size: _party_size,
          ),
        ),
      ),
    );
  }

  Future<void> _clear_recents() async {
    await clear_recent_searches();
    if (!mounted) {
      return;
    }
    setState(() => _recents = []);
  }

  void _use_recent(String query) {
    _search_controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    _commit_search(query);
  }

  void _select_shortcut(SearchFilterSection? section) {
    setState(() {
      _visible_section = section;
      if (section != null) {
        _open_section = section;
      }
    });
  }

  void _toggle_section(SearchFilterSection section) {
    // Single-section mode keeps that accordion open.
    if (_visible_section != null) {
      return;
    }
    setState(() {
      _open_section = _open_section == section ? null : section;
    });
  }

  bool _shows(SearchFilterSection section) {
    return _visible_section == null || _visible_section == section;
  }

  bool _is_expanded(SearchFilterSection section) {
    if (_visible_section == section) {
      return true;
    }
    return _visible_section == null && _open_section == section;
  }

  List<Map<String, dynamic>> get _filtered_landmarks {
    final q = _landmark_query.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.landmarks;
    }

    return widget.landmarks.where((landmark) {
      final name     = landmark['name']?.toString().toLowerCase() ?? '';
      final barangay = landmark['barangay']?.toString().toLowerCase() ?? '';
      return name.contains(q) || barangay.contains(q);
    }).toList();
  }

  bool _is_landmark_selected(Map<String, dynamic> landmark) {
    final selected_id = _filter_landmark['id']?.toString();
    if (selected_id != null && landmark['id'] != null) {
      return landmark['id'].toString() == selected_id;
    }
    return landmark['name']?.toString() == _filter_landmark['name']?.toString();
  }

  String get _landmark_name {
    return _filter_landmark['name']?.toString() ?? default_landmark_name;
  }

  int get _saan_count {
    return _landmark_name.trim().isEmpty ? 0 : 1;
  }

  int get _ano_count => _food_types.length;

  int get _magkano_count {
    final from = _budget_from_controller.text.trim();
    final to   = _budget_to_controller.text.trim();
    if (_budget != null || from.isNotEmpty || to.isNotEmpty) {
      return 1;
    }
    return 0;
  }

  int get _ilan_count => _party_size == null ? 0 : 1;

  int get _settings_count => _saan_count + _ano_count + _magkano_count + _ilan_count;

  String? get _ano_trailing {
    if (_food_types.isEmpty) {
      return null;
    }
    final list = _food_types.toList();
    if (list.length == 1) {
      return list.first;
    }
    return '${list.first} +${list.length - 1}';
  }

  String? get _budget_trailing {
    final from = _budget_from_controller.text.trim();
    final to   = _budget_to_controller.text.trim();
    if (from.isNotEmpty && to.isNotEmpty) {
      return '₱$from–₱$to';
    }
    if (from.isNotEmpty) {
      return 'From ₱$from';
    }
    if (to.isNotEmpty) {
      return 'To ₱$to';
    }
    return _budget;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          SearchFiltersHeader(
            searchController: _search_controller,
            recents: _recents,
            visibleSection: _visible_section,
            saanCount: _saan_count,
            anoCount: _ano_count,
            magkanoCount: _magkano_count,
            ilanCount: _ilan_count,
            settingsCount: _settings_count,
            onClose: () => Navigator.of(context).pop(),
            onSubmitted: _commit_search,
            onRecentTap: _use_recent,
            onClearRecents: _clear_recents,
            onShortcutTap: _select_shortcut,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (_shows(SearchFilterSection.saan)) ...[
                  FilterAccordion(
                    icon: HeroIcons.mapPin,
                    title: 'Saan',
                    subtitle: "Filter the place where you're near.",
                    trailing: _landmark_name,
                    expanded: _is_expanded(SearchFilterSection.saan),
                    onToggle: () => _toggle_section(SearchFilterSection.saan),
                    child: SaanFilterBody(
                      controller: _landmark_controller,
                      landmarks: _filtered_landmarks,
                      isSelected: _is_landmark_selected,
                      onQueryChanged: (value) => setState(() => _landmark_query = value),
                      onPick: (landmark) => setState(() => _filter_landmark = landmark),
                    ),
                  ),
                  if (_shows(SearchFilterSection.ano) ||
                      _shows(SearchFilterSection.magkano) ||
                      _shows(SearchFilterSection.ilan))
                    const SizedBox(height: 12),
                ],
                if (_shows(SearchFilterSection.ano)) ...[
                  FilterAccordion(
                    icon: HeroIcons.star,
                    title: 'Ano',
                    subtitle: 'What food are you looking for?',
                    trailing: _ano_trailing,
                    expanded: _is_expanded(SearchFilterSection.ano),
                    onToggle: () => _toggle_section(SearchFilterSection.ano),
                    child: FilterChipWrap(
                      options: _food_type_options,
                      selected: _food_types,
                      onSelected: (value) => setState(() {
                        if (_food_types.contains(value)) {
                          _food_types.remove(value);
                        } else {
                          _food_types.add(value);
                        }
                      }),
                    ),
                  ),
                  if (_shows(SearchFilterSection.magkano) || _shows(SearchFilterSection.ilan))
                    const SizedBox(height: 12),
                ],
                if (_shows(SearchFilterSection.magkano)) ...[
                  FilterAccordion(
                    icon: HeroIcons.banknotes,
                    title: 'Magkano',
                    subtitle: "What's your budget?",
                    trailing: _budget_trailing,
                    expanded: _is_expanded(SearchFilterSection.magkano),
                    onToggle: () => _toggle_section(SearchFilterSection.magkano),
                    child: MagkanoFilterBody(
                      selected: _budget,
                      fromController: _budget_from_controller,
                      toController: _budget_to_controller,
                      onSelected: (value) => setState(() {
                        _budget = _budget == value ? null : value;
                        if (_budget != null) {
                          _budget_from_controller.clear();
                          _budget_to_controller.clear();
                        }
                      }),
                      onRangeChanged: () => setState(() => _budget = null),
                    ),
                  ),
                  if (_shows(SearchFilterSection.ilan))
                    const SizedBox(height: 12),
                ],
                if (_shows(SearchFilterSection.ilan))
                  FilterAccordion(
                    icon: HeroIcons.userGroup,
                    title: 'Ilan',
                    subtitle: 'How many are you?',
                    trailing: _party_size == null ? null : '$_party_size pax',
                    expanded: _is_expanded(SearchFilterSection.ilan),
                    onToggle: () => _toggle_section(SearchFilterSection.ilan),
                    child: IlanFilterBody(
                      partySize: _party_size,
                      onPresetTap: (size) => setState(() {
                        _party_size = _party_size == size ? null : size;
                      }),
                      onMinus: () => setState(() {
                        final current = _party_size ?? 1;
                        _party_size = current <= 1 ? 1 : current - 1;
                      }),
                      onPlus: () => setState(() {
                        final current = _party_size ?? 1;
                        _party_size = current >= _party_size_max ? _party_size_max : current + 1;
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Maroon search chrome: wordmark, query field, recents, and filter shortcuts.
class SearchFiltersHeader extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> recents;
  final SearchFilterSection? visibleSection;
  final int saanCount;
  final int anoCount;
  final int magkanoCount;
  final int ilanCount;
  final int settingsCount;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearRecents;
  final ValueChanged<SearchFilterSection?> onShortcutTap;

  const SearchFiltersHeader({
    super.key,
    required this.searchController,
    required this.recents,
    required this.visibleSection,
    required this.saanCount,
    required this.anoCount,
    required this.magkanoCount,
    required this.ilanCount,
    required this.settingsCount,
    required this.onClose,
    required this.onSubmitted,
    required this.onRecentTap,
    required this.onClearRecents,
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
              Expanded(
                child: Text(
                  "Sa'n Tayo?",
                  style: textTheme.titleLarge?.copyWith(
                    fontFamily: 'MoreSugar',
                    color: colorScheme.onPrimary,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
                width:  44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.35),
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
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            autofocus: true,
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
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                HeroIcon(
                  HeroIcons.clock,
                  style: HeroIconStyle.outline,
                  size:  14,
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'RECENT SEARCHES',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClearRecents,
                  child: Text(
                    'Clear',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final query in recents)
                  RecentSearchChip(
                    label: query,
                    onTap: () => onRecentTap(query),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilterShortcutRow(
            visibleSection: visibleSection,
            saanCount: saanCount,
            anoCount: anoCount,
            magkanoCount: magkanoCount,
            ilanCount: ilanCount,
            settingsCount: settingsCount,
            onShortcutTap: onShortcutTap,
          ),
        ],
      ),
    );
  }
}

/// Settings shows all; named chips show only their accordion. Sage fill when selected.
class FilterShortcutRow extends StatelessWidget {
  final SearchFilterSection? visibleSection;
  final int saanCount;
  final int anoCount;
  final int magkanoCount;
  final int ilanCount;
  final int settingsCount;
  final ValueChanged<SearchFilterSection?> onShortcutTap;

  const FilterShortcutRow({
    super.key,
    required this.visibleSection,
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
        FilterShortcutChip(
          icon: HeroIcons.adjustmentsHorizontal,
          selected: visibleSection == null,
          badgeCount: settingsCount,
          onTap: () => onShortcutTap(null),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterShortcutChip(
                  icon: HeroIcons.mapPin,
                  label: 'Saan',
                  selected: visibleSection == SearchFilterSection.saan,
                  badgeCount: saanCount,
                  onTap: () => onShortcutTap(SearchFilterSection.saan),
                ),
                const SizedBox(width: 8),
                FilterShortcutChip(
                  icon: HeroIcons.star,
                  label: 'Ano',
                  selected: visibleSection == SearchFilterSection.ano,
                  badgeCount: anoCount,
                  onTap: () => onShortcutTap(SearchFilterSection.ano),
                ),
                const SizedBox(width: 8),
                FilterShortcutChip(
                  icon: HeroIcons.banknotes,
                  label: 'Magkano',
                  selected: visibleSection == SearchFilterSection.magkano,
                  badgeCount: magkanoCount,
                  onTap: () => onShortcutTap(SearchFilterSection.magkano),
                ),
                const SizedBox(width: 8),
                FilterShortcutChip(
                  icon: HeroIcons.userGroup,
                  label: 'Ilan',
                  selected: visibleSection == SearchFilterSection.ilan,
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

/// Cream/sage pill with an optional maroon count badge on the upper-right.
class FilterShortcutChip extends StatelessWidget {
  final HeroIcons icon;
  final String? label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const FilterShortcutChip({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.selected = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: selected ? colorScheme.secondary : colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeroIcon(
                    icon,
                    style: HeroIconStyle.outline,
                    size:  14,
                    color: colorScheme.primary,
                  ),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      label!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
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
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Clock-tagged recent query pill.
class RecentSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const RecentSearchChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroIcon(
                HeroIcons.clock,
                style: HeroIconStyle.outline,
                size:  14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White expandable filter card.
class FilterAccordion extends StatelessWidget {
  final HeroIcons icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const FilterAccordion({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HeroIcon(
                        icon,
                        style: HeroIconStyle.solid,
                        size:  18,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleMedium),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null && trailing!.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        trailing!,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                      ),
                    ),
                  HeroIcon(
                    expanded ? HeroIcons.chevronUp : HeroIcons.chevronDown,
                    style: HeroIconStyle.outline,
                    size:  18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Landmark search + pick list used inside the Saan accordion.
class SaanFilterBody extends StatelessWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> landmarks;
  final bool Function(Map<String, dynamic> landmark) isSelected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Map<String, dynamic>> onPick;

  const SaanFilterBody({
    super.key,
    required this.controller,
    required this.landmarks,
    required this.isSelected,
    required this.onQueryChanged,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onQueryChanged,
          style: textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search landmark or campus',
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
        const SizedBox(height: 8),
        if (landmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No landmarks found.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          )
        else
          for (final landmark in landmarks)
            LandmarkPickRow(
              landmark: landmark,
              selected: isSelected(landmark),
              onTap: () => onPick(landmark),
            ),
      ],
    );
  }
}

/// Outlined option chips with a sage fill when selected. Supports multi-select.
class FilterChipWrap extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  const FilterChipWrap({
    super.key,
    required this.options,
    required this.onSelected,
    this.selected = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterOptionChip(
            label: option,
            selected: selected.contains(option),
            onTap: () => onSelected(option),
          ),
      ],
    );
  }
}

class FilterOptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterOptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.secondary : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.55)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Budget chips plus a custom from–to range.
class MagkanoFilterBody extends StatelessWidget {
  final String? selected;
  final TextEditingController fromController;
  final TextEditingController toController;
  final ValueChanged<String> onSelected;
  final VoidCallback onRangeChanged;

  const MagkanoFilterBody({
    super.key,
    required this.fromController,
    required this.toController,
    required this.onSelected,
    required this.onRangeChanged,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterChipWrap(
          options: _budget_options,
          selected: selected == null ? const {} : {selected!},
          onSelected: onSelected,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Budget range:',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BudgetRangeField(
                controller: fromController,
                hint: 'From',
                onChanged: (_) => onRangeChanged(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('-', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
            ),
            Expanded(
              child: BudgetRangeField(
                controller: toController,
                hint: 'To',
                onChanged: (_) => onRangeChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ilan chips plus a minus / plus stepper for a custom headcount.
class IlanFilterBody extends StatelessWidget {
  final int? partySize;
  final ValueChanged<int> onPresetTap;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const IlanFilterBody({
    super.key,
    required this.onPresetTap,
    required this.onMinus,
    required this.onPlus,
    this.partySize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _party_presets)
              FilterOptionChip(
                label: preset.label,
                selected: partySize == preset.size,
                onTap: () => onPresetTap(preset.size),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PartySizeStepper(
          count: partySize ?? 1,
          onMinus: onMinus,
          onPlus: onPlus,
        ),
      ],
    );
  }
}

class PartySizeStepper extends StatelessWidget {
  final int count;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const PartySizeStepper({
    super.key,
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperButton(label: '-', onTap: onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(
                '$count',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
              ),
              Text(
                count == 1 ? 'person' : 'people',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
        ),
        _StepperButton(label: '+', onTap: onPlus),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepperButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width:  36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class BudgetRangeField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const BudgetRangeField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}
