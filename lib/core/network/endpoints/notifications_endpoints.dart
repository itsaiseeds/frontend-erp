class NotificationsEndpoints {
  NotificationsEndpoints._();

  static const String _base = '/android/api/v1';

  static const String registerDevice = '$_base/devices/register';

  static const String list = '$_base/notifications';

  static String markRead(int id) => '$_base/notification/$id/read';

  static const String markAllRead = '$_base/notifications/read-all';
}
