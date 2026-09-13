import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/presentation/widgets/product_card.dart';

const _bag = ProductPackaging(
  publicId: 'PP-A',
  productName: 'SAI-33',
  stageName: 'Breeder',
  packetWeight: 1,
  packets: 40,
  totalWeight: 40,
  sellingPrice: 4800,
);

Future<Map<String, int>> _pump(WidgetTester tester, int quantity) async {
  final counts = {'tap': 0, 'add': 0, 'remove': 0};

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 168,
            height: 238,
            child: ProductCard(
              packaging: _bag,
              quantity: quantity,
              onTap: () => counts['tap'] = counts['tap']! + 1,
              onAdd: () => counts['add'] = counts['add']! + 1,
              onRemove: () => counts['remove'] = counts['remove']! + 1,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return counts;
}

void main() {
  testWidgets('tapping ADD adds to the cart and does NOT open the detail view',
      (tester) async {
    final counts = await _pump(tester, 0);

    await tester.tap(find.text('ADD'));
    await tester.pump();

    expect(counts['add'], 1);
    expect(counts['tap'], 0, reason: 'ADD must not fall through to the card');
  });

  testWidgets('plus and minus do not open the detail view', (tester) async {
    final counts = await _pump(tester, 2);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();

    expect(counts['add'], 1);
    expect(counts['remove'], 1);
    expect(counts['tap'], 0, reason: 'stepper must not fall through');
  });

  testWidgets('tapping the card body still opens the detail view',
      (tester) async {
    final counts = await _pump(tester, 0);

    await tester.tap(find.text('SAI-33'));
    await tester.pump();

    expect(counts['tap'], 1);
    expect(counts['add'], 0);
  });

  testWidgets('the price is visible on the card', (tester) async {
    await _pump(tester, 0);

    expect(find.text('₹4,800'), findsOneWidget);
  });
}
