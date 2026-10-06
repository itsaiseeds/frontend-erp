import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/products_endpoints.dart';
import 'models/cart_line.dart';
import 'models/paginated_products.dart';
import 'models/products_query.dart';

class ProductsRepository {
  final ApiClient _apiClient;

  const ProductsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedProducts> fetchCatalogue({
    required int page,
    required int pageSize,
    required ProductsQuery query,
    required Map<String, List<String>> rangeParamsByKey,
  }) async {
    final dynamic response = await _apiClient.get(
      ProductsEndpoints.catalogue,
      queryParams: query.toQueryParameters(
        page: page,
        pageSize: pageSize,
        rangeParamsByKey: rangeParamsByKey,
      ),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return PaginatedProducts.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> createOrder({
    required String clientPublicId,
    required int clientAddressId,
    int? clientTransportAgencyId,
    String specialComments = '',
    required List<CartLine> lines,
  }) async {
    await _apiClient.post(
      ProductsEndpoints.createOrder,
      body: {
        'client_public_id': clientPublicId,
        'client_address_id': clientAddressId,
        'client_transport_agency_id': ?clientTransportAgencyId,
        'special_comments': specialComments.trim(),
        'items': [
          for (final line in lines)
            {
              'product_packaging_public_id': line.packaging.publicId,
              'quantity': line.quantity,
            },
        ],
      },
    );
  }
}
