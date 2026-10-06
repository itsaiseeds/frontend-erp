import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/constants/app_strings.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/orders/presentation/order_detail_screen.dart';
import 'package:frontend_erp/features/return_orders/data/models/return_order.dart';
import 'package:frontend_erp/features/return_orders/presentation/return_orders_screen.dart';
import 'package:frontend_erp/features/return_orders/presentation/widgets/return_order_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _returnJson(
  String id, {
  String status = 'RETURN_PENDING',
  String client = 'Gurukrupa',
  String order = 'ORD-1',
  String product = 'SAI-30',
  String packets = '3',
}) =>
    '{"public_id":"$id","status":"$status","return_date":"2026-09-20",'
    '"created_at":"2026-09-19T09:14:02.115Z",'
    '"order":{"public_id":"$order","status":"DISPATCHED"},'
    '"client":{"public_id":"C-1","company_name":"$client"},'
    '"created_by":{"id":4,"name":"Ravi Sales"},"verified_by":null,'
    '"rejected_by":null,"items":[{"product":{"public_id":"P-1",'
    '"name":"$product"},"packet_weight":"5.000","packets":$packets,'
    '"kg":"15.000","price_per_packet":"120.50","line_total":"361.50"}],'
    '"total_kg":"15.000","total_amount":"361.50"}';

