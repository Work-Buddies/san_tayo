import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/mobile/global_widgets/change_landmark_sheet.dart';
import 'package:san_tayo/core/mobile/global_widgets/drag_sheet.dart';
import 'package:san_tayo/core/mobile/search_query.dart';

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

/// Opens one filter (or every filter when [section] is null) in the same
/// drag-down sheet as Change landmark. The returned query is whatever was
/// selected when the sheet closed.
Future<SearchQuery> show_search_filter_sheet({
  required BuildContext context,
  required SearchQuery query,
  required List<Map<String, dynamic>> landmarks,
  SearchFilterSection? section,
}) async {
  final draft = _SearchFilterDraft.from_query(query, landmarks);
  await show_drag_sheet<void>(
    context: context,
    builder: (context, scroll_controller) {
      return _SearchFilterSheet(
        draft: draft,
        landmarks: landmarks,
        section: section,
        scrollController: scroll_controller,
      );
    },
  );
  return draft.to_query();
}

class _SearchFilterDraft {
  final String text;
  Map<String, dynamic> landmark;
  final Set<String> food_types;
  String? budget;
  String budget_from;
  String budget_to;
  int? party_size;

  _SearchFilterDraft({
    required this.text,
    required this.landmark,
    required this.food_types,
    required this.budget,
    required this.budget_from,
    required this.budget_to,
    required this.party_size,
  });

  factory _SearchFilterDraft.from_query(
    SearchQuery query,
    List<Map<String, dynamic>> landmarks,
  ) {
    final fields = budget_fields_from_range(query.min_price, query.max_price);
    final name   = query.landmark_name?.trim() ?? '';
    Map<String, dynamic> landmark = {};
    if (name.isNotEmpty) {
      for (final row in landmarks) {
        if (row['name']?.toString().toLowerCase() == name.toLowerCase()) {
          landmark = row;
          break;
        }
      }
      if (landmark.isEmpty) {
        landmark = {'name': name};
      }
    }

    return _SearchFilterDraft(
      text: query.text,
      landmark: landmark,
      food_types: {...query.food_types},
      budget: fields.preset,
      budget_from: fields.from,
      budget_to: fields.to,
      party_size: query.party_size,
    );
  }

  String? get landmark_name {
    final name = landmark['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      return null;
    }
    return name;
  }

  SearchQuery to_query() {
    final range = parse_budget_range(budget, budget_from, budget_to);
    return SearchQuery(
      text: text,
      landmark_name: landmark_name,
      food_types: food_types.toList(),
      min_price: range.min,
      max_price: range.max,
      party_size: party_size,
    );
  }
}

class _SearchFilterSheet extends StatefulWidget {
  final _SearchFilterDraft draft;
  final List<Map<String, dynamic>> landmarks;
  final SearchFilterSection? section;
  final ScrollController scrollController;

  const _SearchFilterSheet({
    required this.draft,
    required this.landmarks,
    required this.scrollController,
    this.section,
  });

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  final TextEditingController _landmark_controller = TextEditingController();
  late final TextEditingController _budget_from_controller;
  late final TextEditingController _budget_to_controller;
  String _landmark_query = '';

  @override
  void initState() {
    super.initState();
    _budget_from_controller = TextEditingController(text: widget.draft.budget_from);
    _budget_to_controller   = TextEditingController(text: widget.draft.budget_to);
  }

  @override
  void dispose() {
    _landmark_controller.dispose();
    _budget_from_controller.dispose();
    _budget_to_controller.dispose();
    super.dispose();
  }

  bool _shows(SearchFilterSection section) {
    return widget.section == null || widget.section == section;
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
    if (widget.draft.landmark_name == null) {
      return false;
    }

    final selected_id = widget.draft.landmark['id']?.toString();
    if (selected_id != null && landmark['id'] != null) {
      return landmark['id'].toString() == selected_id;
    }
    return landmark['name']?.toString() == widget.draft.landmark['name']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];

    if (_shows(SearchFilterSection.saan)) {
      blocks.addAll(_saan_block());
    }
    if (_shows(SearchFilterSection.ano)) {
      blocks.addAll(_ano_block());
    }
    if (_shows(SearchFilterSection.magkano)) {
      blocks.addAll(_magkano_block());
    }
    if (_shows(SearchFilterSection.ilan)) {
      blocks.addAll(_ilan_block());
    }

