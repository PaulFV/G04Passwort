import 'package:flutter/material.dart';

/// Material 3 window size classes used for adaptive layouts.
enum WindowSize {
  /// Phones (< 600 dp): bottom navigation, single column.
  compact,

  /// Small tablets / phones in landscape (600–839 dp): navigation rail.
  medium,

  /// Tablets / small desktop windows (840–1199 dp): rail, two columns.
  expanded,

  /// Desktop (≥ 1200 dp): extended rail, up to three columns.
  large;

  static WindowSize of(double width) => switch (width) {
    < 600 => WindowSize.compact,
    < 840 => WindowSize.medium,
    < 1200 => WindowSize.expanded,
    _ => WindowSize.large,
  };

  bool get isCompact => this == WindowSize.compact;
  bool get atLeastExpanded => index >= WindowSize.expanded.index;
}

extension ResponsiveContext on BuildContext {
  WindowSize get windowSize => WindowSize.of(MediaQuery.sizeOf(this).width);
}

/// Lays out [children] in as many equal columns as fit (each at least
/// [minItemWidth] wide, at most [maxColumns]). Falls back to a plain column
/// on phones. Intended for short lists (settings, categories, menus).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 340,
    this.maxColumns = 3,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + spacing) ~/ (minItemWidth + spacing))
            .clamp(1, maxColumns);
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: spacing),
                  Expanded(
                    child: i + c < children.length ? children[i + c] : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
      },
    );
  }
}

/// Lazily built list that becomes a multi-column grid on wide screens.
/// Grid cells have a fixed [gridItemExtent] height.
class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.gridItemExtent = 78,
    this.maxItemWidth = 460,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final double gridItemExtent;
  final double maxItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return ListView.builder(
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
        return GridView.builder(
          padding: padding,
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxItemWidth,
            mainAxisExtent: gridItemExtent,
            crossAxisSpacing: 12,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
