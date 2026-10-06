import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_erp/core/constants/app_strings.dart';
import 'package:frontend_erp/features/godown/presentation/widgets/stock_available_cell.dart';

Future<void> _pump(WidgetTester tester, int? available) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: StockAvailableCell(available: available)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the bare available figure', (tester) async {
    await _pump(tester, 42);

    expect(find.text('42'), findsOneWidget);
    // The table header owns the column label; repeating it per row is what
    // makes a table read as a stack of cards.
    expect(find.text(AppStrings.STOCK_AVAILABLE_LABEL), findsNothing);
  });

  testWidgets('an uncounted lot shows a dash, never a zero', (tester) async {
    await _pump(tester, null);

    expect(find.text(AppStrings.STOCK_AVAILABLE_UNKNOWN), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a genuine zero available is shown as zero', (tester) async {
    await _pump(tester, 0);

    expect(find.text('0'), findsOneWidget);
    expect(find.text(AppStrings.STOCK_AVAILABLE_UNKNOWN), findsNothing);
  });
}
