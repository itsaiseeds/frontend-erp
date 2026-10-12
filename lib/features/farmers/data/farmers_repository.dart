import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints/farmers_endpoints.dart';
import 'models/farmers_query.dart';
import 'models/paginated_farmers.dart';

class FarmersRepository {
  final ApiClient _apiClient;

  const FarmersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedFarmers> fetchFarmers({
    required int page,
    required int pageSize,
    required FarmersQuery query,
    required Map<String, List<String>> rangeParamsByKey,
  }) async {
    final dynamic response = await _apiClient.get(
      FarmersEndpoints.list,
      queryParams: query.toQueryParameters(
        page: page,
        pageSize: pageSize,
        rangeParamsByKey: rangeParamsByKey,
      ),
    );

    return PaginatedFarmers.fromJson(_asMap(response));
  }

  Future<void> createFarmer({
    required String farmerName,
    required String contactNumber,
    required String village,
    required String landAreaBigha,
    required bool isLead,
    required List<int> cropIds,
    required List<String> productPublicIds,
  }) {
    return _apiClient.post(
      FarmersEndpoints.create,
      body: {
        'farmer_name': farmerName.trim(),
        'contact_number': contactNumber.trim(),
        'village': village.trim(),
        'land_area_bigha': landAreaBigha,
        'is_lead': isLead,
        'crop_ids': cropIds,
        'product_public_ids': productPublicIds,
      },
    );
  }

  /// Sends only what moved -- same convention as [editFarmerVisit] on the
  /// trip-scoped repository.
  Future<void> editFarmer({
    required String publicId,
    bool? isLead,
    String? farmerName,
    String? contactNumber,
    String? village,
    String? landAreaBigha,
    List<int>? cropIds,
    List<String>? productPublicIds,
  }) {
    return _apiClient.patch(
      FarmersEndpoints.detail(publicId),
      body: {
        'is_lead': ?isLead,
        if (farmerName != null) 'farmer_name': farmerName.trim(),
        if (contactNumber != null) 'contact_number': contactNumber.trim(),
        if (village != null) 'village': village.trim(),
        'land_area_bigha': ?landAreaBigha,
        'crop_ids': ?cropIds,
        'product_public_ids': ?productPublicIds,
      },
    );
  }

  Future<void> deleteFarmer(String publicId) {
    return _apiClient.delete(FarmersEndpoints.detail(publicId));
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
