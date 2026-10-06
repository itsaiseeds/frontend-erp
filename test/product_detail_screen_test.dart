import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_erp/core/config/app_config_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/data/products_repository.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/products/presentation/bloc/products_cubit.dart';
import 'package:frontend_erp/features/products/presentation/product_detail_screen.dart';
import 'package:frontend_erp/features/products/presentation/widgets/image_viewer_sheet.dart';

const _bag = ProductPackaging(
  publicId: 'PP-A',
  productName: 'SAI-33',
  stageName: 'Breeder',
  packetWeight: 1.5,
  packets: 40,
  totalWeight: 60,
  sellingPrice: 4800,
  imageUrl: '/media/products/x.jpg',
  descriptionItems: ['High yield', 'Drought tolerant'],
);

Future<ProductsCubit> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(738, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = ProductsCubit(
    repository: ProductsRepository(apiClient: ApiClient()),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<ProductsCubit>.value(
        value: cubit,
        child: const ProductDetailScreen(packaging: _bag),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: AppConfigKeys.ENV_FILE_DEV);
  });

  testWidgets('shows the headline with pack chips and price', (tester) async {
    await _pump(tester);

    expect(find.text('SAI-33'), findsOneWidget);
    // Once in the headline card, once in the sticky action bar.
    expect(find.text('₹4,800'), findsNWidgets(2));

    // Pack make-up and bag weight as chips; the spec strip duplicated these.
    expect(find.text('40 packets × 1.5 kg'), findsWidgets);
    expect(find.text('Total: 60 Kg'), findsOneWidget);
  });

  testWidgets('the duplicated spec strip is gone', (tester) async {
    await _pump(tester);

    expect(find.text('Packet weight'), findsNothing);
    expect(find.text('Total weight'), findsNothing);
  });

  testWidgets('renders every description point', (tester) async {
    await _pump(tester);

    expect(find.text('High yield'), findsOneWidget);
    expect(find.text('Drought tolerant'), findsOneWidget);
  });

  testWidgets('the sticky stepper adds to the cart', (tester) async {
    final cubit = await _pump(tester);

    expect(find.text('Add to cart'), findsOneWidget);
    await tester.tap(find.text('Add to cart'));
    await tester.pump();

    expect(cubit.state.quantityOf('PP-A'), 1);
  });

  testWidgets('tapping the hero opens an opaque viewer with the action bar',
      (tester) async {
    await _pump(tester);

    // The hero is the tap target now that the chip and badge are gone.
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    expect(find.byType(ImageViewerSheet), findsOneWidget);
    // The buy action stays reachable while inspecting the packet.
    expect(find.text('Add to cart'), findsOneWidget);
    // No leftover title overlapping the app bar.
    expect(find.text('Product'), findsNothing);
  });

  testWidgets('the stepper inside the image viewer tracks the cart',
      (tester) async {
    final cubit = await _pump(tester);

    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    // A captured widget would keep showing "Add to cart" here.
    expect(cubit.state.quantityOf('PP-A'), 1);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(cubit.state.quantityOf('PP-A'), 2);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('the stage badge sits on the card, not over the product shot',
      (tester) async {
    await _pump(tester);

    expect(find.text('View image'), findsNothing);
    // Exactly one badge, in the details card beside the product name.
    expect(find.text('Breeder'), findsOneWidget);
  });

  testWidgets('the footer price is never squeezed by the cart pill',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    // The cart floats above the bar, so the pack summary and price keep the
    // whole footer row rather than being elided to "20 p... Rs4...".
    expect(find.text('40 packets × 1.5 kg'), findsWidgets);
    expect(find.text('View cart'), findsOneWidget);
  });

  testWidgets('adding shows the stepper and the cart shortcut together',
      (tester) async {
    final cubit = await _pump(tester);

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(cubit.state.quantityOf('PP-A'), 1);
    // Both the quantity control and the way to check out stay reachable.
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text('View cart'), findsOneWidget);
  });
}
