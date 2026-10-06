import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/return_orders_endpoints.dart';
import 'models/paginated_return_orders.dart';
import 'models/return_order.dart';
import 'models/return_order_draft_item.dart';
import 'models/return_order_prefill.dart';
import 'models/return_orders_query.dart';

class ReturnOrdersRepository {
  final ApiClient _apiClient;

  const ReturnOrdersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedReturnOrders> fetchReturnOrders({
    required int page,
    required int pageSize,
    required ReturnOrdersQuery query,
    required Map<String, List<String>> rangeParamsByKey,
  }) async {
    final dynamic response = await _apiClient.get(
      ReturnOrdersEndpoints.list,
      queryParams: query.toQueryParameters(
        page: page,
        pageSize: pageSize,
        rangeParamsByKey: rangeParamsByKey,
      ),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return PaginatedReturnOrders.fromJson(Map<String, dynamic>.from(response));
  }

  /// The challan lines for one order, what is still returnable on each, and the
  /// order's live return if it already has one.
  Future<ReturnOrderPrefill> fetchPrefill(String orderPublicId) async {
    final String id = orderPublicId.trim();
    if (id.isEmpty) {
      throw const ApiException(message: AppStrings.RETURN_ORDER_UNKNOWN_ORDER);
    }

    final dynamic response = await _apiClient.get(
      ReturnOrdersEndpoints.forOrder(id),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return ReturnOrderPrefill.fromJson(Map<String, dynamic>.from(response));
  }

  /// Raises a PENDING return against a dispatched or delivered order.
  Future<ReturnOrder> createReturnOrder({
    required String orderPublicId,
    required String returnDate,
    required List<ReturnOrderDraftItem> items,
  }) async {
    if (items.isEmpty) {
      throw const ApiException(message: AppStrings.RETURN_ORDER_NO_ITEMS);
    }

    final dynamic response = await _apiClient.post(
      ReturnOrdersEndpoints.forOrder(orderPublicId),
      body: {
        'return_date': returnDate,
        'items': items.map((item) => item.toRequest()).toList(),
      },
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return ReturnOrder.fromJson(Map<String, dynamic>.from(response));
  }
}
