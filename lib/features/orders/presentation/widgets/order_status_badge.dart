import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/order_status.dart';

/// Lifecycle colours: amber while the order is still being settled, blue once
/// it is moving, green when it lands, red if it is refused. Rule B.9 allows
/// semantic hues -- this is a classification, not decoration.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isCompact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color get _foreground {
    switch (status) {
      case OrderStatus.booked:
      case OrderStatus.underReview:
        return AppColors.WARNING;
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return AppColors.INFO;
      case OrderStatus.delivered:
        return AppColors.SUCCESS;
      case OrderStatus.rejected:
        return AppColors.ERROR;
      case OrderStatus.onHold:
      case OrderStatus.unknown:
        return AppColors.TEXT_SECONDARY;
    }
  }

  Color get _background {
    switch (status) {
      case OrderStatus.booked:
      case OrderStatus.underReview:
        return AppColors.WARNING_LIGHT;
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return AppColors.INFO_LIGHT;
      case OrderStatus.delivered:
        return AppColors.SUCCESS_LIGHT;
      case OrderStatus.rejected:
        return AppColors.ERROR_LIGHT;
      case OrderStatus.onHold:
      case OrderStatus.unknown:
        return AppColors.SURFACE_VARIANT;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.XS6 : AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.FULL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.CLIENT_STATUS_DOT,
            height: AppSizes.CLIENT_STATUS_DOT,
            decoration: BoxDecoration(
              color: _foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.XS6),
          Text(
            OrderStatusX.labelOf(status),
            style: AppTypography.labelSmall.copyWith(color: _foreground),
          ),
        ],
      ),
    );
  }
}
