import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:san_tayo/core/mobile/global_widgets/drag_sheet.dart';

bool _landmark_sheet_open = false;

/// Darkens the screen and slides up a draggable landmark list. Dragging the
/// panel back down (or tapping the dimmed area) cancels without changing the pick.
/// A second tap while the sheet is already open is ignored.
Future<Map<String, dynamic>?> show_change_landmark_sheet({
  required BuildContext context,
  required List<Map<String, dynamic>> landmarks,
  Map<String, dynamic>? selected,
}) {
  if (_landmark_sheet_open) {
    return Future.value(null);
  }

  _landmark_sheet_open = true;
  return show_drag_sheet<Map<String, dynamic>>(
    context: context,
    builder: (context, scroll_controller) {
      return ChangeLandmarkSheet(
        landmarks: landmarks,
        selected: selected,
        scrollController: scroll_controller,
      );
    },
  ).whenComplete(() {
    _landmark_sheet_open = false;
  });
}

/// Bottom panel: search + landmark rows. Selecting a row pops the sheet with that row.
class ChangeLandmarkSheet extends StatefulWidget {
  final List<Map<String, dynamic>> landmarks;
  final Map<String, dynamic>? selected;
  final ScrollController scrollController;

  const ChangeLandmarkSheet({
    super.key,
    required this.landmarks,
    required this.scrollController,
    this.selected,
  });

  @override
  State<ChangeLandmarkSheet> createState() => _ChangeLandmarkSheetState();
}

class _ChangeLandmarkSheetState extends State<ChangeLandmarkSheet> {
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.landmarks;
    }

    return widget.landmarks.where((landmark) {
      final name     = landmark['name']?.toString().toLowerCase() ?? '';
      final barangay = landmark['barangay']?.toString().toLowerCase() ?? '';
      return name.contains(q) || barangay.contains(q);
    }).toList();
  }

  bool _is_selected(Map<String, dynamic> landmark) {
    final selected_id = widget.selected?['id']?.toString();
    if (selected_id != null && landmark['id'] != null) {
      return landmark['id'].toString() == selected_id;
    }

    return landmark['name']?.toString() == widget.selected?['name']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final filtered    = _filtered;

    return DragSheetPanel(
      scrollController: widget.scrollController,
      children: [
          Row(
            children: [
              HeroIcon(
                HeroIcons.mapPin,
                style: HeroIconStyle.solid,
                size:  18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Change landmark',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search landmark or campus',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              filled: true,
              fillColor: Colors.white,
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
          const SizedBox(height: 20),
          Text(
            'Landmarks',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          if (filtered.isEmpty)
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
            for (final landmark in filtered)
              LandmarkPickRow(
                landmark: landmark,
                selected: _is_selected(landmark),
                onTap: () => Navigator.of(context).pop(landmark),
              ),
      ],
    );
  }
}

/// One landmark row: pin, name, barangay, and a check when it is the current pick.
class LandmarkPickRow extends StatelessWidget {
  final Map<String, dynamic> landmark;
  final bool selected;
  final VoidCallback onTap;

  const LandmarkPickRow({
    super.key,
    required this.landmark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final name        = landmark['name']?.toString() ?? '';
    final barangay    = landmark['barangay']?.toString() ?? '';

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
              HeroIcons.mapPin,
              style: selected ? HeroIconStyle.solid : HeroIconStyle.outline,
              size:  20,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: textTheme.titleMedium),
                  if (barangay.isNotEmpty)
                    Text(
                      barangay,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
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
