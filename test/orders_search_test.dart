import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/core/utils/date_formatter.dart';
import 'package:frontend_erp/features/orders/data/models/order.dart';
import 'package:frontend_erp/features/orders/data/models/orders_query.dart';
import 'package:frontend_erp/features/orders/data/orders_repository.dart';
import 'package:frontend_erp/features/orders/presentation/bloc/orders_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The catalogue the backend ships with every page: the eligible clients and
/// products, each as {value: public id, label: name}.
const String _filters =
    '[{"filter":"client","label":"Client","kind":"select","description":"",'
    '"params":[],"options":['
    '{"value":"C-1","label":"Dharati Agro"},'
    '{"value":"C-2","label":"Gurukrupa Seeds"}]},'
    '{"filter":"product","label":"Product","kind":"select","description":"",'
    '"params":[],"options":['
    '{"value":"P-1","label":"SAI-30"},'
    '{"value":"P-2","label":"SAI 32"}]}]';

class _SearchAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    return ResponseBody.fromString(
      '{"total_count":1,"total_pages":1,"next_page_number":null,'
      '"previous_page_number":null,"results":[{"public_id":"O-1",'
      '"created_at":"2026-09-13T17:27:18.171Z","status":"BOOKED",'
      '"client":{"public_id":"C-1","company_name":"Dharati Agro"},'
      '"delivery_address":"Rajkot","city":{"id":7,"name":"Rajkot"},'
      '"expected_delivery_date":"2026-09-20","dispatch_mode":"AGENCY",'
      '"total_amount":"2900.00","total_packets":65,"item_count":2,'
      '"products":[]}],'
      '"available_filters":$_filters,'
      '"available_sorts":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

OrdersCubit _cubitOf(_SearchAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;

  return OrdersCubit(
    repository: OrdersRepository(apiClient: ApiClient(dio: dio)),
  );
}

Map<String, dynamic> _lastParams(_SearchAdapter adapter) =>
    adapter.requests.last.queryParameters;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('searching orders', () {
    test('a company name is sent as a client id, not as free text', () async {
      final adapter = _SearchAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();
      await cubit.submitSearch('dharati');

      final Map<String, dynamic> params = _lastParams(adapter);
      expect(params['client'], 'C-1');
      // get-orders has no free-text param; sending one would be ignored.
      expect(params.containsKey('search'), isFalse);
      expect(params.containsKey('name'), isFalse);

      await cubit.close();
    });

    test('a product name is sent as a product id', () async {
      final adapter = _SearchAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();
      await cubit.submitSearch('SAI-30');

      expect(_lastParams(adapter)['product'], 'P-1');

      await cubit.close();
    });

    test('matching is case-insensitive and partial', () async {
      final adapter = _SearchAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();
      await cubit.submitSearch('GURU');

      expect(_lastParams(adapter)['client'], 'C-2');

      await cubit.close();
    });

    test('a term matching several products sends all their ids', () async {
      final adapter = _SearchAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();
      await cubit.submitSearch('sai');

      final String sent = '${_lastParams(adapter)['product']}';
      expect(sent.split(','), containsAll(<String>['P-1', 'P-2']));

      await cubit.close();
    });

    test(
      'a term matching nothing reports no match and skips the call',
      () async {
        final adapter = _SearchAdapter();
        final cubit = _cubitOf(adapter);

        await cubit.load();
        final int before = adapter.requests.length;

        await cubit.submitSearch('nothing matches this');

        expect(cubit.state.hasNoSearchMatch, isTrue);
        // Without the guard the server would return an unfiltered list, which
        // reads as "search did nothing".
        expect(adapter.requests, hasLength(before));

        await cubit.close();
      },
    );

    test('clearing the search drops the resolved ids', () async {
      final adapter = _SearchAdapter();
      final cubit = _cubitOf(adapter);

      await cubit.load();
      await cubit.submitSearch('dharati');
      expect(_lastParams(adapter)['client'], 'C-1');

      await cubit.clearSearch();

      expect(cubit.state.hasSearch, isFalse);
      // The unfiltered page is cached from the first load, so clearing serves
      // it without a refetch. What matters is that a later fetch is unfiltered.
      await cubit.refresh();
      expect(_lastParams(adapter).containsKey('client'), isFalse);

      await cubit.close();
    });

    test(
      'a search narrows an existing filter rather than widening it',
      () async {
        final adapter = _SearchAdapter();
        final cubit = _cubitOf(adapter);

        await cubit.load();
        await cubit.applyQuery(
          const OrdersQuery(
            selections: {
              'client': {'C-2'},
            },
          ),
        );

        // "dharati" is C-1, which the C-2 filter excludes: the intersection is
        // empty, so the user is not silently shown C-1 as well.
        await cubit.submitSearch('dharati');

        expect('${_lastParams(adapter)['client']}', isNot(contains('C-1')));

        await cubit.close();
      },
    );
  });

  group('IST timestamps', () {
    test('a UTC instant is shown in IST, not device time', () {
      final DateTime utc = DateTime.utc(2026, 9, 13, 17, 27, 18);

      expect(DateFormatter.dayTime(utc), contains('10:57 PM'));
      expect(DateFormatter.dayTime(utc), contains('13 Sep'));
      expect(DateFormatter.dayTime(utc), contains('IST'));
    });

    test('the offset is IST itself, not whatever the device is set to', () {
      // Asserting the rendered hour alone cannot tell the two apart when the
      // machine running the tests is already on IST.
      expect(DateFormatter.IST_OFFSET, const Duration(hours: 5, minutes: 30));

      final DateTime utc = DateTime.utc(2026, 9, 13, 17, 27, 18);
      final DateTime expected = utc.add(DateFormatter.IST_OFFSET);
      final String rendered = DateFormatter.dayTime(utc);

      expect(rendered, contains('${expected.day} Sep'));
      expect(rendered, contains('10:57 PM'));
      expect(utc.toLocal().hour, isNot(equals(utc.hour)));
    });

    test('a late-evening UTC stamp rolls into the next IST day', () {
      // 20:00 UTC on the 13th is 01:30 IST on the 14th.
      final DateTime utc = DateTime.utc(2026, 9, 13, 20, 0);

      expect(DateFormatter.dayTime(utc), contains('14 Sep'));
      expect(DateFormatter.dayTime(utc), contains('1:30 AM'));
    });

    test('a calendar date is printed as sent, with no zone shift', () {
      final Order order = Order.fromJson(const {
        'public_id': 'O-1',
        'expected_delivery_date': '2026-09-20',
      });

      // Shifting a date-only value would show the 19th or the 21st.
      expect(
        DateFormatter.calendarDay(order.expectedDeliveryDate),
        '20 Sep 2026',
      );
    });

    test('a missing timestamp renders a dash rather than throwing', () {
      expect(DateFormatter.dayTime(null), '--');
      expect(DateFormatter.calendarDay(null), '--');
    });
  });
}
