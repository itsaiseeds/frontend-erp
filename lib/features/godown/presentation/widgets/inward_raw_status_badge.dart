import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/inward_raw_status.dart';

class InwardRawStatusBadge extends StatelessWidget {
  final InwardRawStatus status;
  final bool isCompact;

  const InwardRawStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color get _foreground {
    switch (status) {
      case InwardRawStatus.labTesting:
        return AppColors.WARNING;
      case InwardRawStatus.inUse:
        return AppColors.SUCCESS;
      case InwardRawStatus.rejected:
        return AppColors.ERROR;
      case InwardRawStatus.unknown:
        return AppColors.TEXT_SECONDARY;
    }
  }

  Color get _background {
    switch (status) {
      case InwardRawStatus.labTesting:
        return AppColors.WARNING_LIGHT;
      case InwardRawStatus.inUse:
        return AppColors.SUCCESS_LIGHT;
      case InwardRawStatus.rejected:
        return AppColors.ERROR_LIGHT;
      case InwardRawStatus.unknown:
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
            InwardRawStatusX.labelOf(status),
            style: AppTypography.labelSmall.copyWith(color: _foreground),
          ),
        ],
      ),
    );
  }
}
