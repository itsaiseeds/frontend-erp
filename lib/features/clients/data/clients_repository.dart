import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/clients_endpoints.dart';
import '../../../core/network/endpoints/utilities_endpoints.dart';
import '../../../core/utils/json_parser.dart';
import 'models/client.dart';
import 'models/client_address.dart';
import 'models/clients_query.dart';
import 'models/paginated_clients.dart';
import 'models/sales_person_option.dart';
import 'models/transport_agency.dart';

class ClientsRepository {
  final ApiClient _apiClient;

  const ClientsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedClients> fetchClients({
    required int page,
    required int pageSize,
    required ClientsQuery query,
    required Map<String, List<String>> rangeParamsByKey,
    int? salesPersonId,
  }) async {
    final Map<String, dynamic> params = query.toQueryParameters(
      page: page,
      pageSize: pageSize,
      rangeParamsByKey: rangeParamsByKey,
    );
    if (salesPersonId != null) {
      params[ClientsEndpoints.SALES_PERSON_ID_PARAM] = salesPersonId;
    }

    final dynamic response = await _apiClient.get(
      ClientsEndpoints.list,
      queryParams: params,
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return PaginatedClients.fromJson(Map<String, dynamic>.from(response));
  }

  /// Admin-only: the sales persons an admin may book an order for (self
  /// included). A non-admin caller gets 403.
  Future<List<SalesPersonOption>> fetchSalesPersons() async {
    final dynamic response = await _apiClient.get(
      UtilitiesEndpoints.salesPersons,
    );
    return JsonParser.asList(response, SalesPersonOption.fromJson);
  }

  Future<Client> fetchClient(String publicId) async {
    final dynamic response = await _apiClient.get(
      ClientsEndpoints.detail(publicId),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return Client.fromJson(Map<String, dynamic>.from(response));
  }

  /// The client *list* carries only a primary address and no link ids, so the
  /// order pickers read the link rows from their own endpoints. Each returns a
  /// bare array whose ``id`` is what the order endpoint takes.
  ///
  /// [salesPersonId] is only honoured for an admin booking on behalf of that
  /// person -- the client has to belong to them, which is why step 3 of the
  /// admin-booking flow matters (see `sales_person_scope.client_of_caller`).
  Future<List<ClientAddress>> fetchAddresses(
    String clientPublicId, {
    int? salesPersonId,
  }) async {
    final dynamic response = await _apiClient.get(
      ClientsEndpoints.addresses,
      queryParams: {
        ClientsEndpoints.CLIENT_PUBLIC_ID_PARAM: clientPublicId,
        ClientsEndpoints.SALES_PERSON_ID_PARAM: ?salesPersonId,
      },
    );

    return JsonParser.asList(response, ClientAddress.fromJson);
  }

  Future<List<TransportAgency>> fetchTransportAgencies(
    String clientPublicId, {
    int? salesPersonId,
  }) async {
    final dynamic response = await _apiClient.get(
      ClientsEndpoints.transportAgencies,
      queryParams: {
        ClientsEndpoints.CLIENT_PUBLIC_ID_PARAM: clientPublicId,
        ClientsEndpoints.SALES_PERSON_ID_PARAM: ?salesPersonId,
      },
    );

    return JsonParser.asList(response, TransportAgency.fromJson);
  }

  Future<Client> createClient(Client client) async {
    final dynamic response = await _apiClient.post(
      ClientsEndpoints.create,
      body: client.toCreateJson(),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return Client.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Client> updateClient(Client client) async {
    final dynamic response = await _apiClient.post(
      ClientsEndpoints.update,
      body: client.toUpdateJson(),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return Client.fromJson(Map<String, dynamic>.from(response));
  }
}
