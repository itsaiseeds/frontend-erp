import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/clients/data/clients_repository.dart';
import 'package:frontend_erp/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:frontend_erp/features/clients/presentation/bloc/clients_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> requests = [];
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    requests.add(Map<String, dynamic>.from(options.queryParameters));

    return ResponseBody.fromString(
      '{"total_count":1,"total_pages":1,"next_page_number":null,'
      '"previous_page_number":null,"results":[{"public_id":"C-1",'
      '"company_name":"Acme Seeds","company_phone":"9876543210",'
      '"status":"VERIFIED"}],"available_filters":[],"available_sorts":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ClientsCubit _buildCubit(_RecordingAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;

  return ClientsCubit(
    repository: ClientsRepository(apiClient: ApiClient(dio: dio)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('submitting a search sends company_name and hits the API', () async {
    final adapter = _RecordingAdapter();
    final cubit = _buildCubit(adapter);

    await cubit.submitSearch('acme');

    expect(adapter.callCount, 1);
    expect(adapter.requests.single['company_name'], 'acme');
    expect(adapter.requests.single.containsKey('address'), isFalse);
    expect(cubit.state.status, ClientsStatus.loaded);
    expect(cubit.state.clients, hasLength(1));

    await cubit.close();
  });

  test('address scope sends address instead of company_name', () async {
    final adapter = _RecordingAdapter();
    final cubit = _buildCubit(adapter);

    await cubit.setSearchScope(ClientSearchScope.address);
    await cubit.submitSearch('surat');

    expect(adapter.requests.last['address'], 'surat');
    expect(adapter.requests.last.containsKey('company_name'), isFalse);

    await cubit.close();
  });

  test('an identical repeat search is served from cache', () async {
    final adapter = _RecordingAdapter();
    final cubit = _buildCubit(adapter);

    await cubit.submitSearch('acme');
    expect(adapter.callCount, 1);

    await cubit.submitSearch('acme');
    expect(adapter.callCount, 1);

    await cubit.close();
  });

  test('a different term bypasses the cache', () async {
    final adapter = _RecordingAdapter();
    final cubit = _buildCubit(adapter);

    await cubit.submitSearch('acme');
    await cubit.submitSearch('beta');

    expect(adapter.callCount, 2);
    expect(adapter.requests.last['company_name'], 'beta');

    await cubit.close();
  });

  test('clearing the search drops the param and refetches', () async {
    final adapter = _RecordingAdapter();
    final cubit = _buildCubit(adapter);

    await cubit.submitSearch('acme');
    await cubit.clearSearch();

    expect(adapter.callCount, 2);
    expect(adapter.requests.last.containsKey('company_name'), isFalse);
    expect(cubit.state.query.hasSearch, isFalse);

    await cubit.close();
  });

  test('page_size is the fixed default', () async {
    final adapter = _RecordingAdapter();
    final cubit = _buildCubit(adapter);

    await cubit.submitSearch('acme');

    expect(adapter.requests.single['page_size'], ClientsCubit.PAGE_SIZE);

    await cubit.close();
  });
}
