import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_erp/core/theme/app_colors.dart';
import 'package:frontend_erp/features/godown/presentation/widgets/godown_card_shimmer.dart';
import 'package:frontend_erp/features/godown/presentation/widgets/stock_table.dart';

/// The loading skeleton has to be indistinguishable from the real table once
/// data lands, or every row visibly reshuffles on load. These pin the geometry
/// the two share: the header band, the row height, and the alternating bands.

const List<StockTableEntry> _entries = [
  StockTableEntry(
    title: 'Basmati Rice',
    subtitle: '5 KG x 20 BAGS',
    available: 40,
  ),
  StockTableEntry(
    title: 'Sona Masoori',
    subtitle: '5 KG x 20 BAGS',
    available: 0,
  ),
  StockTableEntry(
    title: 'Toor Dal',
    subtitle: '30 KG x 10 BAGS',
    available: null,
  ),
];

/// Pumps [child] at the same viewport and horizontal list padding the stock
/// screens use, so offsets are directly comparable between skeleton and table.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    ),
  );
  // `pumpAndSettle` cannot be used against a shimmer: its highlight sweep is a
  // repeating animation, so the tree never reaches a quiescent frame.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// The tinted header band. In the table it is the only [Container] carrying a
/// colour *and* padding; the skeleton's own placeholder blocks are paddingless.
double _headerHeight(WidgetTester tester) {
  final Finder header = find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.color == AppColors.SURFACE_VARIANT &&
        widget.padding != null,
  );
  return tester.getSize(header).height;
}

/// Whether [widget] paints one of the table's alternating data bands. The real
/// table uses [Material] for its rows, the skeleton [ColoredBox].
bool _isDataBand(Widget widget) {
  final Color? color = switch (widget) {
    ColoredBox(:final Color color) => color,
    Material(:final Color? color) => color,
    _ => null,
  };
  return color == AppColors.SURFACE || color == AppColors.BACKGROUND_TINTED;
}

/// Flat alternating data bands, skipping the full-bleed box `Shimmer` puts
/// behind its child.
List<double> _bandHeights(WidgetTester tester) {
  final List<double> heights = [];
  for (final Element element
      in find.byWidgetPredicate(_isDataBand).evaluate()) {
    final double height = tester.getSize(find.byWidget(element.widget)).height;
    // The shimmering surface itself spans the viewport; a data row never does.
    if (height < 400) heights.add(height);
  }
  return heights;
}

double _realRowHeight(WidgetTester tester) {
  final List<double> heights = _bandHeights(tester);
  expect(heights, isNotEmpty, reason: 'the real table must render data rows');
  return heights.first;
}

void main() {
  testWidgets('the skeleton header is exactly as tall as the real one', (
    tester,
  ) async {
    await _pump(tester, const GodownTableShimmer(itemCount: 3));
    final double skeleton = _headerHeight(tester);

    await _pump(tester, StockTable(entries: _entries, onRowTap: () {}));
    final double real = _headerHeight(tester);

    expect(skeleton, real);
  });

  testWidgets('each skeleton row is exactly as tall as a real row', (
    tester,
  ) async {
    await _pump(tester, const GodownTableShimmer(itemCount: 3));
    final List<double> skeletonRows = _bandHeights(tester);
    expect(skeletonRows, hasLength(3));

    await _pump(tester, StockTable(entries: _entries, onRowTap: () {}));
    final double realRow = _realRowHeight(tester);

    for (final double height in skeletonRows) {
      expect(height, realRow);
    }
  });

  testWidgets('the skeleton alternates its bands like the real table', (
    tester,
  ) async {
    await _pump(tester, const GodownTableShimmer(itemCount: 3));

    final List<Color?> colors = [
      for (final Element element
          in find.byWidgetPredicate(_isDataBand).evaluate())
        if (tester.getSize(find.byWidget(element.widget)).height < 400)
          switch (element.widget) {
            ColoredBox(:final Color color) => color,
            Material(:final Color? color) => color,
            _ => null,
          },
    ];

    expect(colors, [
      AppColors.SURFACE,
      AppColors.BACKGROUND_TINTED,
      AppColors.SURFACE,
    ]);
  });

  testWidgets('the skeleton drops the bordered boxes the table never draws', (
    tester,
  ) async {
    await _pump(tester, const GodownTableShimmer(itemCount: 3));

    // The card skeleton wrapped every row in a bordered rounded box. The real
    // page is flat bands under one tinted header, so those borders would show
    // up as a flash of structure that immediately disappears.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).border != null,
      ),
      findsNothing,
    );
  });

  testWidgets('the skeleton header matches the real table width', (
    tester,
  ) async {
    await _pump(tester, const GodownTableShimmer(itemCount: 3));
    final double skeleton = tester
        .getSize(find.byType(GodownTableShimmer))
        .width;

    await _pump(tester, StockTable(entries: _entries, onRowTap: () {}));
    final double real = tester.getSize(find.byType(StockTable)).width;

    expect(skeleton, real);
  });
}
