import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/constants/app_strings.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/core/widgets/inputs/geo_picker_field.dart';
import 'package:frontend_erp/features/return_orders/data/models/return_order_prefill.dart';
import 'package:frontend_erp/features/return_orders/presentation/create_return_order_screen.dart';
import 'package:frontend_erp/features/return_orders/presentation/widgets/return_item_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _dispatched = '''
{
  "order": {
    "public_id": "ORD-1",
    "status": "DISPATCHED",
    "client": {"public_id": "C-1", "company_name": "Gurukrupa"}
  },
  "return_order": null,
  "lines": [
    {
      "product": {"public_id": "P-1", "name": "SAI-30"},
      "packet_weight": "10.000",
      "dispatched_packets": 6,
      "returnable_packets": 6,
      "suggested_price_per_packet": "200.00"
    },
    {
      "product": {"public_id": "P-1", "name": "SAI-30"},
      "packet_weight": "5.000",
      "dispatched_packets": 4,
      "returnable_packets": 4,
      "suggested_price_per_packet": "120.50"
    }
  ]
}
''';

/// A booked order still carrying challan lines -- blocked for its status, not
/// for anything missing.
const String _confirmed = '''
{
  "order": {
    "public_id": "ORD-1",
    "status": "CONFIRMED",
    "client": {"public_id": "C-1", "company_name": "Gurukrupa"}
  },
  "return_order": null,
  "lines": [
    {
      "product": {"public_id": "P-1", "name": "SAI-30"},
      "packet_weight": "5.000",
      "dispatched_packets": 4,
      "returnable_packets": 4,
      "suggested_price_per_packet": "120.50"
    }
  ]
}
''';

const String _alreadyReturned = '''
{
  "order": {
    "public_id": "ORD-1",
    "status": "DELIVERED",
    "client": {"public_id": "C-1", "company_name": "Gurukrupa"}
  },
  "return_order": {"public_id": "RET-OLD", "status": "RETURN_PENDING"},
  "lines": [
    {
      "product": {"public_id": "P-1", "name": "SAI-30"},
      "packet_weight": "5.000",
      "dispatched_packets": 4,
      "returnable_packets": 4,
      "suggested_price_per_packet": "120.50"
    }
  ]
}
''';

/// An order with nothing on the challan to hand back.
const String _noLines = '''
{
  "order": {
    "public_id": "ORD-1",
    "status": "DISPATCHED",
    "client": {"public_id": "C-1", "company_name": "Gurukrupa"}
  },
  "return_order": null,
  "lines": []
}
''';

class _FormAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  String prefill = _dispatched;
  bool refusesCreate = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.method == 'POST') {
      if (refusesCreate) {
        return ResponseBody.fromString(
          '{"detail":"Packets exceed the challan."}',
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      return ResponseBody.fromString(
        '{"public_id":"RET-NEW","status":"RETURN_PENDING",'
        '"return_date":"2026-09-20","created_at":"2026-09-19T10:00:00.000Z",'
        '"order":{"public_id":"ORD-1","status":"DISPATCHED"},'
        '"client":{"public_id":"C-1","company_name":"Gurukrupa"},'
        '"created_by":null,"verified_by":null,"rejected_by":null,'
        '"items":[],"total_kg":"0.000","total_amount":"0.00"}',
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      prefill,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _pumpForm(WidgetTester tester, _FormAdapter adapter) async {
  tester.view.physicalSize = const Size(738, 1900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;

  await tester.pumpWidget(
    MaterialApp(
      home: Provider<ApiClient>.value(
        value: ApiClient(dio: dio),
        child: const CreateReturnOrderScreen(orderPublicId: 'ORD-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Picks SAI-30 out of the product picker and lands on its card.
Future<void> _pickSai30(WidgetTester tester) async {
  await tester.tap(find.byType(GeoPickerField<ReturnOrderProduct>));
  await tester.pumpAndSettle();

  await tester.tap(find.text('SAI-30').last);
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

  group('raising a return', () {
    testWidgets('an order still at the warehouse is explained, not blocked', (
      tester,
    ) async {
      final adapter = _FormAdapter()..prefill = _confirmed;

      await _pumpForm(tester, adapter);

      expect(
        find.text(AppStrings.RETURN_ORDER_BLOCK_NOT_RETURNABLE_TITLE),
        findsOneWidget,
      );
      // Nothing to add, so the picker is not offered.
      expect(find.text(AppStrings.RETURN_ORDER_ADD_PRODUCT), findsNothing);
    });

    testWidgets('a live return already on the order is named', (tester) async {
      final adapter = _FormAdapter()..prefill = _alreadyReturned;

      await _pumpForm(tester, adapter);

      expect(
        find.text(AppStrings.RETURN_ORDER_BLOCK_LIVE_RETURN_TITLE),
        findsOneWidget,
      );
      expect(
        find.textContaining('RET-OLD'),
        findsWidgets,
        reason: 'the user needs the id of the return that is in the way',
      );
    });

    testWidgets('an order with nothing on the challan says so', (tester) async {
      final adapter = _FormAdapter()..prefill = _noLines;

      await _pumpForm(tester, adapter);

      expect(
        find.text(AppStrings.RETURN_ORDER_BLOCK_NO_LINES_TITLE),
        findsOneWidget,
      );
    });

    testWidgets('the screen opens on an empty draft', (tester) async {
      await _pumpForm(tester, _FormAdapter());

      expect(
        find.text(AppStrings.RETURN_ORDER_DRAFT_EMPTY_TITLE),
        findsOneWidget,
      );
      expect(find.byType(ReturnItemCard), findsNothing);
      expect(find.text(AppStrings.RETURN_ORDER_SUBMIT), findsOneWidget);
    });

    testWidgets('picking a product opens one card per weight option', (
      tester,
    ) async {
      await _pumpForm(tester, _FormAdapter());

      await _pickSai30(tester);

      expect(find.byType(ReturnItemCard), findsOneWidget);
      // Both packet sizes are on offer; the lighter one is chosen to begin with,
      // so it is the one echoed back on the card itself.
      expect(find.text('10 kg'), findsWidgets);
      expect(find.text('5 kg'), findsWidgets);
      // 4 returnable on the 5 kg line, suggested at 120.50.
      expect(find.textContaining('120.50'), findsWidgets);
    });

    testWidgets('tapping the other weight re-reads its cap and price', (
      tester,
    ) async {
      await _pumpForm(tester, _FormAdapter());
      await _pickSai30(tester);

      await tester.tap(find.text('10 kg'));
      await tester.pumpAndSettle();

      expect(find.textContaining('200.00'), findsWidgets);
    });

    testWidgets('add another size puts the second weight on its own card', (
      tester,
    ) async {
      await _pumpForm(tester, _FormAdapter());
      await _pickSai30(tester);

      await tester.tap(find.text(AppStrings.RETURN_ORDER_ADD_MORE_WEIGHT));
      await tester.pumpAndSettle();

      expect(find.byType(ReturnItemCard), findsNWidgets(2));
    });

    testWidgets('removing a card takes the line back off the return', (
      tester,
    ) async {
      await _pumpForm(tester, _FormAdapter());
      await _pickSai30(tester);

      await tester.tap(find.byTooltip(AppStrings.CLIENT_REMOVE).first);
      await tester.pumpAndSettle();

      expect(find.byType(ReturnItemCard), findsNothing);
      expect(
        find.text(AppStrings.RETURN_ORDER_DRAFT_EMPTY_TITLE),
        findsOneWidget,
      );
    });

    testWidgets('the summary counts the packets across every card', (
      tester,
    ) async {
      final adapter = _FormAdapter();
      await _pumpForm(tester, adapter);
      await _pickSai30(tester);

      await tester.tap(find.text(AppStrings.RETURN_ORDER_ADD_MORE_WEIGHT));
      await tester.pumpAndSettle();

      // One packet on each of the two weights.
      expect(find.text(AppStrings.RETURN_ORDER_TOTAL_PACKETS), findsOneWidget);

      await tester.tap(find.text(AppStrings.RETURN_ORDER_SUBMIT));
      await tester.pumpAndSettle();

      final RequestOptions post = adapter.requests.last;
      expect(post.method, 'POST');
      final Map<String, dynamic> body = Map<String, dynamic>.from(
        post.data as Map,
      );
      expect(body['items'], hasLength(2));
    });

    testWidgets('a refused write leaves the draft alone', (tester) async {
      final adapter = _FormAdapter()..refusesCreate = true;
      await _pumpForm(tester, adapter);
      await _pickSai30(tester);

      await tester.tap(find.text(AppStrings.RETURN_ORDER_SUBMIT));
      await tester.pumpAndSettle();

      // Still on the screen with the lines intact, so the count can be fixed.
      expect(find.byType(ReturnItemCard), findsOneWidget);
      expect(find.byType(CreateReturnOrderScreen), findsOneWidget);
    });
  });
}
