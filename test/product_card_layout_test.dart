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

Future<void> _pumpCard(
  WidgetTester tester, {
  required double width,
  required double height,
  required int quantity,
  ProductPackaging packaging = _bag,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ProductCard(
              packaging: packaging,
              quantity: quantity,
              onTap: () {},
              onAdd: () {},
              onRemove: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a long price renders in full, not truncated', (tester) async {
    await _pumpCard(
      tester,
      width: 168,
      height: 238,
      quantity: 0,
      packaging: const ProductPackaging(
        publicId: 'PP-C',
        productName: 'SAI-32',
        stageName: 'Research',
        packetWeight: 2,
        packets: 30,
        totalWeight: 60,
        sellingPrice: 125000,
      ),
    );

    // The screenshot showed the stepper stealing the price row, giving "Rs1,2...".
    expect(find.text('₹1,25,000'), findsOneWidget);
  });

  // A 738px-wide phone at ratio 0.53 gives a 168 x 317 cell.
  testWidgets('fits the real grid cell without overflowing',
      (tester) async {
    await _pumpCard(tester, width: 168, height: 238, quantity: 0);

    expect(tester.takeException(), isNull);
  });

  testWidgets('fits with the stepper expanded', (tester) async {
    await _pumpCard(tester, width: 168, height: 238, quantity: 3);

    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a long product name and no stage', (tester) async {
    await _pumpCard(
      tester,
      width: 168,
      height: 301.6,
      quantity: 1,
      packaging: const ProductPackaging(
        publicId: 'PP-B',
        productName: 'A Very Long Product Name That Wraps Twice Over',
        packetWeight: 1.5,
        packets: 20,
        totalWeight: 30,
        sellingPrice: 5000,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows packet make-up and total weight on separate lines',
      (tester) async {
    await _pumpCard(tester, width: 168, height: 238, quantity: 0);

    expect(find.text('40 packets × 1 kg'), findsOneWidget);
    expect(find.text('40 Kg'), findsOneWidget);
  });

  testWidgets('renders the product name at its full height, not clipped',
      (tester) async {
    await _pumpCard(tester, width: 168, height: 238, quantity: 0);

    final Size size = tester.getSize(find.text('SAI-33'));
    expect(
      size.height,
      greaterThan(14),
      reason: 'a squeezed name row clips the glyphs mid-letter',
    );
  });

  testWidgets('shows price, stage and the ADD button together',
      (tester) async {
    await _pumpCard(tester, width: 168, height: 238, quantity: 0);

    expect(find.text('₹4,800'), findsOneWidget);
    expect(find.text('Breeder'), findsOneWidget);
    expect(find.text('ADD'), findsOneWidget);
  });

  testWidgets('fits a narrower cell', (tester) async {
    await _pumpCard(tester, width: 150, height: 238, quantity: 2);

    expect(tester.takeException(), isNull);
  });
}
