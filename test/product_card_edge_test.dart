import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/presentation/widgets/product_card.dart';

void main() {
  testWidgets('ADD is tappable at its right edge', (tester) async {
    int add = 0, tap = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 168,
              height: 238,
              child: ProductCard(
                packaging: const ProductPackaging(
                  publicId: 'PP-A',
                  productName: 'SAI-33',
                  stageName: 'Breeder',
                  packetWeight: 1,
                  packets: 40,
                  totalWeight: 40,
                  sellingPrice: 4800,
                ),
                quantity: 0,
                onTap: () => tap++,
                onAdd: () => add++,
                onRemove: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Rect box = tester.getRect(find.text('ADD'));
    // Tap near the right edge of the pill, where a negative offset would
    // push it outside the Stack and make it inert.
    await tester.tapAt(Offset(box.right + 6, box.center.dy));
    await tester.pump();

    expect(add, 1, reason: 'right edge of ADD must still register');
    expect(tap, 0);
  });
}
