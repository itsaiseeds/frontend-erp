import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/orders/data/models/order.dart';
import 'package:frontend_erp/features/orders/data/models/order_status.dart';
import 'package:frontend_erp/features/orders/data/models/orders_query.dart';
import 'package:frontend_erp/features/orders/data/orders_repository.dart';
import 'package:frontend_erp/features/orders/presentation/bloc/orders_cubit.dart';
import 'package:frontend_erp/features/orders/presentation/order_detail_screen.dart';
import 'package:frontend_erp/features/orders/presentation/orders_screen.dart';
import 'package:frontend_erp/features/orders/presentation/widgets/order_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _orderJson(String id, {String status = 'BOOKED'}) =>
    '{"public_id":"$id","created_at":"2026-09-13T17:25:49.434Z",'
    '"status":"$status","client":{"public_id":"C-1",'
    '"company_name":"Gurukrupa"},"delivery_address":"Ring Road, Rajkot",'
    '"city":{"id":7,"name":"Rajkot"},"expected_delivery_date":"2026-09-20",'
    '"dispatch_mode":"AGENCY","total_amount":"35000.00","total_packets":120,'
    '"item_count":3,"verified":false,"verified_by":null,'
    '"verified_at":null,"packagings":['
    '{"public_id":"PP-1","negotiated_selling_price":"2400.00",'
    '"product":{"public_id":"P-1","name":"SAI-30","image_url":""},'
    '"packet_weight":"2.00","packets":40,"total_weight":"80.00",'
    '"selling_price":"2400.00","quantity":2},'
    '{"public_id":"PP-2","negotiated_selling_price":"1200.00",'
    '"product":{"public_id":"P-2","name":"SAI-31","image_url":""},'
    '"packet_weight":"1.00","packets":30,"total_weight":"30.00",'
    '"selling_price":"1200.00","quantity":1},'
    '{"public_id":"PP-3","negotiated_selling_price":"400.00",'
    '"product":{"public_id":"P-3","name":"SAI-32","image_url":""},'
    '"packet_weight":"1.00","packets":5,"total_weight":"5.00",'
    '"selling_price":"400.00","quantity":4}]}';

class _OrdersAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final int pageCount;
  final bool isEmpty;

  _OrdersAdapter({this.pageCount = 1, this.isEmpty = false});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final int page = int.tryParse('${options.queryParameters['page']}') ?? 1;
    final int? next = page < pageCount ? page + 1 : null;
    final String results = isEmpty ? '' : _orderJson('O-PAGE$page');

    return ResponseBody.fromString(
      '{"total_count":${isEmpty ? 0 : pageCount},"total_pages":$pageCount,'
      '"next_page_number":${next ?? 'null'},"previous_page_number":null,'
      '"results":[$results],'
      '"available_filters":[{"filter":"status","label":"Status",'
      '"kind":"select","description":"","params":[],'
      '"options":[{"value":"BOOKED","label":"Booked"}]}],'
      '"available_sorts":[{"sort":"created_at","label":"Created",'
      '"description":""}]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientOf(_OrdersAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;
  return ApiClient(dio: dio);
}

OrdersCubit _cubitOf(_OrdersAdapter adapter) =>
    OrdersCubit(repository: OrdersRepository(apiClient: _clientOf(adapter)));

