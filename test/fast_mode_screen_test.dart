import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_erp/core/constants/app_strings.dart';
import 'package:frontend_erp/core/widgets/dialogs/confirmation_dialog.dart';
import 'package:frontend_erp/features/godown/presentation/fast_mode_screen.dart';
import 'package:frontend_erp/features/godown/presentation/widgets/fast_mode_row.dart';

List<FastModeRow> _rows(
  int count, {
  int? preCountedFirst,
  String imageUrl = '',
}) => [
  for (int i = 0; i < count; i++)
    FastModeRow(
      key: 'row-$i',
      title: 'Product $i',
      subtitle: '20 PACKETS x 1.5 KG',
      imageUrl: imageUrl,
      draftCount: i == 0 ? preCountedFirst : null,
    ),
];

class _Counts {
  final Map<String, int?> values = {};
  int submitCalls = 0;
  bool submitResult = true;
}

Future<_Counts> _pump(WidgetTester tester, List<FastModeRow> rows) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);

  final _Counts counts = _Counts();

  await tester.pumpWidget(
    MaterialApp(
      home: FastModeScreen(
        title: 'Bag Stock',
        unitLabel: AppStrings.STOCK_BAGS_UNIT,
        rows: rows,
        onCountChanged: (key, count) => counts.values[key] = count,
        onSubmit: () async {
          counts.submitCalls++;
          return counts.submitResult;
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return counts;
}

/// Opens the review page the same way a user would: tap "Review" in the
/// progress header rather than swiping, so the affordance itself is covered.
Future<void> _openSummary(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.STOCK_SUMMARY_REVIEW));
  await tester.pumpAndSettle();
}

/// Confirms the dialog. Scoped to [ConfirmationDialog] because the app bar and
/// the dialog both carry an "Update" label once the summary is open.
Future<void> _confirmDialog(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(ConfirmationDialog),
      matching: find.widgetWithText(TextButton, AppStrings.STOCK_UPDATE),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _swipeForward(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-420, 0));
  await tester.pumpAndSettle();
}

/// Targets the progress segment only. `find.bySemanticsLabel` also matches the
/// product name rendered inside the card, which would be an ambiguous tap.
Finder segmentFor(String title) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == title,
);

