import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/notifications_endpoints.dart';
import 'models/app_notification.dart';

class NotificationsRepository {
  final ApiClient _apiClient;

  const NotificationsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// Tells the server which FCM token reaches this user. Idempotent, so it
  /// is safe to call on every login, start and token refresh.
  Future<void> registerDevice({
    required String fcmToken,
    String? appVersion,
  }) async {
    await _apiClient.post(
      NotificationsEndpoints.registerDevice,
      body: {
        'fcm_token': fcmToken,
        if (appVersion != null && appVersion.isNotEmpty)
          'app_version': appVersion,
      },
    );
  }

  Future<PaginatedNotifications> fetchNotifications({
    int page = 1,
    int pageSize = 20,
    bool? isRead,
  }) async {
    final dynamic response = await _apiClient.get(
      NotificationsEndpoints.list,
      queryParams: {
        'page': page,
        'page_size': pageSize,
        'is_read': ?isRead,
      },
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    return PaginatedNotifications.fromJson(Map<String, dynamic>.from(response));
  }

  /// The badge: how many are still unread.
  Future<int> fetchUnreadCount() async {
    final PaginatedNotifications page = await fetchNotifications(
      pageSize: 1,
      isRead: false,
    );
    return page.totalCount;
  }

  Future<void> markRead(int id) async {
    await _apiClient.post(NotificationsEndpoints.markRead(id));
  }

  Future<void> markAllRead() async {
    await _apiClient.post(NotificationsEndpoints.markAllRead);
  }
}
