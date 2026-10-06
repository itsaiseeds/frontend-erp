import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_erp/core/constants/app_strings.dart';
import 'package:frontend_erp/features/godown/data/models/stock_table_query.dart';
import 'package:frontend_erp/features/godown/presentation/widgets/stock_table.dart';
import 'package:frontend_erp/features/godown/presentation/widgets/stock_table_view.dart';

/// The shared view is driven entirely by display fields, so the domain models
/// are not needed to pin its behaviour. Filtering and sorting are the screen's
/// job -- this covers what the view itself owns: the toolbar and the table.
List<StockTableEntry> _entries() => const [
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

Future<void> _pump(
  WidgetTester tester,
  List<StockTableEntry> entries, {
  bool isComplete = false,
  StockTableQuery query = const StockTableQuery(),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StockTableView(
          isComplete: isComplete,
          entries: entries,
          query: query,
          searchController: TextEditingController(text: query.search),
          onSearchChanged: (_) {},
          onClearSearch: () {},
          onFilterApplied: (_) {},
          onOpenFillStock: () {},
          onRefresh: () async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The status icon is icon-only, so its meaning lives in the tooltip.
String _tooltipFor(WidgetTester tester, IconData icon) => tester
    .widget<Tooltip>(
      find
          .ancestor(of: find.byIcon(icon), matching: find.byType(Tooltip))
          .first,
    )
    .message!;

void main() {
  testWidgets('renders a header and one row per entry', (tester) async {
    await _pump(tester, _entries());

    expect(find.text(AppStrings.STOCK_TABLE_PRODUCT_LABEL), findsOneWidget);
    expect(find.text(AppStrings.STOCK_AVAILABLE_LABEL), findsOneWidget);
    for (final StockTableEntry entry in _entries()) {
      expect(find.text(entry.title), findsOneWidget);
    }
  });

  testWidgets('a null available count renders as a dash, not zero', (
    tester,
  ) async {
    await _pump(tester, _entries());

    // `Toor Dal` has no position yet and must not look like a genuine zero.
    expect(find.text(AppStrings.STOCK_AVAILABLE_UNKNOWN), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    // `Sona Masoori` really is zero and must still read as `0`.
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('rows keep the order they were given', (tester) async {
    // Filtering and sorting happen in the screen before the view is built, so
    // the view must not reorder what it is handed.
    await _pump(tester, _entries());

    expect(
      tester.getTopLeft(find.text('Basmati Rice')).dy,
      lessThan(tester.getTopLeft(find.text('Sona Masoori')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Sona Masoori')).dy,
      lessThan(tester.getTopLeft(find.text('Toor Dal')).dy),
    );
  });

  testWidgets('the status icon carries a pending tooltip', (tester) async {
    await _pump(tester, _entries());

    expect(
      _tooltipFor(tester, Icons.pending_outlined),
      AppStrings.STOCK_COUNT_PENDING_TOOLTIP,
    );
  });

  testWidgets('a complete count reports the complete tooltip', (tester) async {
    await _pump(tester, _entries(), isComplete: true);

    expect(
      _tooltipFor(tester, Icons.check_circle_rounded),
      AppStrings.STOCK_COUNT_COMPLETE_TOOLTIP,
    );
  });

  testWidgets('the toolbar reads icon, search, then filter', (tester) async {
    await _pump(tester, _entries());

    final Offset icon = tester.getCenter(find.byIcon(Icons.pending_outlined));
    final Offset search = tester.getCenter(
      find.text(AppStrings.STOCK_SEARCH_HINT),
    );
    final Offset filter = tester.getCenter(find.byIcon(Icons.tune_rounded));

    expect(icon.dx, lessThan(search.dx));
    expect(search.dx, lessThan(filter.dx));
  });

  testWidgets('an inactive filter shows no count badge', (tester) async {
    await _pump(tester, _entries());

    // The tune icon is the only control on the toolbar with no text label.
    expect(find.text('0'), findsOneWidget); // the genuine zero count
    expect(find.text('1'), findsNothing);
  });

  testWidgets('an active filter and sort shows a count badge', (tester) async {
    await _pump(
      tester,
      _entries(),
      query: const StockTableQuery(
        filter: StockCountFilter.counted,
        sort: StockSort.availableDesc,
      ),
    );

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('an empty entry list shows the no-match state', (tester) async {
    await _pump(tester, const []);

    expect(find.text(AppStrings.STOCK_NO_SEARCH_MATCH), findsOneWidget);
  });
}
