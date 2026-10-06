import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/return_order.dart';

/// Lifecycle colours, matching the order badge: amber while the return waits on
/// the sales admin, green once it is booked back into stock, red if refused.
class ReturnOrderStatusBadge extends StatelessWidget {
  final ReturnOrderStatus status;
  final bool isCompact;

  const ReturnOrderStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color get _foreground {
    switch (status) {
      case ReturnOrderStatus.pending:
        return AppColors.WARNING;
      case ReturnOrderStatus.accepted:
        return AppColors.SUCCESS;
      case ReturnOrderStatus.rejected:
        return AppColors.ERROR;
      case ReturnOrderStatus.unknown:
        return AppColors.TEXT_SECONDARY;
    }
  }

  Color get _background {
    switch (status) {
      case ReturnOrderStatus.pending:
        return AppColors.WARNING_LIGHT;
      case ReturnOrderStatus.accepted:
        return AppColors.SUCCESS_LIGHT;
      case ReturnOrderStatus.rejected:
        return AppColors.ERROR_LIGHT;
      case ReturnOrderStatus.unknown:
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
            ReturnOrderStatusX.labelOf(status),
            style: AppTypography.labelSmall.copyWith(color: _foreground),
          ),
        ],
      ),
    );
  }
}