void main() {
  testWidgets('shows the product name and packaging detail', (tester) async {
    await _pump(tester, _rows(1));

    expect(find.text('Product 0'), findsOneWidget);
    expect(find.text('20 PACKETS x 1.5 KG'), findsOneWidget);
  });

  testWidgets('the packaging detail sits on a single line', (tester) async {
    await _pump(tester, _rows(1));

    final Text subtitle = tester.widget<Text>(find.text('20 PACKETS x 1.5 KG'));
    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
  });

  testWidgets('the app bar offers a Done way out', (tester) async {
    await _pump(tester, _rows(2));

    expect(find.text(AppStrings.STOCK_FAST_MODE_DONE), findsOneWidget);
  });

  testWidgets('the product detail fits without scrolling', (tester) async {
    await _pump(tester, _rows(1));

    // Scoped to the card's own scroll view: `PageView` and the review table
    // are also `Scrollable`s, and a bare `find.byType(Scrollable)` would pick
    // up the horizontal pager instead.
    final ScrollableState scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(
      scrollable.position.maxScrollExtent,
      lessThanOrEqualTo(0.0),
      reason: 'a normal handset must not have to scroll to see the whole card',
    );
  });

  testWidgets('a long product name is capped at two lines', (tester) async {
    await _pump(tester, [
      const FastModeRow(
        key: 'long',
        title: 'SAI-3353 Super Premium Extra Long Product Name Variant',
        subtitle: '20 PACKETS x 1.5 KG',
      ),
    ]);

    final Text title = tester.widget<Text>(find.textContaining('SAI-3353'));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets('no stock-position figures clutter the counting card', (
    tester,
  ) async {
    await _pump(tester, _rows(2));

    expect(find.textContaining('Consumed'), findsNothing);
    expect(find.textContaining('Reserved'), findsNothing);
  });

  testWidgets('shows the progress as one of many', (tester) async {
    await _pump(tester, _rows(4));

    expect(
      find.text('1 ${AppStrings.STOCK_FAST_MODE_PROGRESS_OF} 4'),
      findsOneWidget,
    );
  });

  testWidgets('a counted visited row raises no skipped marker', (tester) async {
    await _pump(tester, _rows(3, preCountedFirst: 5));

    await _swipeForward(tester);

    expect(find.text(AppStrings.STOCK_FAST_MODE_SKIPPED_ONE), findsNothing);
    expect(find.text(AppStrings.STOCK_FAST_MODE_SKIPPED_HINT), findsNothing);
  });

  testWidgets('the row just opened is not yet called skipped', (tester) async {
    await _pump(tester, _rows(3, preCountedFirst: 5));

    // Landing on row 1 must not immediately mark it skipped; the user has
    // still not had the chance to enter a count.
    await _swipeForward(tester);

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text(AppStrings.STOCK_FAST_MODE_SKIPPED_ONE), findsNothing);
  });

  testWidgets('leaving a row empty behind you flags it as skipped', (
    tester,
  ) async {
    await _pump(tester, _rows(3, preCountedFirst: 5));

    // Go to row 1, then swipe past it without typing.
    await _swipeForward(tester);
    await _swipeForward(tester);

    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text(AppStrings.STOCK_FAST_MODE_SKIPPED_ONE), findsOneWidget);
    expect(find.text(AppStrings.STOCK_FAST_MODE_SKIPPED_HINT), findsOneWidget);
  });

  testWidgets('the skipped marker follows the row left behind', (tester) async {
    await _pump(tester, _rows(3, preCountedFirst: 5));

    await _swipeForward(tester);
    await _swipeForward(tester);
    expect(find.text(AppStrings.STOCK_FAST_MODE_SKIPPED_ONE), findsOneWidget);

    // Going back un-skips row 1, but row 2 is now the one left empty, so the
    // marker should move rather than disappear.
    await tester.tap(segmentFor('Product 1'));
    await tester.pumpAndSettle();
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text(AppStrings.STOCK_FAST_MODE_SKIPPED_ONE), findsOneWidget);

    await tester.tap(segmentFor('Product 0'));
    await tester.pumpAndSettle();
    expect(
      find.text('2 ${AppStrings.STOCK_FAST_MODE_SKIPPED_MANY}'),
      findsOneWidget,
    );
  });

  testWidgets('several skipped rows report a count, not a single', (
    tester,
  ) async {
    await _pump(tester, _rows(4, preCountedFirst: 5));

    await _swipeForward(tester);
    await _swipeForward(tester);
    await _swipeForward(tester);

    expect(
      find.text('2 ${AppStrings.STOCK_FAST_MODE_SKIPPED_MANY}'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a segment jumps straight to that product', (
    tester,
  ) async {
    await _pump(tester, _rows(3, preCountedFirst: 5));

    expect(find.text('Product 0'), findsOneWidget);

    await tester.tap(segmentFor('Product 2'));
    await tester.pumpAndSettle();

    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('Product 0'), findsNothing);
  });

  testWidgets('tapping a skipped segment jumps back to it', (tester) async {
    await _pump(tester, _rows(3, preCountedFirst: 5));

    // Move past row 1 so it is flagged, then return via the marker.
    await _swipeForward(tester);
    await _swipeForward(tester);
    expect(find.text('Product 2'), findsOneWidget);

    await tester.tap(segmentFor('Product 1'));
    await tester.pumpAndSettle();

    expect(find.text('Product 1'), findsOneWidget);
  });

  testWidgets('typing a digit records a count for the visible row', (
    tester,
  ) async {
    final _Counts counts = await _pump(tester, _rows(2));

    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();

    expect(counts.values['row-0'], 7);
  });

  testWidgets('clearing a count reports null, not zero', (tester) async {
    final _Counts counts = await _pump(tester, _rows(1, preCountedFirst: 5));

    // Null must reach the cubit so the row counts as uncounted rather than
    // counted-as-zero.
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pumpAndSettle();

    expect(counts.values.containsKey('row-0'), isTrue);
    expect(counts.values['row-0'], isNull);
  });

  testWidgets('an empty row list shows the nothing-to-count state', (
    tester,
  ) async {
    await _pump(tester, const []);

    expect(find.text(AppStrings.STOCK_NO_PACKAGINGS_TITLE), findsOneWidget);
  });

  group('review summary', () {
    testWidgets('Review opens the final summary page', (tester) async {
      await _pump(tester, _rows(3, preCountedFirst: 5));

      expect(find.text(AppStrings.STOCK_SUMMARY_REVIEW), findsOneWidget);
      expect(find.text(AppStrings.STOCK_UPDATE), findsNothing);

      await _openSummary(tester);

      // The summary is the last page and replaces the counting app bar action.
      expect(find.text(AppStrings.STOCK_SUMMARY_TITLE), findsOneWidget);
      expect(find.text(AppStrings.STOCK_UPDATE), findsOneWidget);
      expect(find.text(AppStrings.STOCK_FAST_MODE_DONE), findsNothing);
      // Every product is listed so the whole run is reviewable at once.
      for (int i = 0; i < 3; i++) {
        expect(find.text('Product $i'), findsOneWidget);
      }
    });

    testWidgets('summary lists each entered count and marks blanks', (
      tester,
    ) async {
      await _pump(tester, _rows(3, preCountedFirst: 5));
      await _openSummary(tester);

      expect(find.text('5'), findsOneWidget);
      expect(find.text(AppStrings.STOCK_SUMMARY_MISSING), findsNWidgets(2));
      expect(
        find.text('1 ${AppStrings.STOCK_SUMMARY_COUNTED}'),
        findsOneWidget,
      );
      expect(
        find.text('2 ${AppStrings.STOCK_SUMMARY_MISSING}'),
        findsOneWidget,
      );
    });

    testWidgets('tapping a summary row jumps back to that product', (
      tester,
    ) async {
      await _pump(tester, _rows(3, preCountedFirst: 5));
      await _openSummary(tester);

      await tester.tap(find.text('Product 2'));
      await tester.pumpAndSettle();

      expect(find.text('Product 2'), findsOneWidget);
      expect(find.text(AppStrings.STOCK_FAST_MODE_DONE), findsOneWidget);
    });

    testWidgets('Update asks for confirmation and does not save on cancel', (
      tester,
    ) async {
      final _Counts counts = await _pump(tester, _rows(2, preCountedFirst: 5));
      await _openSummary(tester);

      await tester.tap(find.text(AppStrings.STOCK_UPDATE));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.STOCK_UPDATE_CONFIRM_TITLE), findsOneWidget);
      expect(counts.submitCalls, 0);

      await tester.tap(find.text(AppStrings.CANCEL));
      await tester.pumpAndSettle();

      expect(counts.submitCalls, 0);
      // Cancelling keeps the user on the review page with entries intact.
      expect(find.text(AppStrings.STOCK_SUMMARY_TITLE), findsOneWidget);
    });

    testWidgets('confirming Update saves and closes Fill Stock', (
      tester,
    ) async {
      final _Counts counts = await _pump(tester, _rows(2, preCountedFirst: 5));
      await _openSummary(tester);

      await tester.tap(find.text(AppStrings.STOCK_UPDATE));
      await tester.pumpAndSettle();
      await _confirmDialog(tester);

      expect(counts.submitCalls, 1);
      expect(find.byType(FastModeScreen), findsNothing);
    });

    testWidgets('a failed save keeps the review page open', (tester) async {
      final _Counts counts = await _pump(tester, _rows(2, preCountedFirst: 5));
      counts.submitResult = false;
      await _openSummary(tester);

      await tester.tap(find.text(AppStrings.STOCK_UPDATE));
      await tester.pumpAndSettle();
      await _confirmDialog(tester);

      expect(counts.submitCalls, 1);
      expect(find.byType(FastModeScreen), findsOneWidget);
      expect(find.text(AppStrings.STOCK_SUMMARY_TITLE), findsOneWidget);
    });

    testWidgets('nothing counted blocks Update with a warning', (tester) async {
      final _Counts counts = await _pump(tester, _rows(2));
      await _openSummary(tester);

      await tester.tap(find.text(AppStrings.STOCK_UPDATE));
      await tester.pumpAndSettle();

      // No dialog and no submit -- an empty run cannot be confirmed. The toast
      // itself is deliberately not asserted: it renders through the global
      // toastification overlay, which is not part of this widget's contract.
      expect(find.text(AppStrings.STOCK_UPDATE_CONFIRM_TITLE), findsNothing);
      expect(find.byType(ConfirmationDialog), findsNothing);
      expect(counts.submitCalls, 0);
    });
  });
}
