import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// The app-bar bell, with the unread count riding on it.
///
/// The count is passed in rather than fetched here: the badge has to stay
/// correct after a push arrives or the inbox is read, both of which happen
/// outside this widget.
class NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const NotificationBell({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  /// Past this the badge would outgrow the bell, so it stops counting.
  static const int _maxShown = 99;

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;
    final String label = unreadCount > _maxShown
        ? '$_maxShown+'
        : '$unreadCount';

    return IconButton(
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            hasUnread
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            size: AppSizes.HOME_APP_BAR_ICON,
            color: AppColors.TEXT_PRIMARY,
          ),
          if (hasUnread)
            Positioned(
              top: -AppSpacing.XS5,
              right: -AppSpacing.XS6,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: AppSizes.NOTIFICATION_BADGE_MIN,
                ),
                height: AppSizes.NOTIFICATION_BADGE_MIN,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.XS4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ERROR,
                  borderRadius: BorderRadius.circular(AppRadius.FULL),
                  // The ring keeps the badge legible where it overlaps the
                  // bell rather than merging into it.
                  border: Border.all(
                    color: AppColors.SURFACE,
                    width: AppSizes.NOTIFICATION_BADGE_RING,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
