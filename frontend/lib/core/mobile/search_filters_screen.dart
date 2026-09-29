import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/cache/app_cache.dart';
import 'package:san_tayo/core/mobile/global_widgets/search_filter_widgets.dart';
import 'package:san_tayo/core/mobile/home_bar.dart';
import 'package:san_tayo/core/mobile/search_query.dart';
import 'package:san_tayo/core/mobile/search_results_screen.dart';

const int _party_size_max = 20;

/// Full-screen search + filter overlay opened from the dashboard search bar.
///
/// The system home bar stays visible on this screen. Any page pushed over it,
/// including results, hides the bar again.
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

class _SearchFiltersScreenState extends State<SearchFiltersScreen> with RouteAware {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      home_bar_observer.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    home_bar_observer.unsubscribe(this);
    hide_home_bar();
    _search_controller.dispose();
    _landmark_controller.dispose();
    _budget_from_controller.dispose();
    _budget_to_controller.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    show_home_bar();
  }

  @override
  void didPopNext() {
    show_home_bar();
  }

  @override
  void didPushNext() {
    hide_home_bar();
  }

  @override
  void didPop() {
    hide_home_bar();
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
    await _open_results(value);
  }

  Future<void> _open_results(String value) async {
    final budget = parse_budget_range(
      _budget,
      _budget_from_controller.text,
      _budget_to_controller.text,
    );

    final popped = await Navigator.of(context).push<ResultsPop>(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          listings: widget.listings,
          landmarks: widget.landmarks,
          query: SearchQuery(
            text: value,
            landmark_name: _query_landmark_name,
            food_types: _food_types.toList(),
            min_price: budget.min,
            max_price: budget.max,
            party_size: _party_size,
          ),
        ),
      ),
    );

    if (!mounted || popped == null) {
      return;
    }

    _search_controller.value = TextEditingValue(
      text: popped.query.text,
      selection: TextSelection.collapsed(offset: popped.query.text.length),
    );
    _apply_query(popped.query);
    if (popped.show_filters) {
      _select_shortcut(popped.section);
    }
  }

  void _apply_query(SearchQuery query) {
    final fields = budget_fields_from_range(query.min_price, query.max_price);
    _budget_from_controller.text = fields.from;
    _budget_to_controller.text   = fields.to;
    _landmark_controller.clear();

    final name = query.landmark_name?.trim() ?? '';
    Map<String, dynamic> landmark = {};
    if (name.isNotEmpty) {
      for (final row in widget.landmarks) {
        if (row['name']?.toString().toLowerCase() == name.toLowerCase()) {
          landmark = row;
          break;
        }
      }
      if (landmark.isEmpty) {
        landmark = {'name': name};
      }
    }

    setState(() {
      _filter_landmark = landmark;
      _food_types
        ..clear()
        ..addAll(query.food_types);
      _budget         = fields.preset;
      _party_size     = query.party_size;
      _landmark_query = '';
    });
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
    if (_query_landmark_name == null) {
      return false;
    }

    final selected_id = _filter_landmark['id']?.toString();
    if (selected_id != null && landmark['id'] != null) {
      return landmark['id'].toString() == selected_id;
    }
    return landmark['name']?.toString() == _filter_landmark['name']?.toString();
  }

  /// Null means Anywhere: no landmark is sent to the results query.
  String? get _query_landmark_name {
    final name = _filter_landmark['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      return null;
    }
    return name;
  }

  String get _saan_label => _query_landmark_name ?? 'Anywhere';

  int get _saan_count => _query_landmark_name == null ? 0 : 1;

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
                    trailing: _saan_label,
                    expanded: _is_expanded(SearchFilterSection.saan),
                    onToggle: () => _toggle_section(SearchFilterSection.saan),
                    child: SaanFilterBody(
                      controller: _landmark_controller,
                      landmarks: _filtered_landmarks,
                      anywhereSelected: _query_landmark_name == null,
                      isSelected: _is_landmark_selected,
                      onQueryChanged: (value) => setState(() => _landmark_query = value),
                      onAnywhere: () => setState(() => _filter_landmark = {}),
                      onPick: (landmark) => setState(() {
                        if (_is_landmark_selected(landmark)) {
                          _filter_landmark = {};
                        } else {
                          _filter_landmark = landmark;
                        }
                      }),
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
                    child: AnoFilterBody(
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
