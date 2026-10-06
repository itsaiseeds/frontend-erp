import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/toast_utils.dart';
import '../clients/presentation/client_detail_screen.dart';
import '../orders/data/models/order.dart';
import '../orders/data/orders_repository.dart';
import '../orders/presentation/order_detail_screen.dart';
import 'data/models/app_notification.dart';

/// Opens the screen a tapped notification points at.
///
/// The push carries only a screen name and a public id, while the detail
/// screens want a loaded object, so the fetch happens here. Anything this
/// app does not recognise -- a screen added to the backend later -- simply
/// leaves the user on the dashboard rather than failing.
class NotificationRouter {
  NotificationRouter._();

  /// Routes one notification. [context] must be a navigator context that
  /// outlives the fetch, so the caller passes the home screen's.
  static Future<void> open(
    BuildContext context, {
    required AppNotification notification,
    required ApiClient apiClient,
  }) async {
    switch (notification.target) {
      case NotificationTarget.orderDetail:
        await _openOrder(
          context,
          publicId: notification.orderPublicId,
          apiClient: apiClient,
        );
      case NotificationTarget.clientDetail:
        _openClient(context, publicId: notification.clientPublicId);
      case NotificationTarget.returnOrderDetail:
      case NotificationTarget.unknown:
        // No screen for these yet: the tap still opened the app, which is
        // the useful half, and the inbox holds the detail.
        break;
    }
  }

  /// The order list is the only way to read one order, so the row is
  /// fetched before the screen can be pushed.
  static Future<void> _openOrder(
    BuildContext context, {
    required String publicId,
    required ApiClient apiClient,
  }) async {
    if (publicId.isEmpty) return;

    try {
      final Order? order = await OrdersRepository(
        apiClient: apiClient,
      ).fetchOrderByPublicId(publicId);

      if (!context.mounted) return;

      if (order == null) {
        ToastUtils.showWarning(
          context,
          AppStrings.NOTIFICATION_ORDER_MISSING,
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ToastUtils.showError(context, AppStrings.NOTIFICATION_OPEN_FAILED);
    }
  }

  static void _openClient(BuildContext context, {required String publicId}) {
    if (publicId.isEmpty) return;
    ClientDetailScreen.push(context, publicId: publicId);
  }
}
