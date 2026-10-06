import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/orders_endpoints.dart';
import 'models/challan.dart';

class ChallanRepository {
  final ApiClient _apiClient;

  const ChallanRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<Challan> fetchChallan(String orderPublicId) async {
    final dynamic response = await _apiClient.get(
      OrdersEndpoints.challan(orderPublicId),
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return Challan.fromJson(Map<String, dynamic>.from(response));
  }
}