class _ReturnAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<String>? rows;
  final int pageCount;
  final int rowsPerPage;

  _ReturnAdapter({this.rows, this.pageCount = 1, this.rowsPerPage = 1});

  /// The order a return points at. fetchOrderByPublicId reads a page envelope,
  /// not a bare object, so this has to be wrapped before it is served.
  static const String _orderRow =
      '{"public_id":"ORD-1","created_at":'
      '"2026-09-13T17:25:49.434Z","status":"DISPATCHED","client":'
      '{"public_id":"C-1","company_name":"Gurukrupa"},"delivery_address":'
      '"Ring Road, Rajkot","city":{"id":7,"name":"Rajkot"},"dispatch_mode":'
      '"AGENCY","total_amount":"35000.00","total_packets":120,'
      '"item_count":1,"verified":false,"verified_by":null,'
      '"verified_at":null,"packagings":[{"public_id":"PP-1",'
      '"negotiated_selling_price":"2400.00","product":{"public_id":"P-1",'
      '"name":"SAI-30","image_url":""},"packet_weight":"5.00","packets":10,'
      '"total_weight":"50.00","selling_price":"2400.00","quantity":1}]}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.contains('get-orders')) {
      return ResponseBody.fromString(
        '{"total_count":1,"total_pages":1,"next_page_number":null,'
        '"previous_page_number":null,"results":[$_orderRow],'
        '"available_filters":[],"available_sorts":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final int page = int.tryParse('${options.queryParameters['page']}') ?? 1;
    final int? next = page < pageCount ? page + 1 : null;
    final List<String>? given = rows;
    final String results = given == null
        ? List.generate(
            rowsPerPage,
            (int i) => _returnJson('RET-PAGE$page-$i'),
          ).join(',')
        : given.join(',');

    return ResponseBody.fromString(
      '{"total_count":${given?.length ?? pageCount * rowsPerPage},'
      '"total_pages":$pageCount,'
      '"next_page_number":${next ?? 'null'},"previous_page_number":null,'
      '"results":[$results],'
      '"available_filters":[{"filter":"status","label":"Status",'
      '"kind":"select","description":"","params":[],'
      '"options":[{"value":"RETURN_PENDING","label":"Pending"}]}],'
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

Dio _dioOf(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

ApiClient _clientOf(_ReturnAdapter adapter) => ApiClient(dio: _dioOf(adapter));

Future<void> _pumpScreen(WidgetTester tester, _ReturnAdapter adapter) async {
  tester.view.physicalSize = const Size(738, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final ApiClient client = _clientOf(adapter);

  await tester.pumpWidget(
    MaterialApp(
      home: Provider<ApiClient>.value(
        value: client,
        child: const ReturnOrdersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String term) async {
  await tester.enterText(find.byType(TextField).first, term);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('return list', () {
    testWidgets('a page renders a card per return', (tester) async {
      await _pumpScreen(tester, _ReturnAdapter());

      expect(find.byType(ReturnOrderCard), findsOneWidget);
      expect(find.text('Gurukrupa'), findsOneWidget);
      expect(find.textContaining('RET-PAGE1'), findsWidgets);
    });

    testWidgets('the status of each row is spelled out', (tester) async {
      await _pumpScreen(
        tester,
        _ReturnAdapter(
          rows: [
            _returnJson('RET-1', status: 'RETURN_ACCEPTED'),
            _returnJson('RET-2', status: 'RETURN_REJECTED'),
          ],
        ),
      );

      expect(
        find.text(ReturnOrderStatusX.labelOf(ReturnOrderStatus.accepted)),
        findsOneWidget,
      );
      expect(
        find.text(ReturnOrderStatusX.labelOf(ReturnOrderStatus.rejected)),
        findsOneWidget,
      );
    });

    testWidgets('an empty list says so instead of showing a blank page', (
      tester,
    ) async {
      await _pumpScreen(tester, _ReturnAdapter(rows: []));

      expect(find.text(AppStrings.RETURN_ORDERS_EMPTY_TITLE), findsOneWidget);
      expect(find.byType(ReturnOrderCard), findsNothing);
    });

    testWidgets('searching narrows the loaded rows without refetching', (
      tester,
    ) async {
      final adapter = _ReturnAdapter(
        rows: [
          _returnJson('RET-1', client: 'Gurukrupa', product: 'SAI-30'),
          _returnJson('RET-2', client: 'Dharati Agro', product: 'SAI 32'),
        ],
      );
      await _pumpScreen(tester, adapter);
      final int before = adapter.requests.length;

      await _search(tester, 'dharati');

      expect(find.byType(ReturnOrderCard), findsOneWidget);
      expect(find.text('Dharati Agro'), findsOneWidget);
      // get-return-orders has no free-text param, so the filter is ours to run.
      expect(adapter.requests, hasLength(before));
    });

    testWidgets('a term matching nothing reports no match', (tester) async {
      await _pumpScreen(
        tester,
        _ReturnAdapter(rows: [_returnJson('RET-1', client: 'Gurukrupa')]),
      );

      await _search(tester, 'zzz-nothing');

      expect(find.byType(ReturnOrderCard), findsNothing);
      expect(
        find.text(AppStrings.RETURN_ORDERS_NO_MATCH_TITLE),
        findsOneWidget,
      );
    });

    testWidgets('the return id and the order id are both searchable', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _ReturnAdapter(
          rows: [
            _returnJson('RET-AAA', order: 'ORD-111'),
            _returnJson('RET-BBB', order: 'ORD-222'),
          ],
        ),
      );

      await _search(tester, 'ORD-222');

      expect(find.byType(ReturnOrderCard), findsOneWidget);
      expect(find.textContaining('RET-BBB'), findsWidgets);
    });

    testWidgets('the next page is fetched when the list runs out of rows', (
      tester,
    ) async {
      // Rows have to overflow the viewport before the scroll listener fires;
      // paging is scroll-driven, exactly as it is on the orders list.
      final adapter = _ReturnAdapter(pageCount: 3, rowsPerPage: 30);
      await _pumpScreen(tester, adapter);
      expect(find.byType(ReturnOrderCard), findsWidgets);

      // Paging fires only once the remaining scroll distance drops under the
      // threshold, so keep scrolling until it does.
      for (int i = 0; i < 10 && adapter.requests.length < 2; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();
      }

      expect(adapter.requests.length, greaterThan(1));
      expect(
        adapter.requests.map((r) => '${r.queryParameters['page']}'),
        containsAll(<String>['1', '2']),
      );
      expect(find.byType(ReturnOrderCard), findsWidgets);
    });

    testWidgets('tapping a card opens the order it belongs to', (tester) async {
      await _pumpScreen(tester, _ReturnAdapter());

      await tester.tap(find.byType(ReturnOrderCard));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
    });
  });
}
