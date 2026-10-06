import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/analytics_endpoints.dart';
import 'models/analytics_summary.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  const AnalyticsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<AnalyticsSummary> fetchSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final dynamic response = await _apiClient.get(
      AnalyticsEndpoints.analytics,
      queryParams: {
        'start_date_time': start.toUtc().toIso8601String(),
        'end_date_time': end.toUtc().toIso8601String(),
      },
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return AnalyticsSummary.fromJson(Map<String, dynamic>.from(response));
  }
}
