import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/orders_endpoints.dart';
import 'models/order.dart';
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

  /// One order by its public id, for a notification tap.
  ///
  /// There is no detail endpoint, so this narrows the list with
  /// ``?public_id=``. That filter is a substring match, so the exact id is
  /// picked out of whatever comes back rather than trusting the first row.
  /// Null means the order is not the caller's or no longer exists.
  Future<Order?> fetchOrderByPublicId(String publicId) async {
    final String wanted = publicId.trim();
    if (wanted.isEmpty) return null;

    final dynamic response = await _apiClient.get(
      OrdersEndpoints.list,
      queryParams: {'public_id': wanted, 'page': 1, 'page_size': 20},
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    final PaginatedOrders page = PaginatedOrders.fromJson(
      Map<String, dynamic>.from(response),
    );

    for (final Order order in page.results) {
      if (order.publicId.toUpperCase() == wanted.toUpperCase()) return order;
    }
    return null;
  }
}
