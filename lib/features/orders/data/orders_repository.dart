import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/orders_endpoints.dart';
import 'models/orders_query.dart';
import 'models/paginated_orders.dart';

class OrdersRepository {
  final ApiClient _apiClient;

  const OrdersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedOrders> fetchOrders({
    required int page,
    required int pageSize,
    required OrdersQuery query,
    required Map<String, List<String>> rangeParamsByKey,
  }) async {
    final dynamic response = await _apiClient.get(
      OrdersEndpoints.list,
      queryParams: query.toQueryParameters(
        page: page,
        pageSize: pageSize,
        rangeParamsByKey: rangeParamsByKey,
      ),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return PaginatedOrders.fromJson(Map<String, dynamic>.from(response));
  }
}
