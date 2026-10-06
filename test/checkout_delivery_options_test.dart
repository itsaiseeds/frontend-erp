import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/features/clients/data/clients_repository.dart';
import 'package:frontend_erp/features/clients/data/models/client.dart';
import 'package:frontend_erp/features/products/data/models/cart_line.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/data/products_repository.dart';
import 'package:frontend_erp/features/products/presentation/bloc/checkout_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _listBody =
    '{"total_count":1,"total_pages":1,"next_page_number":null,'
    '"previous_page_number":null,"results":[{"public_id":"C-1",'
    '"company_name":"Gurukrupa","status":"VERIFIED",'
    '"primary_address":{"line_1":"Line 1","city":"Rajkot"}}],'
    '"available_filters":[],"available_sorts":[]}';

const String _addressesBody =
    '[{"id":7,"label":"Warehouse","is_primary":false,"line_1":"Plot 4",'
    '"line_2":"","pincode":"360001","city":"Rajkot","state":"Gujarat",'
    '"country":"India","city_id":1,"state_id":2,"country_id":3},'
    '{"id":9,"label":"Head office","is_primary":true,"line_1":"Ring Road",'
    '"line_2":"","pincode":"360002","city":"Rajkot","state":"Gujarat",'
    '"country":"India","city_id":1,"state_id":2,"country_id":3}]';

const String _agenciesBody =
    '[{"id":3,"name":"Speedy Roadways","is_primary":true}]';

class _PickerAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  String addressesBody;
  String agenciesBody;

  _PickerAdapter({
    this.addressesBody = _addressesBody,
    this.agenciesBody = _agenciesBody,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final String path = options.path;
    final String body;
    if (path.contains('client-addresses')) {
      body = addressesBody;
    } else if (path.contains('client-transport-agencies')) {
      body = agenciesBody;
    } else if (options.method == 'POST') {
      body = '{"public_id":"O-1"}';
    } else {
      body = _listBody;
    }

    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

CheckoutCubit _buildCubit(_PickerAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;
  final ApiClient apiClient = ApiClient(dio: dio);

  return CheckoutCubit(
    clientsRepository: ClientsRepository(apiClient: apiClient),
    productsRepository: ProductsRepository(apiClient: apiClient),
  );
}

Client _clientOf(CheckoutCubit cubit) => cubit.state.clients.single;

const List<CartLine> _lines = [
  CartLine(packaging: ProductPackaging(publicId: 'PP-1', sellingPrice: 100)),
];

Map<String, dynamic> _orderBody(_PickerAdapter adapter) {
  final RequestOptions request = adapter.requests.lastWhere(
    (options) => options.method == 'POST',
  );
  return Map<String, dynamic>.from(request.data as Map);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('private dispatch', () {
    test('is offered first and selected by default', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));

      expect(cubit.state.agencies.first.isPrivateDispatch, isTrue);
      expect(cubit.state.agencies.first.name, 'Private dispatch');
      expect(cubit.state.agency!.isPrivateDispatch, isTrue);

      await cubit.close();
    });

    test('is offered even when the client has no saved agency', () async {
      final adapter = _PickerAdapter(agenciesBody: '[]');
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));

      expect(cubit.state.agencies, hasLength(1));
      expect(cubit.state.agencies.single.isPrivateDispatch, isTrue);

      await cubit.close();
    });

    test('sends no agency id at all, not a zero', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));
      await cubit.placeOrder(_lines);

      final Map<String, dynamic> body = _orderBody(adapter);
      // A zero would be rejected as an unknown link id.
      expect(body.containsKey('client_transport_agency_id'), isFalse);

      await cubit.close();
    });

    test('a real agency still sends its link id', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));
      cubit.selectAgency(cubit.state.agencies.last);
      await cubit.placeOrder(_lines);

      expect(_orderBody(adapter)['client_transport_agency_id'], 3);

      await cubit.close();
    });

    test('switching back to private drops the id again', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));
      cubit.selectAgency(cubit.state.agencies.last);
      cubit.selectAgency(cubit.state.agencies.first);
      await cubit.placeOrder(_lines);

      expect(
        _orderBody(adapter).containsKey('client_transport_agency_id'),
        isFalse,
      );

      await cubit.close();
    });
  });

  group('delivery options come from the link pickers', () {
    test('the client list alone leaves both pickers empty', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();

      // The list payload carries no link arrays -- this is the bug the
      // picker fetch exists to fix.
      expect(_clientOf(cubit).addresses, isEmpty);
      expect(_clientOf(cubit).transportAgencies, isEmpty);
      expect(cubit.state.addresses, isEmpty);

      await cubit.close();
    });

    test('selecting a client loads its addresses and agencies', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));

      expect(cubit.state.addresses, hasLength(2));
      // Private dispatch plus the client's one saved agency.
      expect(cubit.state.agencies, hasLength(2));
      expect(cubit.state.agencies.last.id, 3);
      expect(cubit.state.isLoadingLinks, isFalse);

      await cubit.close();
    });

    test('both pickers are queried for the chosen client', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));

      final List<RequestOptions> links = adapter.requests
          .where((request) => request.path.contains('utilities/'))
          .toList();

      expect(links, hasLength(2));
      for (final RequestOptions request in links) {
        expect(request.queryParameters['client_public_id'], 'C-1');
      }

      await cubit.close();
    });

    test('the primary address is preselected with its link id', () async {
      final adapter = _PickerAdapter();
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));

      expect(cubit.state.address!.id, 9);
      expect(cubit.state.canSubmit, isTrue);

      await cubit.close();
    });

    test('a client with no saved address cannot be ordered against', () async {
      final adapter = _PickerAdapter(addressesBody: '[]');
      final cubit = _buildCubit(adapter);

      await cubit.loadClients();
      await cubit.selectClient(_clientOf(cubit));

      expect(cubit.state.addresses, isEmpty);
      expect(cubit.state.address, isNull);
      expect(cubit.state.isDeliveryResolved, isFalse);

      await cubit.close();
    });
  });
}
