import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/app_notification.dart';

/// The icon that matches what the notification is about, so the list can be
/// scanned without reading every title.
IconData _iconFor(AppNotification notification) {
  switch (notification.target) {
    case NotificationTarget.orderDetail:
      return Icons.receipt_long_rounded;
    case NotificationTarget.clientDetail:
      return Icons.storefront_rounded;
    case NotificationTarget.returnOrderDetail:
      return Icons.assignment_return_rounded;
    case NotificationTarget.unknown:
      return Icons.notifications_rounded;
  }
}

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;

    return Material(
      color: isUnread ? AppColors.PRIMARY_SURFACE : AppColors.SURFACE,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.MD16,
            vertical: AppSpacing.SMD12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.NOTIFICATION_ICON_BOX,
                height: AppSizes.NOTIFICATION_ICON_BOX,
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppColors.SURFACE
                      : AppColors.SURFACE_VARIANT,
                  borderRadius: BorderRadius.circular(AppRadius.MD),
                ),
                child: Icon(
                  _iconFor(notification),
                  size: AppSizes.ICON_LG,
                  color: isUnread
                      ? AppColors.PRIMARY
                      : AppColors.TEXT_SECONDARY,
                ),
              ),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: isUnread
                                ? AppTypography.labelStrong
                                : AppTypography.bodyMedium,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: AppSpacing.SM8),
                          Container(
                            width: AppSizes.NOTIFICATION_UNREAD_DOT,
                            height: AppSizes.NOTIFICATION_UNREAD_DOT,
                            margin: const EdgeInsets.only(top: AppSpacing.XS5),
                            decoration: const BoxDecoration(
                              color: AppColors.PRIMARY,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.XXS2),
                      Text(
                        notification.body,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.TEXT_SECONDARY,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.XS4),
                    Text(
                      DateFormatter.timeOfDay(notification.createdAtDateTime),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.TEXT_DISABLED,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
