import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/orders_endpoints.dart';
import '../../products/data/models/cart_line.dart';
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

  /// Edits one of the caller's BOOKED orders. Sends only what the sales
  /// person actually changed -- the backend applies only the keys present in
  /// the body and leaves everything else as it was. ``lines``, when passed,
  /// is a full replacement of the order's items (there is no partial-item
  /// edit on the backend), while ``addComment`` is appended as a new line
  /// rather than replacing the order's existing comments.
  ///
  /// The response is the backend's full order-detail shape, not the list
  /// shape [Order.fromJson] parses (nested ``items`` rather than a flat
  /// ``packagings`` array, no ``city``/``item_count`` and so on), so it is
  /// not parsed here -- callers re-fetch the list (``OrdersCubit.refresh``)
  /// to see the change, same as after placing a new order.
  Future<void> editOrder({
    required String publicId,
    int? clientAddressId,
    int? clientTransportAgencyId,
    String? expectedDeliveryDate,
    String? addComment,
    List<CartLine>? lines,
    Map<String, dynamic>? bookedFor,
    int? createdBy,
  }) {
    return _apiClient.patch(
      OrdersEndpoints.editOrder(publicId),
      body: {
        'client_address_id': ?clientAddressId,
        'client_transport_agency_id': ?clientTransportAgencyId,
        'expected_delivery_date': ?expectedDeliveryDate,
        if (addComment != null && addComment.trim().isNotEmpty)
          'special_comments': addComment.trim(),
        if (lines != null)
          'items': [
            for (final line in lines)
              {
                'product_packaging_public_id': line.packaging.publicId,
                'quantity': line.quantity,
              },
          ],
        'booked_for': ?bookedFor,
        'created_by': ?createdBy,
      },
    );
  }
}
