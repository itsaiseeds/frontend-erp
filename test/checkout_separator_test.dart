import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/config/app_config_keys.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/data/products_repository.dart';
import 'package:frontend_erp/features/products/presentation/bloc/products_cubit.dart';
import 'package:frontend_erp/features/products/presentation/checkout_screen.dart';
import 'package:frontend_erp/features/products/presentation/widgets/cart_line_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screen loads clients on open; stub it so the test measures layout
/// rather than the network.
class _EmptyClientsAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"total_count":0,"total_pages":0,"next_page_number":null,'
      '"previous_page_number":null,"results":[],'
      '"available_filters":[],"available_sorts":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _stubbedClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = _EmptyClientsAdapter();
  return ApiClient(dio: dio);
}

ProductPackaging _bag(String id) => ProductPackaging(
  publicId: id,
  productName: 'SAI-$id',
  packetWeight: 2,
  packets: 40,
  sellingPrice: 2400,
);

Future<void> _pumpCart(WidgetTester tester, int productCount) async {
  tester.view.physicalSize = const Size(738, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final ApiClient apiClient = _stubbedClient();
  final cubit = ProductsCubit(
    repository: ProductsRepository(apiClient: apiClient),
  );
  addTearDown(cubit.close);

  for (int index = 0; index < productCount; index++) {
    cubit.addToCart(_bag('$index'));
  }

  await tester.pumpWidget(
    MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          BlocProvider<ProductsCubit>.value(value: cubit),
        ],
        child: const CheckoutScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: AppConfigKeys.ENV_FILE_DEV);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('three products get two separators', (tester) async {
    await _pumpCart(tester, 3);

    expect(find.byType(CartLineTile), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('a single product gets no separator', (tester) async {
    await _pumpCart(tester, 1);

    expect(find.byType(CartLineTile), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('the separator sits between products, never above the '
      'first one', (tester) async {
    await _pumpCart(tester, 2);

    final double firstTile = tester
        .getTopLeft(find.byType(CartLineTile).first)
        .dy;
    final double rule = tester.getTopLeft(find.byType(Divider)).dy;

    expect(rule, greaterThan(firstTile));
  });
}