    return DragSheetPanel(
      scrollController: widget.scrollController,
      children: blocks,
    );
  }

  List<Widget> _saan_block() {
    return [
      const _FilterSheetHeading(
        icon: HeroIcons.mapPin,
        title: 'Saan',
        subtitle: "Filter the place where you're near.",
      ),
      const SizedBox(height: 12),
      SaanFilterBody(
        controller: _landmark_controller,
        landmarks: _filtered_landmarks,
        anywhereSelected: widget.draft.landmark_name == null,
        isSelected: _is_landmark_selected,
        onQueryChanged: (value) => setState(() => _landmark_query = value),
        onAnywhere: () => setState(() => widget.draft.landmark = {}),
        onPick: (landmark) => setState(() {
          if (_is_landmark_selected(landmark)) {
            widget.draft.landmark = {};
          } else {
            widget.draft.landmark = landmark;
          }
        }),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _ano_block() {
    return [
      const _FilterSheetHeading(
        icon: HeroIcons.star,
        title: 'Ano',
        subtitle: 'What food are you looking for?',
      ),
      const SizedBox(height: 12),
      AnoFilterBody(
        selected: widget.draft.food_types,
        onSelected: (value) => setState(() {
          if (widget.draft.food_types.contains(value)) {
            widget.draft.food_types.remove(value);
          } else {
            widget.draft.food_types.add(value);
          }
        }),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _magkano_block() {
    return [
      const _FilterSheetHeading(
        icon: HeroIcons.banknotes,
        title: 'Magkano',
        subtitle: "What's your budget?",
      ),
      const SizedBox(height: 12),
      MagkanoFilterBody(
        selected: widget.draft.budget,
        fromController: _budget_from_controller,
        toController: _budget_to_controller,
        onSelected: (value) => setState(() {
          widget.draft.budget = widget.draft.budget == value ? null : value;
          if (widget.draft.budget != null) {
            _budget_from_controller.clear();
            _budget_to_controller.clear();
            widget.draft.budget_from = '';
            widget.draft.budget_to   = '';
          }
        }),
        onRangeChanged: () => setState(() {
          widget.draft.budget      = null;
          widget.draft.budget_from = _budget_from_controller.text;
          widget.draft.budget_to   = _budget_to_controller.text;
        }),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _ilan_block() {
    return [
      const _FilterSheetHeading(
        icon: HeroIcons.userGroup,
        title: 'Ilan',
        subtitle: 'How many are you?',
      ),
      const SizedBox(height: 12),
      IlanFilterBody(
        partySize: widget.draft.party_size,
        onPresetTap: (size) => setState(() {
          widget.draft.party_size = widget.draft.party_size == size ? null : size;
        }),
        onMinus: () => setState(() {
          final current = widget.draft.party_size ?? 1;
          widget.draft.party_size = current <= 1 ? 1 : current - 1;
        }),
        onPlus: () => setState(() {
          final current = widget.draft.party_size ?? 1;
          widget.draft.party_size = current >= _party_size_max ? _party_size_max : current + 1;
        }),
      ),
    ];
  }
}

class _FilterSheetHeading extends StatelessWidget {
  final HeroIcons icon;
  final String title;
  final String subtitle;

  const _FilterSheetHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Row(
      children: [
        HeroIcon(
          icon,
          style: HeroIconStyle.solid,
          size:  18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Landmark search + pick list used inside the Saan filter.
class SaanFilterBody extends StatelessWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> landmarks;
  final bool anywhereSelected;
  final bool Function(Map<String, dynamic> landmark) isSelected;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAnywhere;
  final ValueChanged<Map<String, dynamic>> onPick;

  const SaanFilterBody({
    super.key,
    required this.controller,
    required this.landmarks,
    required this.anywhereSelected,
    required this.isSelected,
    required this.onQueryChanged,
    required this.onAnywhere,
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
        AnywherePickRow(
          selected: anywhereSelected,
          onTap: onAnywhere,
        ),
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

/// Clears Saan. Stays at the top of the list while the landmark search is active.
class AnywherePickRow extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const AnywherePickRow({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            HeroIcon(
              HeroIcons.globeAlt,
              style: selected ? HeroIconStyle.solid : HeroIconStyle.outline,
              size:  20,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Anywhere', style: textTheme.titleMedium),
            ),
            if (selected)
              HeroIcon(
                HeroIcons.check,
                style: HeroIconStyle.solid,
                size:  20,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Food-type chips. The option list lives here so every Ano filter stays in sync.
class AnoFilterBody extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  const AnoFilterBody({
    super.key,
    required this.onSelected,
    this.selected = const {},
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipWrap(
      options: _food_type_options,
      selected: selected,
      onSelected: onSelected,
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
