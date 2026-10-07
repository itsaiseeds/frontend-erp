import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/lab_endpoints.dart';
import '../../godown/data/models/godown_page.dart';
import '../../godown/data/models/inward_raw_material.dart';
import 'models/lab_testing.dart';

/// Every lab-tester-token endpoint: the pending-lot queue and the lab test
/// records themselves. A sales-person or godown-manager token gets a 403 on
/// every one of these -- the server enforces the role split, not this class.
class LabTesterRepository {
  final ApiClient _apiClient;

  const LabTesterRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<GodownPage<InwardRawMaterial>> fetchPendingLots({
    required Map<String, dynamic> queryParams,
  }) async {
    final dynamic response = await _apiClient.get(
      LabEndpoints.pendingLots,
      queryParams: queryParams,
    );
    return GodownPage.fromJson(_asMap(response), InwardRawMaterial.fromJson);
  }

  Future<GodownPage<LabTesting>> fetchLabTestings({
    required Map<String, dynamic> queryParams,
  }) async {
    final dynamic response = await _apiClient.get(
      LabEndpoints.labTestings,
      queryParams: queryParams,
    );
    return GodownPage.fromJson(_asMap(response), LabTesting.fromJson);
  }

  Future<LabTesting> fetchLabTesting(String publicId) async {
    final dynamic response = await _apiClient.get(
      LabEndpoints.labTesting(publicId),
    );
    return LabTesting.fromJson(_asMap(response));
  }

  Future<LabTesting> submitLabTest({
    required String inwardRawMaterialPublicId,
    required int numberOfPlants,
    required int femaleCount,
    required int otCount,
    required String result,
    String? comment,
  }) async {
    final dynamic response = await _apiClient.post(
      LabEndpoints.labTestings,
      body: {
        'inward_raw_material': inwardRawMaterialPublicId,
        'number_of_plants': numberOfPlants,
        'female_count': femaleCount,
        'ot_count': otCount,
        'result': result,
        'comment': ?comment?.trim(),
      },
    );
    return LabTesting.fromJson(_asMap(response));
  }

  Future<LabTesting> updateLabTesting({
    required String publicId,
    required int numberOfPlants,
    required int femaleCount,
    required int otCount,
    required String result,
    String? comment,
  }) async {
    final dynamic response = await _apiClient.patch(
      LabEndpoints.labTesting(publicId),
      body: {
        'number_of_plants': numberOfPlants,
        'female_count': femaleCount,
        'ot_count': otCount,
        'result': result,
        'comment': ?comment?.trim(),
      },
    );
    return LabTesting.fromJson(_asMap(response));
  }

  static Map<String, dynamic> _asMap(dynamic response) {
    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }
    return Map<String, dynamic>.from(response);
  }
}
