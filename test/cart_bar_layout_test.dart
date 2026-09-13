import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_erp/core/config/app_config_keys.dart';
import 'package:frontend_erp/features/products/data/models/cart_line.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/presentation/widgets/cart_bar.dart';

List<CartLine> _linesFor(int count) => [
  for (int i = 0; i < count; i++)
    CartLine(
      packaging: ProductPackaging(
        publicId: 'PP-$i',
        productName: 'SAI-3$i',
        imageUrl: '/media/products/$i.jpg',
        sellingPrice: 4800,
      ),
    ),
];

Future<Size> _barSize(WidgetTester tester, int itemCount) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFEEEEEE))),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CartBar(
                lines: _linesFor(itemCount),
                itemCount: itemCount,
                total: itemCount * 4800,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.getSize(find.byType(CartBar));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: AppConfigKeys.ENV_FILE_DEV);
  });

  testWidgets('an empty cart is fully hidden', (tester) async {
    await _barSize(tester, 0);

    // Slid off-screen and faded out, so it covers no grid content.
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity).first,
    );
    expect(opacity.opacity, 0);
  });

  testWidgets('a filled cart previews its items with the count and total',
      (tester) async {
    await _barSize(tester, 2);

    expect(find.text('View cart'), findsOneWidget);
    expect(find.text('2 items  ₹9,600'), findsOneWidget);
    // One thumbnail per line, previewing what is in the cart.
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('thumbnails are capped so a big cart stays compact',
      (tester) async {
    await _barSize(tester, 6);

    expect(find.byType(Image), findsNWidgets(3));
    expect(find.text('6 items  ₹28,800'), findsOneWidget);
  });

  testWidgets('the pill stays a single row', (tester) async {
    await _barSize(tester, 1);

    final Size pill = tester.getSize(
      find.byType(GestureDetector).last,
    );
    expect(
      pill.height,
      lessThanOrEqualTo(50),
      reason: 'a two-line pill reads as a banner, not a floating action',
    );
  });

  testWidgets('the pill hugs its content rather than filling the width',
      (tester) async {
    tester.view.physicalSize = const Size(738, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _barSize(tester, 1);

    final double pillWidth = tester
        .getSize(find.byType(GestureDetector).last)
        .width;
    expect(
      pillWidth,
      lessThan(500),
      reason: 'a floating pill should not span the screen',
    );
  });
}
