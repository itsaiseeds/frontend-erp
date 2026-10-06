import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_erp/core/constants/app_strings.dart';
import 'package:frontend_erp/core/theme/app_colors.dart';
import 'package:frontend_erp/core/theme/app_spacing.dart';
import 'package:frontend_erp/features/godown/data/models/stock_table_query.dart';
import 'package:frontend_erp/features/godown/presentation/widgets/stock_filter_sheet.dart';

/// The stock filter sheet has to behave like the app's other filter sheets: a
/// rail of sections beside the options, a search box over them, and a footer
/// that only commits on Apply. These pin that behaviour, plus the two things
/// that are stock-specific and easy to break: the controls are single-select,
/// and Clear all must leave the toolbar's search text alone.

Future<void> _pump(WidgetTester tester, StockTableQuery query) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: StockFilterSheet(query: query)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the sheet the way the toolbar does, lets [edit] change it, then taps
/// [commitLabel] and returns whatever the sheet handed back.
Future<StockTableQuery?> _run(
  WidgetTester tester,
  StockTableQuery query, {
  required Future<void> Function(WidgetTester) edit,
  String commitLabel = AppStrings.STOCK_FILTER_APPLY,
}) async {
  StockTableQuery? result;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await StockFilterSheet.show(context, query: query);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  await edit(tester);

  await tester.tap(find.text(commitLabel));
  await tester.pumpAndSettle();

  return result;
}

/// The small primary dot the rail draws beside any section holding a non-default
/// choice. Matched on the circle decoration, which is unique to these; the
/// rail's active bar is a plain coloured bar, not a circle.
int _railDots(WidgetTester tester) => find
    .byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final BoxDecoration? decoration = widget.decoration as BoxDecoration?;
      return decoration?.shape == BoxShape.circle &&
          decoration?.color == AppColors.PRIMARY;
    })
    .evaluate()
    .length;

void main() {
  testWidgets('the rail names both sections and opens on count status', (
    tester,
  ) async {
    await _pump(tester, const StockTableQuery());

    expect(find.text(AppStrings.STOCK_FILTER_COUNT_STATUS), findsOneWidget);
    expect(find.text(AppStrings.STOCK_FILTER_SORT), findsOneWidget);

    // Only the open section's options are listed.
    expect(find.text(AppStrings.STOCK_FILTER_ALL), findsOneWidget);
    expect(find.text(AppStrings.STOCK_SORT_NAME_ASC), findsNothing);
  });

  testWidgets(
    'the sheet fills most of the screen, like the other filter sheets',
    (tester) async {
      await _pump(tester, const StockTableQuery());

      expect(
        tester.getSize(find.byType(StockFilterSheet)).height,
        900 * AppSizes.FILTER_SHEET_HEIGHT,
      );
    },
  );

  testWidgets('the search box and the close button are both offered', (
    tester,
  ) async {
    await _pump(tester, const StockTableQuery());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(AppStrings.CLIENTS_SEARCH_FILTERS), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('the rail marks each section that holds a non-default choice', (
    tester,
  ) async {
    await _pump(
      tester,
      const StockTableQuery(
        filter: StockCountFilter.counted,
        sort: StockSort.availableDesc,
      ),
    );

    expect(_railDots(tester), 2);
  });

  testWidgets('an untouched query marks nothing', (tester) async {
    await _pump(tester, const StockTableQuery());

    expect(_railDots(tester), 0);
  });

  testWidgets('picking a count status and applying returns the new query', (
    tester,
  ) async {
    final StockTableQuery? applied = await _run(
      tester,
      const StockTableQuery(),
      edit: (tester) async {
        await tester.tap(find.text(AppStrings.STOCK_FILTER_NOT_COUNTED));
        await tester.pumpAndSettle();
      },
    );

    expect(applied?.filter, StockCountFilter.notCounted);
    // Untouched controls keep their defaults.
    expect(applied?.sort, StockSort.nameAsc);
  });

  testWidgets('the count status stays single-select', (tester) async {
    await _pump(tester, const StockTableQuery());

    await tester.tap(find.text(AppStrings.STOCK_FILTER_COUNTED));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.STOCK_FILTER_NOT_COUNTED));
    await tester.pumpAndSettle();

    // Picking a second option replaces the first rather than adding to it, so
    // exactly one row carries the selection box.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('the sort section applies its own single choice', (tester) async {
    final StockTableQuery? applied = await _run(
      tester,
      const StockTableQuery(),
      edit: (tester) async {
        await tester.tap(find.text(AppStrings.STOCK_FILTER_SORT));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.STOCK_SORT_NAME_ASC), findsOneWidget);
        await tester.tap(find.text(AppStrings.STOCK_SORT_AVAILABLE_DESC));
        await tester.pumpAndSettle();
      },
    );

    expect(applied?.sort, StockSort.availableDesc);
    expect(applied?.filter, StockCountFilter.all);
  });

  testWidgets('the close button discards the draft', (tester) async {
    StockTableQuery? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await StockFilterSheet.show(
                  context,
                  query: const StockTableQuery(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.STOCK_FILTER_COUNTED));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Null means "no change", which is what a cancel has to mean.
    expect(result, isNull);
  });

  testWidgets('Clear all resets the controls but keeps the toolbar search', (
    tester,
  ) async {
    final StockTableQuery? applied = await _run(
      tester,
      const StockTableQuery(
        search: 'rice',
        filter: StockCountFilter.counted,
        sort: StockSort.availableDesc,
      ),
      edit: (tester) async {
        await tester.tap(find.text(AppStrings.CLIENTS_CLEAR_ALL));
        await tester.pumpAndSettle();
      },
      commitLabel: AppStrings.CLIENTS_CLEAR_ALL,
    );

    // Clear all only clears; the query still has to be applied deliberately.
    expect(applied, isNull);
  });

  testWidgets('Clear all then Apply keeps the search text intact', (
    tester,
  ) async {
    final StockTableQuery? applied = await _run(
      tester,
      const StockTableQuery(
        search: 'rice',
        filter: StockCountFilter.counted,
        sort: StockSort.availableDesc,
      ),
      edit: (tester) async {
        await tester.tap(find.text(AppStrings.CLIENTS_CLEAR_ALL));
        await tester.pumpAndSettle();
      },
    );

    expect(applied?.filter, StockCountFilter.all);
    expect(applied?.sort, StockSort.nameAsc);
    // The search box belongs to the toolbar, so clearing the sheet's controls
    // must not silently wipe what the user typed there.
    expect(applied?.search, 'rice');
  });

  testWidgets('the search box narrows the open section', (tester) async {
    await _pump(tester, const StockTableQuery());

    await tester.enterText(find.byType(TextField), 'today');
    await tester.pumpAndSettle();

    // Matching is on substrings, the same as the app's other filter sheets, so
    // "Counted today" is the only survivor here.
    expect(find.text(AppStrings.STOCK_FILTER_COUNTED), findsOneWidget);
    expect(find.text(AppStrings.STOCK_FILTER_ALL), findsNothing);
    expect(find.text(AppStrings.STOCK_FILTER_NOT_COUNTED), findsNothing);
  });

  testWidgets('a search with no hits says so instead of showing nothing', (
    tester,
  ) async {
    await _pump(tester, const StockTableQuery());

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.CLIENTS_NO_FILTER_MATCH), findsOneWidget);
  });
}
