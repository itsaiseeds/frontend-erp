import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/products/presentation/widgets/quantity_stepper.dart';

Future<void> _pumpUnbounded(WidgetTester tester, int quantity) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            // No bounded width: this is the shape that crashed in the cart
            // line tile and the detail footer.
            SizedBox(
              height: 34,
              child: QuantityStepper(
                quantity: quantity,
                onAdd: () {},
                onRemove: () {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the stepper lays out without a bounded width', (tester) async {
    await _pumpUnbounded(tester, 2);

    expect(tester.takeException(), isNull);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('the ADD pill lays out without a bounded width',
      (tester) async {
    await _pumpUnbounded(tester, 0);

    expect(tester.takeException(), isNull);
    expect(find.text('ADD'), findsOneWidget);
  });

  testWidgets('the stepper hugs its buttons rather than stretching',
      (tester) async {
    await _pumpUnbounded(tester, 2);

    final double width = tester.getSize(find.byType(QuantityStepper)).width;
    expect(
      width,
      lessThan(120),
      reason: 'a stretched stepper leaves a wide gap around the count',
    );
  });
}
