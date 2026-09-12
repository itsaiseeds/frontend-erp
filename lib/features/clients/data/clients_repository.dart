import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/clients_endpoints.dart';
import 'models/client.dart';
import 'models/clients_query.dart';
import 'models/paginated_clients.dart';

class ClientsRepository {
  final ApiClient _apiClient;

  const ClientsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedClients> fetchClients({
    required int page,
    required int pageSize,
    required ClientsQuery query,
    required Map<String, List<String>> rangeParamsByKey,
  }) async {
    final dynamic response = await _apiClient.get(
      ClientsEndpoints.list,
      queryParams: query.toQueryParameters(
        page: page,
        pageSize: pageSize,
        rangeParamsByKey: rangeParamsByKey,
      ),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return PaginatedClients.fromJson(Map<String, dynamic>.from(response));
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
