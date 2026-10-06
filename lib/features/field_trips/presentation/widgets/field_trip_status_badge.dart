import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/field_trip_status.dart';

/// Lifecycle colours: amber while the trip is still waiting on someone, blue
/// once the salesperson is out, green when it is done. Rule B.9 allows
/// semantic hues -- this is a classification, not decoration.
class FieldTripStatusBadge extends StatelessWidget {
  final FieldTripStatus status;
  final bool isCompact;

  const FieldTripStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color get _foreground {
    switch (status) {
      case FieldTripStatus.planned:
        return AppColors.WARNING;
      case FieldTripStatus.approved:
        return AppColors.INFO;
      case FieldTripStatus.inProgress:
        return AppColors.PRIMARY;
      case FieldTripStatus.completed:
        return AppColors.SUCCESS;
      case FieldTripStatus.unknown:
        return AppColors.TEXT_SECONDARY;
    }
  }

  Color get _background {
    switch (status) {
      case FieldTripStatus.planned:
        return AppColors.WARNING_LIGHT;
      case FieldTripStatus.approved:
        return AppColors.INFO_LIGHT;
      case FieldTripStatus.inProgress:
        return AppColors.PRIMARY_SURFACE;
      case FieldTripStatus.completed:
        return AppColors.SUCCESS_LIGHT;
      case FieldTripStatus.unknown:
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
            FieldTripStatusX.labelOf(status),
            style: AppTypography.labelSmall.copyWith(color: _foreground),
          ),
        ],
      ),
    );
  }
}
