import 'package:flutter/material.dart';

/// Darkens the screen and slides up a panel. Dragging the panel down past its
/// minimum size, or tapping the dimmed area, closes it.
Future<T?> show_drag_sheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, ScrollController scroll_controller) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.28,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.72],
        shouldCloseOnMinExtent: true,
        builder: (context, scroll_controller) {
          return builder(context, scroll_controller);
        },
      );
    },
  );
}

/// Rounded sheet surface with the grab handle. [children] scroll with [scrollController],
/// which is what lets a downward drag shrink and then close the sheet.
class DragSheetPanel extends StatelessWidget {
  final ScrollController scrollController;
  final List<Widget> children;

  const DragSheetPanel({
    super.key,
    required this.scrollController,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
