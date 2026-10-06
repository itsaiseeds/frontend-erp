import 'dart:convert';

/// Where a notification wants to take the user.
///
/// The backend calls these screens; the set is open, so anything this app
/// does not recognise falls back to [unknown] and opens the inbox rather
/// than failing. A new backend event never needs an app release.
enum NotificationTarget { orderDetail, clientDetail, returnOrderDetail, unknown }

class AppNotification {
  final int id;
  final String eventType;
  final String title;
  final String body;
  final String screen;
  final Map<String, dynamic> data;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    this.id = 0,
    this.eventType = '',
    this.title = '',
    this.body = '',
    this.screen = '',
    this.data = const {},
    this.isRead = false,
    this.createdAt = '',
  });

  /// From the inbox endpoint, where `data` is a real JSON object.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _asInt(json['id']),
      eventType: '${json['event_type'] ?? ''}',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      screen: '${json['screen'] ?? ''}',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      isRead: json['is_read'] == true,
      createdAt: '${json['created_at'] ?? ''}',
    );
  }

  /// From a push, where FCM allows only strings -- so `data` arrives as a
  /// JSON-encoded string and has to be decoded.
  factory AppNotification.fromPush({
    required Map<String, dynamic> payload,
    String title = '',
    String body = '',
  }) {
    return AppNotification(
      id: int.tryParse('${payload['notification_id'] ?? ''}') ?? 0,
      eventType: '${payload['type'] ?? ''}',
      title: title,
      body: body,
      screen: '${payload['screen'] ?? ''}',
      data: _decodePushData(payload['data']),
    );
  }

  NotificationTarget get target {
    switch (screen) {
      case 'order_detail':
        return NotificationTarget.orderDetail;
      case 'client_detail':
        return NotificationTarget.clientDetail;
      case 'return_order_detail':
        return NotificationTarget.returnOrderDetail;
      default:
        return NotificationTarget.unknown;
    }
  }

  String get orderPublicId => '${data['order_public_id'] ?? ''}';

  String get clientPublicId => '${data['client_public_id'] ?? ''}';

  String get returnOrderPublicId => '${data['return_order_public_id'] ?? ''}';

  DateTime? get createdAtDateTime => DateTime.tryParse(createdAt);

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      eventType: eventType,
      title: title,
      body: body,
      screen: screen,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  /// A push carries `data` as a JSON string. A malformed one must not stop
  /// the notification being shown, so it degrades to no payload.
  static Map<String, dynamic> _decodePushData(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);

    final String text = '${raw ?? ''}'.trim();
    if (text.isEmpty) return const {};

    try {
      final dynamic decoded = jsonDecode(text);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
    } catch (_) {
      return const {};
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class PaginatedNotifications {
  final int totalCount;
  final int totalPages;
  final int? nextPageNumber;
  final List<AppNotification> results;

  const PaginatedNotifications({
    this.totalCount = 0,
    this.totalPages = 0,
    this.nextPageNumber,
    this.results = const [],
  });

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    final dynamic results = json['results'];

    return PaginatedNotifications(
      totalCount: AppNotification._asInt(json['total_count']),
      totalPages: AppNotification._asInt(json['total_pages']),
      nextPageNumber: json['next_page_number'] == null
          ? null
          : AppNotification._asInt(json['next_page_number']),
      results: results is List
          ? results
                .whereType<Map>()
                .map(
                  (item) =>
                      AppNotification.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}
