import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/return_orders/data/models/paginated_return_orders.dart';
import 'package:frontend_erp/features/return_orders/data/models/return_order.dart';
import 'package:frontend_erp/features/return_orders/data/models/return_order_draft_item.dart';
import 'package:frontend_erp/features/return_orders/data/models/return_order_prefill.dart';
import 'package:frontend_erp/features/return_orders/data/return_orders_repository.dart';
import 'package:frontend_erp/features/return_orders/presentation/bloc/return_order_form_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _listPage = '''
{
  "total_count": 1,
  "total_pages": 1,
  "next_page_number": null,
  "previous_page_number": null,
  "results": [
    {
      "public_id": "RET-ABC123",
      "status": "RETURN_PENDING",
      "return_date": "2026-09-20",
      "created_at": "2026-09-19T09:14:02.115Z",
      "order": {"public_id": "ORD-1", "status": "DISPATCHED"},
      "client": {"public_id": "C-1", "company_name": "Gurukrupa"},
      "created_by": {"id": 4, "name": "Ravi Sales"},
      "verified_by": null,
      "rejected_by": null,
      "items": [
        {
          "product": {"public_id": "P-1", "name": "SAI-30"},
          "packet_weight": "5.000",
          "packets": 3,
          "kg": "15.000",
          "price_per_packet": "120.50",
          "line_total": "361.50"
        }
      ],
      "total_kg": "15.000",
      "total_amount": "361.50"
    }
  ],
  "available_filters": [
    {
      "filter": "status",
      "label": "Status",
      "kind": "select",
      "description": "",
      "params": [],
      "options": [{"value": "RETURN_PENDING", "label": "Pending"}]
    }
  ],
  "available_sorts": [
    {"sort": "created_at", "label": "Created", "description": "Newest first."}
  ]
}
''';

/// SAI-30 went out in two packet sizes, SAI 32 in one -- the shape that makes
/// the picker list products only and put the weight on the card.
const String _prefill = '''
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
    },
    {
      "product": {"public_id": "P-2", "name": "SAI 32"},
      "packet_weight": "1.000",
      "dispatched_packets": 10,
      "returnable_packets": 8,
      "suggested_price_per_packet": "40.00"
    }
  ]
}
''';

/// Routes by path and method so one adapter can stand in for the prefill, the
/// create and the list.
class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  String prefillBody = _prefill;
  String listBody = _listPage;

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.method == 'POST') {
      final Map<String, dynamic> sent = Map<String, dynamic>.from(
        options.data as Map,
      );
      return _json({
        'public_id': 'RET-NEW',
        'status': 'RETURN_PENDING',
        'return_date': sent['return_date'],
        'created_at': '2026-09-19T10:00:00.000Z',
        'order': {'public_id': 'ORD-1', 'status': 'DISPATCHED'},
        'client': {'public_id': 'C-1', 'company_name': 'Gurukrupa'},
        'created_by': {'id': 4, 'name': 'Ravi Sales'},
        'verified_by': null,
        'rejected_by': null,
        'items': const [],
        'total_kg': '0.000',
        'total_amount': '0.00',
      }, 201);
    }

    if (options.path.endsWith('/get-return-orders')) {
      return ResponseBody.fromString(
        listBody,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      prefillBody,
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

ReturnOrdersRepository _repositoryOf(_Adapter adapter) =>
    ReturnOrdersRepository(apiClient: ApiClient(dio: _dioOf(adapter)));

ReturnOrderFormCubit _formCubitOf(_Adapter adapter) {
  return ReturnOrderFormCubit(
    repository: _repositoryOf(adapter),
    orderPublicId: 'ORD-1',
  );
}

ReturnOrderPrefill _prefillFrom(String json) => ReturnOrderPrefill.fromJson(
  Map<String, dynamic>.from(jsonDecode(json) as Map),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('return list payload', () {
    test('reads the card fields off a list row', () {
      final PaginatedReturnOrders page = PaginatedReturnOrders.fromJson(
        Map<String, dynamic>.from(jsonDecode(_listPage) as Map),
      );
      final ReturnOrder item = page.results.single;

      expect(item.publicId, 'RET-ABC123');
      expect(item.client.companyName, 'Gurukrupa');
      expect(item.order.publicId, 'ORD-1');
      expect(item.createdBy?.name, 'Ravi Sales');
      expect(item.items.single.product.name, 'SAI-30');
      expect(item.items.single.packets, 3);
    });

    test('decimal-string weights and amounts become numbers', () {
      final ReturnOrder item = PaginatedReturnOrders.fromJson(
        Map<String, dynamic>.from(jsonDecode(_listPage) as Map),
      ).results.single;

      expect(item.totalAmount, isA<num>());
      expect(item.totalAmount, 361.50);
      expect(item.totalKg, 15);
      expect(item.items.single.pricePerPacket, 120.50);
      expect(item.items.single.lineTotal, 361.50);
    });

    test('an unset actor stays null rather than an empty person', () {
      final ReturnOrder item = PaginatedReturnOrders.fromJson(
        Map<String, dynamic>.from(jsonDecode(_listPage) as Map),
      ).results.single;

      expect(item.verifiedBy, isNull);
      expect(item.rejectedBy, isNull);
      expect(item.includeInOtherRawMaterials, isNull);
    });

    test('the return date is a plain calendar day, not an instant', () {
      final ReturnOrder item = PaginatedReturnOrders.fromJson(
        Map<String, dynamic>.from(jsonDecode(_listPage) as Map),
      ).results.single;

      expect(item.returnDate!.year, 2026);
      expect(item.returnDate!.month, 9);
      expect(item.returnDate!.day, 20);
      expect(item.returnDate!.isUtc, isTrue);
    });

    test('the envelope carries filters and sorts for the sheet', () {
      final PaginatedReturnOrders page = PaginatedReturnOrders.fromJson(
        Map<String, dynamic>.from(jsonDecode(_listPage) as Map),
      );

      expect(page.totalCount, 1);
      expect(page.availableFilters.single.key, 'status');
      expect(page.availableSorts.single.key, 'created_at');
    });
  });

  group('return status', () {
    test('every backend code maps to its own case', () {
      expect(
        ReturnOrderStatusX.fromRaw('RETURN_PENDING'),
        ReturnOrderStatus.pending,
      );
      expect(
        ReturnOrderStatusX.fromRaw('RETURN_ACCEPTED'),
        ReturnOrderStatus.accepted,
      );
      expect(
        ReturnOrderStatusX.fromRaw('RETURN_REJECTED'),
        ReturnOrderStatus.rejected,
      );
    });

    test('an unknown or empty code falls back rather than throwing', () {
      expect(
        ReturnOrderStatusX.fromRaw('SOMETHING_NEW'),
        ReturnOrderStatus.unknown,
      );
      expect(ReturnOrderStatusX.fromRaw(''), ReturnOrderStatus.unknown);
    });

    test('pending and accepted are the live states a second return blocks', () {
      expect(ReturnOrderStatusX.isLive(ReturnOrderStatus.pending), isTrue);
      expect(ReturnOrderStatusX.isLive(ReturnOrderStatus.accepted), isTrue);
      expect(ReturnOrderStatusX.isLive(ReturnOrderStatus.rejected), isFalse);
    });

    test('every status has a human label', () {
      for (final ReturnOrderStatus status in ReturnOrderStatus.values) {
        expect(ReturnOrderStatusX.labelOf(status), isNotEmpty);
      }
    });
  });

  group('return search', () {
    final ReturnOrder row = ReturnOrder.fromJson(const {
      'public_id': 'RET-ABC123',
      'order': {'public_id': 'ORD-99', 'status': 'DISPATCHED'},
      'client': {'public_id': 'C-1', 'company_name': 'Gurukrupa Seeds'},
      'items': [
        {
          'product': {'public_id': 'P-1', 'name': 'SAI-30'},
          'packets': 2,
        },
      ],
    });

    test('matches the return id, the order id, the client and the product', () {
      expect(row.matches('ret-abc'), isTrue);
      expect(row.matches('ORD-99'), isTrue);
      expect(row.matches('gurukrupa'), isTrue);
      expect(row.matches('sai-30'), isTrue);
    });

    test('a term that matches nothing reports no match', () {
      expect(row.matches('wheat'), isFalse);
    });
  });

  group('return prefill', () {
    test('groups the challan lines into products, lightest weight first', () {
      final ReturnOrderPrefill prefill = _prefillFrom(_prefill);

      // Three lines but two products: the picker lists products only.
      expect(prefill.lines, hasLength(3));
      expect(prefill.products, hasLength(2));
      expect(prefill.products.first.name, 'SAI 32');
      expect(prefill.products.last.name, 'SAI-30');
      expect(prefill.products.last.sortedLines.first.weightKey, '5');
      expect(prefill.products.last.sortedLines.last.weightKey, '10');
    });

    test('each line keeps what is dispatched and what is still returnable', () {
      final ReturnOrderPrefill prefill = _prefillFrom(_prefill);
      final ReturnOrderProduct sai30 = prefill.products.last;

      expect(sai30.lineForWeight(10)!.dispatchedPackets, 6);
      expect(sai30.lineForWeight(10)!.returnablePackets, 6);
      expect(sai30.lineForWeight(5)!.suggestedPricePerPacket, 120.50);
      expect(sai30.totalReturnablePackets, 10);
    });

    test('a dispatched order with no live return can take one', () {
      final ReturnOrderPrefill prefill = _prefillFrom(_prefill);

      expect(prefill.isReturnableOrder, isTrue);
      expect(prefill.hasLiveReturn, isFalse);
      expect(prefill.canCreate, isTrue);
    });

    test('an order that has not shipped cannot take a return', () {
      final ReturnOrderPrefill prefill = _prefillFrom(
        jsonEncode({
          'order': {'public_id': 'ORD-1', 'status': 'CONFIRMED'},
          'return_order': null,
          'lines': const [],
        }),
      );

      expect(prefill.isReturnableOrder, isFalse);
      expect(prefill.canCreate, isFalse);
    });

    test('an order with a live return already cannot take a second one', () {
      final ReturnOrderPrefill prefill = _prefillFrom(
        jsonEncode({
          'order': {'public_id': 'ORD-1', 'status': 'DELIVERED'},
          'return_order': {'public_id': 'RET-1', 'status': 'RETURN_PENDING'},
          'lines': const [],
        }),
      );

      expect(prefill.hasLiveReturn, isTrue);
      expect(prefill.canCreate, isFalse);
    });
  });

  group('building a return', () {
    test('picking a product opens a card on its lightest weight', () async {
      final adapter = _Adapter();
      final cubit = _formCubitOf(adapter);

      await cubit.load();
      final ReturnOrderProduct sai30 = cubit.state.prefill!.products.firstWhere(
        (product) => product.publicId == 'P-1',
      );

      expect(cubit.addProduct(sai30), isNull);

      final ReturnOrderDraftItem item = cubit.state.items.single;
      expect(item.packetWeight, 5);
      expect(item.packets, 1);
      expect(item.pricePerPacket, 120.50);
      expect(item.maxPackets, 4);

      await cubit.close();
    });

    test(
      'the count is capped at what that weight still has returnable',
      () async {
        final adapter = _Adapter();
        final cubit = _formCubitOf(adapter);

        await cubit.load();
        final ReturnOrderProduct sai30 = cubit.state.prefill!.products
            .firstWhere((product) => product.publicId == 'P-1');
        cubit.addProduct(sai30);

        cubit.setPackets(0, 99);
        expect(cubit.state.items.single.packets, 4);

        cubit.setPackets(0, 0);
        expect(cubit.state.items.single.packets, 1);

        await cubit.close();
      },
    );

    test(
      'switching weight re-reads that weight\'s cap and suggested price',
      () async {
        final adapter = _Adapter();
        final cubit = _formCubitOf(adapter);

        await cubit.load();
        final ReturnOrderProduct sai30 = cubit.state.prefill!.products
            .firstWhere((product) => product.publicId == 'P-1');
        cubit.addProduct(sai30);
        cubit.setPackets(0, 3);

        expect(cubit.setWeight(0, 10), isNull);

        final ReturnOrderDraftItem item = cubit.state.items.single;
        expect(item.packetWeight, 10);
        expect(item.maxPackets, 6);
        expect(item.pricePerPacket, 200);
        // The old count belonged to the 5 kg line and is out of range on the 10 kg
        // one only by coincidence here; it is reset either way so the field and
        // the state cannot disagree.
        expect(item.packets, 1);

        await cubit.close();
      },
    );

    test('the same weight twice on one product is refused', () async {
      final adapter = _Adapter();
      final cubit = _formCubitOf(adapter);

      await cubit.load();
      final ReturnOrderProduct sai30 = cubit.state.prefill!.products.firstWhere(
        (product) => product.publicId == 'P-1',
      );

      cubit.addProduct(sai30);
      expect(cubit.addAnotherWeight(0), isNull);

      // The 5 kg card is already on the return, so switching to it is refused.
      expect(cubit.setWeight(1, 5), isNotNull);
      expect(cubit.state.items, hasLength(2));
      expect(cubit.state.items.map((item) => item.weightKey), ['5', '10']);

      await cubit.close();
    });

    test(
      'a product leaves the picker once every weight is on the return',
      () async {
        final adapter = _Adapter();
        final cubit = _formCubitOf(adapter);

        await cubit.load();
        final ReturnOrderProduct sai30 = cubit.state.prefill!.products
            .firstWhere((product) => product.publicId == 'P-1');

        expect(cubit.availableProducts, hasLength(2));

        cubit.addProduct(sai30);
        expect(cubit.availableProducts, hasLength(2));

        cubit.addAnotherWeight(0);
        expect(cubit.availableProducts, hasLength(1));
        expect(cubit.addAnotherWeight(0), isNotNull);

        await cubit.close();
      },
    );

    test('a product with nothing returnable left is not offered', () async {
      final adapter = _Adapter();
      adapter.prefillBody = jsonEncode({
        'order': {'public_id': 'ORD-1', 'status': 'DISPATCHED'},
        'return_order': null,
        'lines': [
          {
            'product': {'public_id': 'P-1', 'name': 'SAI-30'},
            'packet_weight': '5.000',
            'dispatched_packets': 4,
            'returnable_packets': 4,
            'suggested_price_per_packet': '120.50',
          },
          {
            'product': {'public_id': 'P-2', 'name': 'SAI 32'},
            'packet_weight': '1.000',
            'dispatched_packets': 10,
            'returnable_packets': 0,
            'suggested_price_per_packet': '40.00',
          },
        ],
      });
      final cubit = _formCubitOf(adapter);

      await cubit.load();

      expect(cubit.availableProducts.map((p) => p.publicId), ['P-1']);

      await cubit.close();
    });

    test('a negative price is ignored rather than sent', () async {
      final adapter = _Adapter();
      final cubit = _formCubitOf(adapter);

      await cubit.load();
      final ReturnOrderProduct sai30 = cubit.state.prefill!.products.firstWhere(
        (product) => product.publicId == 'P-1',
      );
      cubit.addProduct(sai30);
      cubit.setPrice(0, -5);

      expect(cubit.state.items.single.pricePerPacket, 120.50);

      await cubit.close();
    });

    test('removing a card puts its weight back in the picker', () async {
      final adapter = _Adapter();
      final cubit = _formCubitOf(adapter);

      await cubit.load();
      final ReturnOrderProduct sai30 = cubit.state.prefill!.products.firstWhere(
        (product) => product.publicId == 'P-1',
      );
      cubit.addProduct(sai30);

      expect(cubit.state.items, hasLength(1));
      cubit.removeItem(0);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.canSubmit, isFalse);

      await cubit.close();
    });

    test('submitting sends the date and one row per card', () async {
      final adapter = _Adapter();
      final cubit = _formCubitOf(adapter);

      await cubit.load();
      final ReturnOrderProduct sai30 = cubit.state.prefill!.products.firstWhere(
        (product) => product.publicId == 'P-1',
      );
      cubit.addProduct(sai30);
      cubit.setPackets(0, 3);
      cubit.setPrice(0, 125);
      cubit.addAnotherWeight(0);

      final bool created = await cubit.submit();

      expect(created, isTrue);
      expect(cubit.state.created?.publicId, 'RET-NEW');

      final RequestOptions post = adapter.requests.last;
      expect(post.method, 'POST');
      expect(post.path, endsWith('/return-order/ORD-1'));

      final Map<String, dynamic> body = Map<String, dynamic>.from(
        post.data as Map,
      );
      expect(body['return_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

      final List<dynamic> items = body['items'] as List<dynamic>;
      expect(items, hasLength(2));

      final Map<String, dynamic> first = Map<String, dynamic>.from(
        items.first as Map,
      );
      expect(first['product_public_id'], 'P-1');
      expect(first['packet_weight'], '5');
      expect(first['packets'], 3);
      expect(first['price_per_packet'], '125.00');

      final Map<String, dynamic> second = Map<String, dynamic>.from(
        items.last as Map,
      );
      expect(second['packet_weight'], '10');
      expect(second['packets'], 1);

      await cubit.close();
    });

    test('an empty return is not submitted at all', () async {
      final adapter = _Adapter();
      final cubit = _formCubitOf(adapter);

      await cubit.load();
      final int before = adapter.requests.length;

      final bool created = await cubit.submit();

      expect(created, isFalse);
      expect(adapter.requests, hasLength(before));

      await cubit.close();
    });

    test(
      'a rejected return keeps the draft on screen with the reason',
      () async {
        // The API answering a write with a 400 is the case worth covering: the
        // message has to reach the user and the lines must survive.
        final cubit = ReturnOrderFormCubit(
          repository: ReturnOrdersRepository(
            apiClient: ApiClient(dio: _dioOf(_RejectingAdapter())),
          ),
          orderPublicId: 'ORD-1',
        );

        await cubit.load();
        cubit.addProduct(cubit.state.prefill!.products.first);

        final bool created = await cubit.submit();

        expect(created, isFalse);
        expect(cubit.state.errorMessage, 'Packets exceed the challan.');
        // The draft survives so the quantity can be fixed, not retyped.
        expect(cubit.state.items, hasLength(1));
        expect(cubit.state.canSubmit, isTrue);

        await cubit.close();
      },
    );
  });
}

/// Answers the prefill normally but refuses the create with a 400, the way the
/// API answers a return that breaks the challan limits.
class _RejectingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST') {
      return ResponseBody.fromString(
        '{"detail":"Packets exceed the challan."}',
        400,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      _prefill,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