Future<void> _pumpScreen(WidgetTester tester, _OrdersAdapter adapter) async {
  tester.view.physicalSize = const Size(738, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Provider<ApiClient>.value(
        value: _clientOf(adapter),
        child: const OrdersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _order = Order(
  publicId: 'O-ABC123',
  status: OrderStatus.dispatched,
  client: OrderClient(publicId: 'C-1', companyName: 'Gurukrupa'),
  deliveryAddress: 'Plot 4, Ring Road, Rajkot',
  city: OrderCity(id: 7, name: 'Rajkot'),
  dispatchMode: 'AGENCY',
  totalAmount: 35000,
  totalPackets: 120,
  itemCount: 3,
  packagings: [
    OrderPackaging(
      publicId: 'PP-1',
      productPublicId: 'P-1',
      productName: 'SAI-30',
      packetWeight: 2,
      packets: 40,
      totalWeight: 80,
      sellingPrice: 2500,
      negotiatedSellingPrice: 2400,
      quantity: 2,
    ),
    OrderPackaging(
      publicId: 'PP-2',
      productPublicId: 'P-2',
      productName: 'SAI-31',
      packetWeight: 1,
      packets: 30,
      totalWeight: 30,
      sellingPrice: 1200,
      negotiatedSellingPrice: 1200,
      quantity: 1,
    ),
    OrderPackaging(
      publicId: 'PP-3',
      productPublicId: 'P-3',
      productName: 'SAI-32',
      packetWeight: 1,
      packets: 5,
      totalWeight: 5,
      sellingPrice: 400,
      negotiatedSellingPrice: 400,
      quantity: 4,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('orders cubit', () {
    test('loads the first page and keeps the filter catalogue', () async {
      final adapter = _OrdersAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();

      expect(cubit.state.orders, hasLength(1));
      expect(cubit.state.availableFilters.single.key, 'status');
      expect(cubit.state.availableSorts.single.title, 'Created');

      await cubit.close();
    });

    test('hits the orders endpoint with paging params', () async {
      final adapter = _OrdersAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();

      final RequestOptions request = adapter.requests.single;
      expect(request.path, contains('get-orders'));
      expect(request.queryParameters['page'], 1);
      expect(request.queryParameters['page_size'], OrdersCubit.PAGE_SIZE);

      await cubit.close();
    });

    test('loadMore appends the next page rather than replacing', () async {
      final adapter = _OrdersAdapter(pageCount: 2);
      final cubit = _cubitOf(adapter);

      await cubit.load();
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();

      expect(cubit.state.orders, hasLength(2));
      expect(cubit.state.orders.first.publicId, 'O-PAGE1');
      expect(cubit.state.orders.last.publicId, 'O-PAGE2');
      expect(cubit.state.hasMore, isFalse);

      await cubit.close();
    });

    test('a filter selection reaches the request as a param', () async {
      final adapter = _OrdersAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.applyQuery(
        const OrdersQuery(
          selections: {
            'status': {'BOOKED', 'CONFIRMED'},
          },
        ),
      );

      final String sent = '${adapter.requests.last.queryParameters['status']}';
      expect(sent.split(','), containsAll(<String>['BOOKED', 'CONFIRMED']));

      await cubit.close();
    });

    test('sorting descending prefixes the key with a minus', () async {
      final adapter = _OrdersAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.applyQuery(
        const OrdersQuery(sort: 'created_at', descending: true),
      );

      expect(adapter.requests.last.queryParameters['sort'], '-created_at');

      await cubit.close();
    });

    test('refresh refetches instead of serving the cache', () async {
      final adapter = _OrdersAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();
      await cubit.load();
      expect(adapter.requests, hasLength(1));

      await cubit.refresh();
      expect(adapter.requests, hasLength(2));

      await cubit.close();
    });
  });

  group('orders screen', () {
    testWidgets('renders a card per order', (tester) async {
      await _pumpScreen(tester, _OrdersAdapter());

      expect(find.byType(OrderCard), findsOneWidget);
      expect(find.text('Gurukrupa'), findsOneWidget);
    });

    testWidgets('shows an empty message when there are no orders', (
      tester,
    ) async {
      await _pumpScreen(tester, _OrdersAdapter(isEmpty: true));

      expect(find.byType(OrderCard), findsNothing);
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('tapping a card opens the order preview', (tester) async {
      await _pumpScreen(tester, _OrdersAdapter());

      await tester.tap(find.byType(OrderCard));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.text('Order details'), findsOneWidget);
    });

    testWidgets('the list can be pulled down to refresh', (tester) async {
      await _pumpScreen(tester, _OrdersAdapter());

      expect(find.byType(RefreshIndicator), findsOneWidget);

      await tester.fling(find.byType(OrderCard), const Offset(0, 320), 1000);
      await tester.pumpAndSettle();

      expect(find.byType(OrderCard), findsOneWidget);
    });
  });

  group('order card', () {
    Future<void> pumpCard(WidgetTester tester, Order order) async {
      tester.view.physicalSize = const Size(738, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OrderCard(order: order)),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows client, city, total and status', (tester) async {
      await pumpCard(tester, _order);

      expect(find.text('Gurukrupa'), findsOneWidget);
      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Dispatched'), findsOneWidget);
      expect(find.textContaining('35,000'), findsOneWidget);
    });

    testWidgets('does not show the public id', (tester) async {
      await pumpCard(tester, _order);

      expect(find.text('O-ABC123'), findsNothing);
    });

    testWidgets('keeps product pictures off the card', (tester) async {
      await pumpCard(
        tester,
        Order(
          publicId: 'O-1',
          client: const OrderClient(companyName: 'Acme'),
          packagings: const [
            OrderPackaging(
              publicId: 'PP-1',
              productName: 'SAI-30',
              imageUrl: '/media/products/sai30.jpg',
              quantity: 1,
            ),
          ],
        ),
      );

      // The picture belongs to the preview; the card stays a text summary.
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('counts bags as well as packets', (tester) async {
      await pumpCard(tester, _order);

      // 2 + 1 + 4 bags across the three lines, 120 packets overall.
      expect(find.textContaining('7 bags'), findsOneWidget);
      expect(find.textContaining('120 packets'), findsOneWidget);
    });

    testWidgets('marks a verified order', (tester) async {
      await pumpCard(
        tester,
        const Order(
          publicId: 'O-1',
          client: OrderClient(companyName: 'Acme'),
          isVerified: true,
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('an unverified order carries no verified mark', (tester) async {
      await pumpCard(tester, _order);

      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('stamps the booking time in IST', (tester) async {
      await pumpCard(
        tester,
        Order(
          publicId: 'O-1',
          client: const OrderClient(companyName: 'Acme'),
          createdAt: DateTime.utc(2026, 9, 13, 17, 27, 18),
        ),
      );

      // 17:27 UTC is 10:57 PM IST, the same evening.
      expect(find.textContaining('10:57 PM'), findsOneWidget);
      expect(find.textContaining('IST'), findsOneWidget);
      expect(find.textContaining('13 Sep'), findsOneWidget);
    });

    testWidgets('summarises extra products instead of listing them all', (
      tester,
    ) async {
      await pumpCard(tester, _order);

      expect(find.text('SAI-30'), findsOneWidget);
      expect(find.text('SAI-31'), findsOneWidget);
      // The third is rolled into a count, keeping the card a fixed shape.
      expect(find.text('SAI-32'), findsNothing);
      expect(find.text('+1 more'), findsOneWidget);
    });

    testWidgets('falls back to the address when there is no city', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const Order(
          publicId: 'O-1',
          deliveryAddress: 'Ring Road, Rajkot',
          client: OrderClient(companyName: 'Acme'),
        ),
      );

      expect(find.text('Ring Road, Rajkot'), findsOneWidget);
    });
  });

  group('order preview', () {
    Future<void> pumpDetail(WidgetTester tester, Order order) async {
      tester.view.physicalSize = const Size(738, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(home: OrderDetailScreen(order: order)),
      );
      await tester.pump();
    }

    testWidgets('lists every product, not just the first few', (tester) async {
      await pumpDetail(tester, _order);

      expect(find.text('SAI-30'), findsOneWidget);
      expect(find.text('SAI-31'), findsOneWidget);
      expect(find.text('SAI-32'), findsOneWidget);
    });

    testWidgets('shows the totals and the delivery block', (tester) async {
      await pumpDetail(tester, _order);

      expect(find.textContaining('35,000'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Plot 4, Ring Road, Rajkot'), findsOneWidget);
      expect(find.text('Transport agency'), findsOneWidget);
    });

    testWidgets('shows how each bag is packed', (tester) async {
      await pumpDetail(tester, _order);

      expect(find.text('40 x 2 kg'), findsOneWidget);
      expect(find.text('80 Kg'), findsOneWidget);
    });

    testWidgets('shows the agreed price and strikes the list price', (
      tester,
    ) async {
      await pumpDetail(tester, _order);

      // Line one was negotiated 2500 -> 2400, so both prices appear.
      expect(find.textContaining('2,400'), findsWidgets);
      expect(find.textContaining('2,500'), findsOneWidget);
      // 2400 x 2 bags.
      expect(find.textContaining('4,800'), findsOneWidget);
    });

    testWidgets('the metric counts items, matching the lines listed', (
      tester,
    ) async {
      // Four lines, two of them the same product: a distinct-product count
      // would say 3 here and contradict the four rows below it.
      await pumpDetail(
        tester,
        const Order(
          publicId: 'O-1',
          itemCount: 4,
          packagings: [
            OrderPackaging(
              publicId: 'PP-1',
              productPublicId: 'P-1',
              productName: 'SAI-30',
              quantity: 1,
            ),
            OrderPackaging(
              publicId: 'PP-2',
              productPublicId: 'P-2',
              productName: 'SAI-31',
              quantity: 1,
            ),
            OrderPackaging(
              publicId: 'PP-3',
              productPublicId: 'P-3',
              productName: 'SAI-32',
              quantity: 1,
            ),
            OrderPackaging(
              publicId: 'PP-4',
              productPublicId: 'P-3',
              productName: 'SAI-32',
              quantity: 1,
            ),
          ],
        ),
      );

      expect(find.text('4'), findsWidgets);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('shows who verified the order and when', (tester) async {
      await pumpDetail(
        tester,
        Order(
          publicId: 'O-1',
          isVerified: true,
          verifiedBy: 'Priya Admin',
          verifiedAt: DateTime.utc(2026, 9, 13, 18, 12),
        ),
      );

      expect(find.text('Priya Admin'), findsOneWidget);
      expect(find.textContaining('11:42 PM'), findsOneWidget);
    });

    testWidgets('says an unverified order is still awaiting approval', (
      tester,
    ) async {
      await pumpDetail(tester, _order);

      expect(find.text('Awaiting verification'), findsOneWidget);
    });

    testWidgets('an own-vehicle order says so', (tester) async {
      await pumpDetail(
        tester,
        const Order(publicId: 'O-1', dispatchMode: 'PRIVATE'),
      );

      expect(find.text('Own vehicle'), findsOneWidget);
    });
  });
}
